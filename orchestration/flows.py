from prefect import flow, get_run_logger

from orchestration.config import DBT_JOBS
from orchestration.dbt_client import execute_dbt_job


@flow(name="dbt-daily-pipeline", log_prints=True)
def daily_pipeline():

    logger = get_run_logger()

    logger.info("Iniciando pipeline diario")

    execute_dbt_job(
        "00_SOURCE_FRESHNESS",
        DBT_JOBS["source_freshness"]
    )

    execute_dbt_job(
        "01_STAGING_DAILY",
        DBT_JOBS["staging_daily"]
    )

    execute_dbt_job(
        "02_SNAPSHOTS",
        DBT_JOBS["snapshots"]
    )

    execute_dbt_job(
        "03_INTERMEDIATE",
        DBT_JOBS["intermediate"]
    )

    execute_dbt_job(
        "04_MARTS",
        DBT_JOBS["marts"]
    )

    logger.info("Pipeline diario completado")


@flow(name="dbt-weekly-full-refresh", log_prints=True)
def weekly_pipeline():

    logger = get_run_logger()

    logger.info("Iniciando pipeline semanal")

    execute_dbt_job(
        "00_SOURCE_FRESHNESS",
        DBT_JOBS["source_freshness"]
    )

    execute_dbt_job(
        "STAGING_FULL_REFRESH",
        DBT_JOBS["staging_full_refresh"]
    )

    execute_dbt_job(
        "02_SNAPSHOTS",
        DBT_JOBS["snapshots"]
    )

    execute_dbt_job(
        "03_INTERMEDIATE",
        DBT_JOBS["intermediate"]
    )

    execute_dbt_job(
        "04_MARTS",
        DBT_JOBS["marts"]
    )

    logger.info("Pipeline semanal completado")


if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--mode",
        choices=["daily", "weekly"],
        required=True
    )

    args = parser.parse_args()

    if args.mode == "daily":
        daily_pipeline()

    elif args.mode == "weekly":
        weekly_pipeline()
