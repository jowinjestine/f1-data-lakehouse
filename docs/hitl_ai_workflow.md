# Human-in-the-Loop AI Workflow

This project follows a **Human-in-the-Loop (HITL) AI** delivery model. AI agents generate code, infrastructure, and documentation, while human reviewers control all critical decisions.

## Roles and Responsibilities

### Human Reviewer

| Responsibility | Examples |
|---|---|
| Architecture decisions | Cloud Run vs Cloud Functions, dataset layout, location choices |
| Security review | IAM roles, credential management, access controls |
| Quality gates | PR approval, test coverage thresholds, schema validation |
| Deployment approval | Terraform apply, backfill execution, production releases |
| Final acceptance | Dashboard narrative, documentation accuracy, release sign-off |

### AI Agent

| Responsibility | Examples |
|---|---|
| Code generation | Python ingestion jobs, dbt models, Terraform modules |
| Test creation | Unit tests, integration tests, dbt schema tests |
| Documentation | Architecture docs, metric definitions, runbooks |
| Configuration | Contract YAMLs, crosswalk CSVs, CI/CD workflows |
| Jira management | Task descriptions, status updates, acceptance criteria |

## AI Agent Boundaries

### Agents MAY

- Generate code, dbt models, Terraform, tests, and documentation
- Create and update Jira task descriptions
- Write contract YAMLs and crosswalk CSVs
- Run linting, formatting, and compilation checks
- Post progress updates to Slack

### Agents MAY NOT

- Apply Terraform without human approval
- Trigger full historical backfill without human approval
- Change IAM or security settings without review
- Publish dashboard links without review
- Merge PRs without CI passing and human approval
- Create or rotate secrets or credentials

## 8-Phase Delivery Model

Each phase has a **human review gate** that must be passed before proceeding.

| Phase | Goal | Human Gate |
|---|---|---|
| 0. HITL Setup | Repo scaffold, templates, governance docs | Approve execution model |
| 1. Foundation | Terraform infra, GCS, BQ, IAM, budget alerts | Approve architecture + IAM |
| 2. Thin Slice | One race weekend end-to-end | Approve thin slice before scaling |
| 3. Full Ingestion | Modern + historical data, backfill, checkpointing | Approve backfill dry run |
| 4. Full dbt | All staging, marts, aggregates, crosswalks, tests | Approve lineage + metric definitions |
| 5. Dashboard | All Looker Studio pages + data health | Approve narrative + sharing |
| 6. CI/CD + Ops | GitHub Actions, Cloud Scheduler, alerting | Approve deployment pipeline |
| 7. Portfolio Polish | README, docs, graphify, understand, release | Approve final release |

**Critical path**: Phase 0 -> 1 -> 2 -> 3 -> 4 -> 6 -> 7

Phase 5 (Dashboard) may proceed after Phase 4 but is non-blocking.

## GitHub PR Workflow

All tasks are completed through GitHub pull requests:

1. AI agent creates a feature branch (e.g., `phase-1/foundation`)
2. AI agent generates code and opens a PR with summary, test evidence, and checklist
3. Human reviewer reviews the PR using the HITL checklist
4. Human approves or requests changes
5. Once approved, human merges the PR
6. Task is marked complete in Jira

## Acceptance Criteria Template

Every AI-generated task should include:

```markdown
## Acceptance Criteria
- [ ] Functional requirement met (describe specific behavior)
- [ ] Tests pass (unit, integration, dbt as applicable)
- [ ] No secrets or credentials committed
- [ ] Documentation updated
- [ ] PR opened with HITL checklist completed
- [ ] Human review completed
```

## Security Review Checklist

Before approving any PR that touches infrastructure or credentials:

- [ ] IAM roles follow least-privilege principle
- [ ] No JSON keys or static credentials anywhere
- [ ] Workload Identity Federation used for GitHub Actions
- [ ] Runtime service accounts attached to Cloud Run Jobs (not key-based)
- [ ] No sensitive data in logs, error messages, or environment variables
- [ ] `.gitignore` excludes all credential files
- [ ] Budget alerts configured

## Deployment Approval Checklist

Before approving production deployments:

- [ ] CI pipeline passes all checks
- [ ] Human code review completed
- [ ] Budget impact assessed
- [ ] Rollback plan documented
- [ ] No breaking changes to existing data
- [ ] Terraform plan reviewed (no unexpected resource changes)
