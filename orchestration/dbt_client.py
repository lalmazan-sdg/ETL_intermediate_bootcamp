import os
import time

import requests

from dotenv import load_dotenv
from prefect import task, get_run_logger
from prefect.blocks.system import Secret

from orchestration.config import (
    DBT_API_URL,
    DBT_ACCOUNT_ID,
    POLL_INTERVAL,
    MAX_WAIT_SECONDS
)


load_dotenv()


@task(name="Execute dbt Cloud Job")
def execute_dbt_job(job_name: str, job_id: int):

    logger = get_run_logger()

    token = os.getenv("DBT_CLOUD_API_TOKEN")

    if not token:
        token = Secret.load("dbt-cloud-api-token").get()

    if not token:
        raise ValueError(
            "DBT_CLOUD_API_TOKEN no está configurado"
        )

    headers = {
        "Authorization": f"Token {token}"
    }

    trigger_url = (
        f"{DBT_API_URL}/api/v2/accounts/"
        f"{DBT_ACCOUNT_ID}/jobs/{job_id}/run/"
    )

    payload = {
        "cause": f"Triggered by Prefect: {job_name}"
    }

    logger.info(f"Iniciando job: {job_name}")

    response = requests.post(
        trigger_url,
        headers=headers,
        json=payload,
        timeout=30
    )

    response.raise_for_status()

    run_id = response.json()["data"]["id"]

    logger.info(f"Job iniciado. Run ID: {run_id}")

    logger.info(
        f"Job: {job_name} | ID: {job_id}"
    )

    status_url = (
        f"{DBT_API_URL}/api/v2/accounts/"
        f"{DBT_ACCOUNT_ID}/runs/{run_id}/"
    )

    status_names = {
        1: "Queued",
        2: "Starting",
        3: "Running",
        10: "Success",
        20: "Error",
        30: "Cancelled"
    }

    start_time = time.monotonic()

    while time.monotonic() - start_time < MAX_WAIT_SECONDS:

        response = requests.get(
            status_url,
            headers=headers,
            timeout=30
        )

        response.raise_for_status()

        status = response.json()["data"]["status"]

        status_name = status_names.get(
            status, "Unknown"
        )

        logger.info(
            f"{job_name} | Run {run_id}: {status_name}"
        )

        if status == 10:

            duration = round(
                time.monotonic() - start_time, 2
            )

            logger.info(
                f"{job_name} completado correctamente"
            )

            logger.info(
                f"Duración de monitorización: {duration}s"
            )

            return {
                "job_name": job_name,
                "job_id": job_id,
                "run_id": run_id,
                "status": "Success",
                "monitoring_seconds": duration
            }

        if status in (20, 30):

            logger.error(
                f"{job_name} terminó con estado {status_name}"
            )

            raise RuntimeError(
                f"Error ejecutando {job_name}. "
                f"Run ID: {run_id}"
            )

        if status not in (1, 2, 3):

            raise RuntimeError(
                f"Estado inesperado de dbt Cloud: {status}"
            )

        time.sleep(POLL_INTERVAL)

    raise TimeoutError(
        f"Tiempo máximo superado en {job_name}. "
        f"Run ID: {run_id}"
    )
