# Quarterly Business Review Process

## Overview

Quarterly Business Reviews (QBRs) are held in the first two weeks of each quarter to assess progress, realign priorities, and set goals for the upcoming quarter.

## OKR Framework

We use Objectives and Key Results (OKRs) to set and track goals.

### Structure
- **Objectives**: Qualitative, ambitious goals (3-5 per team per quarter)
- **Key Results**: Measurable outcomes that indicate objective completion (2-4 per objective)
- **Scoring**: 0.0 to 1.0 scale (0.7 = good, 1.0 = exceptional/sandbagged)

### Example OKR
**Objective**: Improve platform reliability for enterprise customers

| Key Result | Target | Scoring |
|-----------|--------|---------|
| Reduce P1 incidents from 4/quarter to 1/quarter | ≤1 incident | 0.0=4+, 0.5=2-3, 1.0=0-1 |
| Achieve 99.95% uptime (up from 99.9%) | 99.95% | 0.0=<99.9%, 0.5=99.9-99.94%, 1.0=≥99.95% |
| Reduce mean time to recovery from 45min to 15min | ≤15 min | 0.0=>45min, 0.5=15-45min, 1.0=≤15min |

## QBR Schedule

| Week | Activity | Participants |
|------|----------|-------------|
| Q-1 Week | Teams draft proposed OKRs | Team leads + ICs |
| Q+1 Day 1-3 | Previous quarter scoring + retrospective | All teams |
| Q+1 Day 4-7 | Cross-team alignment and dependency mapping | Team leads + Directors |
| Q+1 Day 8-10 | Final OKR approval by leadership | VPs + C-suite |
| Q+1 Day 11-14 | OKRs published and communicated | All hands meeting |

## Review Presentation Template

Each team presents a 15-minute QBR with this structure:

### Slide 1: Scorecard (2 min)
- Previous quarter OKR scores (red/yellow/green)
- Key metrics dashboard
- Budget utilization

### Slide 2: Wins & Learnings (3 min)
- Top 3 achievements
- What we learned from misses
- Shoutouts to cross-team collaborators

### Slide 3: Next Quarter Objectives (5 min)
- 3-5 proposed objectives with key results
- Resource requirements and constraints
- Dependencies on other teams

### Slide 4: Risks & Asks (3 min)
- Top risks to next quarter's success
- Headcount or budget requests
- Decisions needed from leadership

### Slide 5: Q&A (2 min)

## Metrics Dashboard

Each team maintains a real-time metrics dashboard in Snowflake/Streamlit with:

- **Delivery**: Velocity, cycle time, deployment frequency
- **Quality**: Bug escape rate, test coverage, incident count
- **Customer**: NPS, support tickets, feature adoption
- **Operational**: Uptime, latency p99, error rate
- **Financial**: Cost per transaction, infrastructure spend, ROI

## Annual Planning Integration

- Q4 QBR feeds into annual planning (December)
- Annual goals cascade into quarterly OKRs
- Mid-year strategy review (July) may adjust annual targets
- Budget cycles align with fiscal year (January-December)

## Tools

- **OKR Tracking**: Lattice (lattice.internal.corp)
- **Presentations**: Google Slides (template in shared drive)
- **Metrics**: Snowflake + Streamlit dashboards
- **Action Items**: Jira epics linked to OKR key results
