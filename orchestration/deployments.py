from prefect import flow
from prefect.schedules import Cron


REPOSITORY_URL = (
    "https://github.com/"
    "lalmazan-sdg/ETL_intermediate_bootcamp.git"
)

WORK_POOL_NAME = "dbt-cloud-serverless"


if __name__ == "__main__":

    daily_pipeline = flow.from_source(
        source=REPOSITORY_URL,
        entrypoint="orchestration/flows.py:daily_pipeline"
    )

    daily_pipeline.deploy(
        name="daily-serverless",
        work_pool_name=WORK_POOL_NAME,
        schedules=[
            Cron(
                "0 9 * * 0-4,6",
                timezone="Europe/Madrid"
            )
        ],
        concurrency_limit=1,
        tags=["dbt", "daily", "orchestration"],
        description=(
            "Daily dbt Cloud orchestration: source freshness, "
            "staging, snapshots, intermediate and marts."
        )
    )

    weekly_pipeline = flow.from_source(
        source=REPOSITORY_URL,
        entrypoint="orchestration/flows.py:weekly_pipeline"
    )

    weekly_pipeline.deploy(
        name="weekly-serverless",
        work_pool_name=WORK_POOL_NAME,
        schedules=[
            Cron(
                "0 9 * * 5",
                timezone="Europe/Madrid"
            )
        ],
        concurrency_limit=1,
        tags=["dbt", "weekly", "full-refresh"],
        description=(
            "Weekly dbt Cloud orchestration: source freshness, "
            "staging full refresh, snapshots, intermediate and marts."
        )
    )
