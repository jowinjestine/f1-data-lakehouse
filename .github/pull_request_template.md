## Summary
<!-- 1-3 bullet points describing what this PR does -->

-

## Changes
<!-- List key files changed and why -->

-

## Test Evidence
<!-- How was this tested? Include command outputs, screenshots, or logs -->

-

## HITL AI Checklist

### Code Quality
- [ ] Code review completed by human reviewer
- [ ] All tests pass (`make test`)
- [ ] Linting passes (`make lint`)
- [ ] No secrets or credentials committed

### Data Engineering
- [ ] Schema contracts validated (if ingestion changes)
- [ ] dbt compile passes (if dbt changes)
- [ ] Terraform validate passes (if infra changes)
- [ ] Documentation updated (if behavior changes)

### Security
- [ ] No JSON keys or static credentials
- [ ] IAM roles follow least-privilege
- [ ] No sensitive data in logs or error messages

### Deployment
- [ ] Budget impact assessed (if adding new resources)
- [ ] Rollback plan considered

---
*This PR was generated with assistance from AI agents as part of the HITL AI workflow. All changes have been reviewed by a human.*
