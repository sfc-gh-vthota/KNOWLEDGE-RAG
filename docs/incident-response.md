# Incident Response Procedures

## Severity Levels

### SEV-1 (Critical)
- **Definition**: Complete service outage affecting all customers, data breach confirmed, or revenue-impacting failure
- **Response Time**: 15 minutes to acknowledge, all hands on deck
- **Communication**: Immediate exec notification, customer status page update within 30 minutes
- **Examples**: Payment processing down, database corruption, confirmed security breach

### SEV-2 (High)
- **Definition**: Partial service degradation affecting >25% of users, or potential security incident under investigation
- **Response Time**: 30 minutes to acknowledge, dedicated incident commander assigned
- **Communication**: Engineering leadership notified, status page updated within 1 hour
- **Examples**: Elevated error rates, one region down, suspicious access patterns detected

### SEV-3 (Medium)
- **Definition**: Minor service impact affecting <25% of users, or non-critical system failure
- **Response Time**: 2 hours to acknowledge during business hours
- **Communication**: Team lead notified, internal Slack update
- **Examples**: Batch job failures, non-critical API degradation, monitoring gaps

### SEV-4 (Low)
- **Definition**: No customer impact, internal tooling issues, cosmetic bugs
- **Response Time**: Next business day
- **Communication**: Team Jira ticket created
- **Examples**: Internal dashboard down, CI/CD pipeline stuck, documentation errors

## Escalation Path

```
On-Call Engineer (first responder)
    → Team Lead (if not resolved in 30 min)
        → Engineering Manager (if SEV-1/2 not resolved in 1 hour)
            → VP Engineering (if SEV-1 not resolved in 2 hours)
                → CTO (if customer-facing for >4 hours)
```

## Incident Commander Responsibilities

1. **Declare the incident** — Create incident channel in Slack (#inc-YYYY-MM-DD-description)
2. **Assemble the team** — Page relevant on-call engineers
3. **Establish communication cadence** — Updates every 15 min for SEV-1, 30 min for SEV-2
4. **Coordinate resolution** — Assign workstreams, prevent duplicate effort
5. **Manage stakeholders** — Keep leadership informed, draft customer communications
6. **Call the all-clear** — Confirm resolution, schedule post-mortem

## Post-Mortem Process

All SEV-1 and SEV-2 incidents require a post-mortem within 5 business days.

### Post-Mortem Template
- **Timeline**: Minute-by-minute reconstruction of events
- **Root Cause**: Technical root cause (use 5 Whys methodology)
- **Impact**: Duration, users affected, revenue impact
- **Detection**: How was the issue discovered? Could we have caught it sooner?
- **Resolution**: What fixed it? Was it a temporary or permanent fix?
- **Action Items**: Preventive measures with owners and due dates

### Blameless Culture
- Post-mortems focus on systems and processes, never individuals
- "What failed?" not "Who failed?"
- Goal is to prevent recurrence, not assign blame

## On-Call Schedule

- Rotations are weekly, Monday 9 AM to Monday 9 AM
- Primary and secondary on-call for each service
- On-call engineers must acknowledge pages within 5 minutes
- Compensation: $500/week on-call stipend + $100 per after-hours page
- Swap requests must be submitted 48 hours in advance via PagerDuty
