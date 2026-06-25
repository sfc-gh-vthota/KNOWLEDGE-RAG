/*
 * RAG Demo Setup: Cortex Search on Knowledge Base Documents
 * 
 * This script creates the infrastructure for a RAG pipeline:
 * 1. Database and schema
 * 2. Stage for markdown files (simulates S3)
 * 3. Table to hold parsed documents
 * 4. Loads documents from stage
 * 5. Creates Cortex Search Service (auto-embeds text)
 *
 * Prerequisites:
 *   - Upload .md files to the stage using:
 *     PUT file:///path/to/RAG-CORTEX-SEARCH-DEMO/docs/*.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
 */

-- ============================================================
-- STEP 1: Infrastructure
-- ============================================================

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS RAG_DEMO;
CREATE SCHEMA IF NOT EXISTS RAG_DEMO.KNOWLEDGE_BASE;
USE SCHEMA RAG_DEMO.KNOWLEDGE_BASE;

CREATE WAREHOUSE IF NOT EXISTS RAG_WH 
  WAREHOUSE_SIZE = 'XSMALL' 
  AUTO_SUSPEND = 60 
  AUTO_RESUME = TRUE;

USE WAREHOUSE RAG_WH;

-- ============================================================
-- STEP 2: Stage for markdown files
-- ============================================================

CREATE STAGE IF NOT EXISTS DOCS_STAGE
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'Stage for knowledge base markdown documents';

-- Upload files (run from SnowSQL or Snowsight):
-- PUT file:///path/to/docs/onboarding-guide.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/docs/data-governance-policy.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/docs/incident-response.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/docs/api-authentication.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/docs/cloud-architecture.md @DOCS_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/docs/quarterly-review-process.md @DOCS_STAGE AUTO_COMPRESS=FALSE;

-- Verify files are uploaded:
-- LIST @DOCS_STAGE;

-- ============================================================
-- STEP 3: Table to hold parsed documents
-- ============================================================

