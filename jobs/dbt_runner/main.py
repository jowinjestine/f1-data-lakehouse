import logging
import os
import subprocess
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","logger":"%(name)s","message":"%(message)s"}',
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)

DBT_DIR = os.environ.get("DBT_DIR", "/app/dbt")
PROFILES_DIR = os.environ.get("DBT_PROFILES_DIR", "/app/dbt")
TARGET = os.environ.get("DBT_TARGET", "prod")


def _run_dbt(command: list[str]) -> None:
    full_cmd = ["dbt"] + command + ["--project-dir", DBT_DIR, "--profiles-dir", PROFILES_DIR, "--target", TARGET]
    logger.info("Running: %s", " ".join(full_cmd))
    result = subprocess.run(full_cmd, capture_output=True, text=True)
    if result.stdout:
        logger.info(result.stdout)
    if result.returncode != 0:
        logger.error("dbt command failed: %s", result.stderr)
        raise RuntimeError(f"dbt {command[0]} failed with exit code {result.returncode}")


def run() -> None:
    logger.info("Starting dbt runner pipeline")

    steps = [
        ["deps"],
        ["source", "freshness"],
        ["run"],
        ["test"],
        ["docs", "generate"],
    ]

    for step in steps:
        step_name = " ".join(step)
        logger.info("Step: dbt %s", step_name)
        try:
            _run_dbt(step)
            logger.info("Completed: dbt %s", step_name)
        except RuntimeError:
            if step[0] == "source":
                logger.warning("Source freshness check failed (non-fatal), continuing")
            else:
                raise

    logger.info("dbt runner pipeline complete")


if __name__ == "__main__":
    run()
