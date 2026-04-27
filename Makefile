.PHONY: lint test test-unit test-integration test-all fmt validate dbt-compile install

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
	@if ls terraform/*.tf >/dev/null 2>&1; then \
		cd terraform && terraform validate; \
	else \
		echo "Skipping terraform validate: no Terraform configuration files found in terraform/"; \
	fi

dbt-compile:
	@if [ -f dbt/dbt_project.yml ]; then \
		cd dbt && dbt compile; \
	else \
		echo "Skipping dbt compile: dbt/dbt_project.yml not found; dbt project is not yet configured."; \
	fi
