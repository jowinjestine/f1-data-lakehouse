FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY jobs/dbt_runner/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY dbt/ /app/dbt/
COPY jobs/dbt_runner/ /app/jobs/dbt_runner/

ENV DBT_DIR=/app/dbt

CMD ["python", "jobs/dbt_runner/main.py"]
