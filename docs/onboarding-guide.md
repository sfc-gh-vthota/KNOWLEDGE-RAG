# New Employee Onboarding Guide

## Welcome to the Team

Welcome to our organization. This guide covers everything you need to get productive in your first two weeks.

## Day 1 Checklist

- Collect your laptop from IT (Room 3B, Building A)
- Activate your corporate email at mail.internal.corp
- Set up Multi-Factor Authentication (MFA) on your phone using the Okta Verify app
- Join the #general and #your-team Slack channels
- Complete mandatory security awareness training in the LMS portal

## Access Requests

All system access is managed through ServiceNow. Submit requests at servicenow.internal.corp/access.

### Standard Access (auto-approved within 4 hours)
- Email and calendar (Outlook/Google Workspace)
- Slack
- Confluence and Jira
- GitHub (read-only to public repos)

### Elevated Access (requires manager approval, 1-2 business days)
- Production database read access
- AWS Console (development account)
- Snowflake (analyst role)
- GitHub (write access to team repos)

### Restricted Access (requires VP approval + security review)
- Production database write access
- PII data access
- Admin consoles
- Key management systems

## Development Environment Setup

1. Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
2. Install required tools: `brew install git python node docker`
3. Clone the team repository: `git clone git@github.com:org/team-repo.git`
4. Set up pre-commit hooks: `pre-commit install`
5. Configure your IDE with the team's shared settings (see `.vscode/settings.json`)

## Key Contacts

| Role | Name | Slack Handle |
|------|------|-------------|
| Your Manager | Listed in Workday | Check your offer letter |
| IT Support | Help Desk | #it-support |
| HR Questions | People Team | #ask-hr |
| Security | InfoSec Team | #security-help |

## First Week Goals

- Complete all compliance training modules
- Set up your development environment
- Attend team standup (daily at 9:30 AM)
- Schedule 1:1s with your direct teammates
- Read the team's architecture documentation in Confluence