CREATE OR REPLACE TABLE DOCUMENTS (
    doc_id STRING,
    title STRING,
    content STRING,
    source_file STRING,
    last_updated TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- STEP 4: Load markdown content from stage into table
-- ============================================================

-- Read files from stage and insert into DOCUMENTS table
INSERT INTO DOCUMENTS (doc_id, title, content, source_file)
SELECT
    MD5(RELATIVE_PATH) AS doc_id,
    REPLACE(REPLACE(RELATIVE_PATH, '.md', ''), '-', ' ') AS title,
    TO_VARCHAR(GET_PRESIGNED_URL(@DOCS_STAGE, RELATIVE_PATH)) AS content,
    RELATIVE_PATH AS source_file
FROM DIRECTORY(@DOCS_STAGE)
WHERE RELATIVE_PATH LIKE '%.md';

-- Alternative: Manual insert if stage loading is complex
-- You can also directly insert content:

TRUNCATE TABLE DOCUMENTS;

INSERT INTO DOCUMENTS (doc_id, title, content, source_file) VALUES
('doc_001', 'New Employee Onboarding Guide', 
 $$# New Employee Onboarding Guide

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
- Email and calendar
- Slack
- Confluence and Jira
- GitHub (read-only)

### Elevated Access (requires manager approval, 1-2 business days)
- Production database read access
- AWS Console (development account)
- Snowflake (analyst role)
- GitHub (write access)

### Restricted Access (requires VP approval + security review)
- Production database write access
- PII data access
- Admin consoles

## Development Environment Setup
1. Install Homebrew
2. Install required tools: git, python, node, docker
3. Clone the team repository
4. Set up pre-commit hooks
5. Configure your IDE with team settings

## First Week Goals
- Complete all compliance training modules
- Set up your development environment
- Attend team standup (daily at 9:30 AM)
- Schedule 1:1s with your direct teammates
- Read the team architecture documentation$$,
 'onboarding-guide.md'),

('doc_002', 'Data Governance Policy',
 $$# Data Governance Policy

## Data Classification Levels

### Level 1: Public
- Marketing materials, public documentation
- No special handling required

### Level 2: Internal
- Internal communications, project plans
- Must remain within corporate systems

### Level 3: Confidential
- Customer data (non-PII), financial reports, contracts
- Encrypted at rest and in transit
- Access requires role-based approval

### Level 4: Restricted (PII/PHI/PCI)
- Personally Identifiable Information (PII): names, SSN, addresses
- Protected Health Information (PHI): medical records
- Payment Card Industry (PCI): credit card numbers
- Must be encrypted with AES-256 at rest
- Tokenized or masked in non-production environments
- Access requires VP approval + annual recertification

## Data Retention Schedule
- Transaction records: 7 years
- Customer communications: 5 years
- Employee records: 7 years post-separation
- Audit logs: 10 years
- Marketing analytics: 3 years
- Temporary files: 90 days auto-purge

## PII Handling Requirements
- Collect only minimum PII necessary
- PII must reside in designated PII-approved databases only
- Never store PII in spreadsheets, emails, or local drives
- All PII access is logged and reviewed quarterly
- Cross-border transfers require Data Protection Impact Assessment

## Compliance Frameworks
Aligns with: GDPR, CCPA, SOX, PCI-DSS, HIPAA$$,
 'data-governance-policy.md'),

('doc_003', 'Incident Response Procedures',
 $$# Incident Response Procedures

## Severity Levels

### SEV-1 (Critical)
- Complete service outage affecting all customers
- Response Time: 15 minutes to acknowledge
- Communication: Immediate exec notification, status page update within 30 minutes
- Examples: Payment processing down, database corruption, confirmed security breach

### SEV-2 (High)
- Partial service degradation affecting >25% of users
- Response Time: 30 minutes to acknowledge
- Communication: Engineering leadership notified, status page within 1 hour

### SEV-3 (Medium)
- Minor impact affecting <25% of users
- Response Time: 2 hours during business hours

### SEV-4 (Low)
- No customer impact, internal tooling issues
- Response Time: Next business day

## Escalation Path
On-Call Engineer → Team Lead (30 min) → Engineering Manager (1 hour) → VP Engineering (2 hours) → CTO (4 hours)

## Incident Commander Responsibilities
1. Declare the incident — Create Slack channel
2. Assemble the team — Page relevant engineers
3. Communication cadence — Updates every 15 min for SEV-1
4. Coordinate resolution — Assign workstreams
5. Manage stakeholders — Draft customer communications
6. Call the all-clear — Schedule post-mortem

## Post-Mortem Process
Required within 5 business days for SEV-1 and SEV-2.
Focus on: Timeline, Root Cause, Impact, Detection, Resolution, Action Items.
Blameless culture: focus on systems, not individuals.

## On-Call Schedule
- Weekly rotations, Monday to Monday
- Primary and secondary on-call per service
- Acknowledge pages within 5 minutes
- Compensation: $500/week stipend + $100 per after-hours page$$,
 'incident-response.md'),

('doc_004', 'API Authentication Guide',
 $$# API Authentication Guide

## Overview
All API access uses OAuth 2.0 with JWT bearer tokens.

## Client Credentials Flow (Service-to-Service)
POST /oauth/token with grant_type=client_credentials, client_id, client_secret, scope.
Returns access_token (expires in 1 hour).

## Authorization Code Flow (User-Facing Apps)
1. Redirect user to /oauth/authorize
2. User authenticates and consents
3. Callback receives authorization code
4. Exchange code for token

## Refresh Token Flow
Access tokens expire after 1 hour. Use refresh tokens (expire after 30 days of inactivity).

## Rate Limits
- Free: 60 requests/min
- Standard: 600 requests/min
- Premium: 6,000 requests/min
- Enterprise: Custom

Rate limit headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset.
HTTP 429 when exceeded — implement exponential backoff with jitter.

## Token Best Practices
1. Never log tokens
2. Store in environment variables or secret managers (Vault, AWS Secrets Manager)
3. Minimize scope — request only what you need
4. Rotate client secrets every 90 days
5. Validate token signatures and expiration

## API Key Management
- Generate at developer-portal.internal.corp/keys
- Scoped to specific services and environments
- Production keys require security team approval
- Maximum 5 active keys per application
- Keys can be revoked instantly

## Troubleshooting
- 401: Token expired — refresh or re-authenticate
- 403: Insufficient scope — request additional scopes
- 429: Rate limited — implement backoff
- invalid_client: Wrong credentials — check for rotation$$,
 'api-authentication.md'),

('doc_005', 'Cloud Architecture Overview',
 $$# Cloud Architecture Overview

## Multi-Region Design
- us-east-1 (Primary): Main production workloads
- us-west-2 (DR): Disaster recovery, read replicas
- eu-west-1 (EU): EU data residency for GDPR

## Architecture Layers

### Edge Layer
- CloudFront CDN, AWS WAF, Route 53 with failover

### Application Layer
- EKS (Kubernetes) with auto-scaling (target 60% utilization)
- Blue-green deployments with automatic rollback on >1% error rate
- Service mesh (Istio) for mTLS

### Data Layer
- Aurora PostgreSQL (Multi-AZ) — primary database
- Snowflake — analytics warehouse via PrivateLink
- ElastiCache Redis — 3-node cluster
- S3 — cross-region replication
- Amazon MSK (Kafka) — event streaming

## Disaster Recovery
- Primary DB: RPO 1 min, RTO 15 min (Aurora Global Database)
- Object Storage: RPO 15 min, RTO 1 hour (S3 CRR)
- Application: RPO 0, RTO 5 min (multi-region active-passive)
- Snowflake: RPO 0, RTO instant (database replication)

## Network Design
- Production VPC: 10.0.0.0/16
- Subnets: Public (ALB), Private (EKS), Isolated (Database)
- NAT Gateways per AZ, VPC Flow Logs (90 day retention)
- All inter-service communication over PrivateLink

## Security Controls
- TLS 1.3 in transit, AES-256 at rest
- IAM roles with least-privilege
- GuardDuty for threat detection
- Quarterly penetration testing

## Cost Optimization
- Reserved Instances (3-year, 60% savings)
- Spot Instances for batch/dev (up to 90% savings)
- Snowflake auto-suspend after 60 seconds
- Monthly cost review (target <15% MoM growth)$$,
 'cloud-architecture.md'),

('doc_006', 'Quarterly Business Review Process',
 $$# Quarterly Business Review Process

## OKR Framework
- Objectives: Qualitative, ambitious goals (3-5 per team)
- Key Results: Measurable outcomes (2-4 per objective)
- Scoring: 0.0 to 1.0 (0.7 = good, 1.0 = sandbagged)

## QBR Schedule
- Q-1 Week: Teams draft proposed OKRs
- Q+1 Day 1-3: Previous quarter scoring + retrospective
- Q+1 Day 4-7: Cross-team alignment
- Q+1 Day 8-10: Final OKR approval by leadership
- Q+1 Day 11-14: OKRs published at all-hands

## Review Presentation (15 min per team)
1. Scorecard (2 min): Previous quarter scores, key metrics
2. Wins & Learnings (3 min): Top 3 achievements, lessons from misses
3. Next Quarter Objectives (5 min): Proposed OKRs, resource needs
4. Risks & Asks (3 min): Top risks, headcount/budget requests
5. Q&A (2 min)

## Metrics Dashboard (per team)
- Delivery: Velocity, cycle time, deployment frequency
- Quality: Bug escape rate, test coverage, incident count
- Customer: NPS, support tickets, feature adoption
- Operational: Uptime, latency p99, error rate
- Financial: Cost per transaction, infrastructure spend

## Tools
- OKR Tracking: Lattice
- Presentations: Google Slides (shared template)
- Metrics: Snowflake + Streamlit dashboards
- Action Items: Jira epics linked to OKR key results$$,
 'quarterly-review-process.md');

-- Verify
SELECT doc_id, title, source_file, LENGTH(content) AS content_length 
FROM DOCUMENTS;

-- ============================================================
-- STEP 5: Create Cortex Search Service
-- ============================================================

-- Cortex Search automatically creates embeddings and a vector index.
-- No manual EMBED_TEXT() calls needed!

CREATE OR REPLACE CORTEX SEARCH SERVICE DOC_SEARCH
  ON content
  ATTRIBUTES title, source_file
  WAREHOUSE = RAG_WH
  TARGET_LAG = '1 hour'
  AS (
    SELECT doc_id, title, content, source_file
    FROM DOCUMENTS
  );

-- Verify the service is created
SHOW CORTEX SEARCH SERVICES;

-- ============================================================
-- DONE! The Cortex Search Service is now ready.
-- Run the Streamlit app (streamlit_app.py) to search your docs.
-- ============================================================
