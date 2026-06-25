# Data Governance Policy

## Purpose

This policy establishes standards for data classification, handling, retention, and disposal across all systems and environments.

## Data Classification Levels

### Level 1: Public
- Marketing materials, public documentation
- No special handling required
- Can be shared externally without approval

### Level 2: Internal
- Internal communications, project plans, non-sensitive business data
- Must remain within corporate systems
- Do not share externally without manager approval

### Level 3: Confidential
- Customer data (non-PII), financial reports, contracts
- Encrypted at rest and in transit
- Access requires role-based approval
- Audit logging mandatory

### Level 4: Restricted (PII/PHI/PCI)
- Personally Identifiable Information (PII): names, SSN, addresses, phone numbers
- Protected Health Information (PHI): medical records, insurance data
- Payment Card Industry (PCI): credit card numbers, CVVs
- Must be encrypted with AES-256 at rest
- Tokenized or masked in non-production environments
- Access requires VP approval + annual recertification
- Full audit trail with 7-year retention

## Data Retention Schedule

| Data Type | Retention Period | Disposal Method |
|-----------|-----------------|-----------------|
| Transaction records | 7 years | Secure deletion |
| Customer communications | 5 years | Secure deletion |
| Employee records | 7 years post-separation | Secure deletion |
| Audit logs | 10 years | Archive then delete |
| Marketing analytics | 3 years | Standard deletion |
| Temporary/working files | 90 days | Auto-purge |

## PII Handling Requirements

### Collection
- Collect only the minimum PII necessary for the business purpose
- Inform data subjects of collection through privacy notices
- Obtain consent where required by jurisdiction (GDPR, CCPA)

### Storage
- PII must reside in designated PII-approved databases only
- Never store PII in spreadsheets, emails, or local drives
- All PII databases must have column-level encryption enabled

### Access
- PII access requires completion of annual privacy training
- Access is granted on a need-to-know basis with time-limited approvals
- All PII access is logged and reviewed quarterly

### Sharing
- PII must never be shared via email or chat
- Use approved secure file transfer mechanisms only
- Cross-border transfers require Data Protection Impact Assessment (DPIA)

## Compliance Frameworks

This policy aligns with:
- GDPR (General Data Protection Regulation)
- CCPA (California Consumer Privacy Act)
- SOX (Sarbanes-Oxley) for financial data
- PCI-DSS for payment card data
- HIPAA for health information (where applicable)

## Violations

Violations of this policy may result in:
- Mandatory retraining
- Access revocation
- Disciplinary action up to termination
- Regulatory fines (personal liability in some jurisdictions)

Report potential violations to security@company.com or the anonymous ethics hotline.
