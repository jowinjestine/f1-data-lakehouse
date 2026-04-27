.PHONY: lint test test-unit test-integration fmt validate dbt-compile install

install:
	pip install -e ".[dev,dbt]"

lint:
	ruff check .
	ruff format --check .

fmt:
	ruff check --fix .
	ruff format .

test:
	pytest tests/ -m "not integration"

test-unit:
	pytest tests/unit/ -v

test-integration:
	pytest tests/integration/ -v -m integration

test-all:
	pytest tests/ -v --cov=jobs --cov-report=term-missing

validate:
	cd terraform && terraform validate

dbt-compile:
	cd dbt && dbt compile
