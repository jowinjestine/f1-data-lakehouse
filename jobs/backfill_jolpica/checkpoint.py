import logging

from google.cloud import bigquery

logger = logging.getLogger(__name__)


def _get_client(project_id: str) -> bigquery.Client:
    return bigquery.Client(project=project_id)


def get_checkpoint(project_id: str, ops_dataset: str, source: str, dataset: str) -> dict | None:
    client = _get_client(project_id)
    table_id = f"{project_id}.{ops_dataset}.backfill_checkpoints"

    query = f"""
    SELECT last_completed_year, last_completed_round
    FROM `{table_id}`
    WHERE source = @source AND dataset = @dataset
    ORDER BY updated_at DESC
    LIMIT 1
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("source", "STRING", source),
            bigquery.ScalarQueryParameter("dataset", "STRING", dataset),
        ]
    )

    try:
        rows = list(client.query(query, job_config=job_config).result())
        if rows:
            return {
                "last_completed_year": rows[0].last_completed_year,
                "last_completed_round": rows[0].last_completed_round,
            }
    except Exception:
        logger.warning("No checkpoint table found, starting from beginning")

    return None


def save_checkpoint(
    project_id: str,
    ops_dataset: str,
    source: str,
    dataset: str,
    year: int,
    round_number: int | None,
) -> None:
    client = _get_client(project_id)
    table_id = f"{project_id}.{ops_dataset}.backfill_checkpoints"

    query = f"""
    MERGE `{table_id}` t
    USING (SELECT @source AS source, @dataset AS dataset) s
    ON t.source = s.source AND t.dataset = s.dataset
    WHEN MATCHED THEN UPDATE SET
        last_completed_year = @year,
        last_completed_round = @round,
        updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT
        (source, dataset, last_completed_year, last_completed_round, updated_at)
    VALUES (@source, @dataset, @year, @round, CURRENT_TIMESTAMP())
    """

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("source", "STRING", source),
            bigquery.ScalarQueryParameter("dataset", "STRING", dataset),
            bigquery.ScalarQueryParameter("year", "INT64", year),
            bigquery.ScalarQueryParameter("round", "INT64", round_number),
        ]
    )

    client.query(query, job_config=job_config).result()
    logger.info("Saved checkpoint: %s/%s year=%d round=%s", source, dataset, year, round_number)
