# Cloud Architecture Overview

## Multi-Region Design

Our platform operates across three AWS regions for high availability and compliance:

- **us-east-1 (Primary)**: Main production workloads, primary database
- **us-west-2 (DR)**: Disaster recovery, read replicas, async backup
- **eu-west-1 (EU)**: EU customer data residency (GDPR compliance)

## Architecture Layers

### Edge Layer
- CloudFront CDN for static assets and API caching
- AWS WAF for DDoS protection and IP filtering
- Route 53 with health checks and failover routing

### Application Layer
- EKS (Kubernetes) clusters in each region
- Auto-scaling based on CPU/memory (target: 60% utilization)
- Blue-green deployments with automatic rollback on error rate >1%
- Service mesh (Istio) for inter-service communication and mTLS

### Data Layer
- **Primary Database**: Aurora PostgreSQL (Multi-AZ) in us-east-1
- **Analytics**: Snowflake (Enterprise edition, multi-cluster warehouse)
- **Cache**: ElastiCache Redis cluster (3 nodes, automatic failover)
- **Object Storage**: S3 with cross-region replication for critical buckets
- **Message Queue**: Amazon MSK (Kafka) for event streaming

### Data Warehouse (Snowflake)
- Connected via AWS PrivateLink (no data traverses public internet)
- Loading: Snowpipe for real-time ingestion, batch loads via Airflow
- Compute: Separate warehouses per workload (ETL, analytics, ML)
- Storage: Enterprise-grade encryption, time travel (90 days), fail-safe (7 days)

## Disaster Recovery

| Component | RPO | RTO | Strategy |
|-----------|-----|-----|----------|
| Primary DB | 1 min | 15 min | Aurora Global Database |
| Object Storage | 15 min | 1 hour | S3 Cross-Region Replication |
| Application | 0 | 5 min | Multi-region active-passive |
| Snowflake | 0 | Instant | Database replication |
| Redis Cache | N/A | 5 min | Rebuild from DB on failover |

## Network Architecture

```
Internet → CloudFront → ALB → EKS Pods → Internal Services
                                  ↓
                          VPC Peering / PrivateLink
                                  ↓
                    Aurora / ElastiCache / S3 / Snowflake
```

### VPC Design
- Production VPC: 10.0.0.0/16 (65,536 IPs)
- Subnets: Public (ALB), Private (EKS), Isolated (Database)
- NAT Gateways in each AZ for outbound from private subnets
- VPC Flow Logs enabled for all traffic (retained 90 days)

## Security Controls

- All data encrypted in transit (TLS 1.3) and at rest (AES-256)
- IAM roles with least-privilege (no long-lived credentials)
- Security groups restrict traffic to known sources
- GuardDuty for threat detection
- Config rules for compliance monitoring
- Quarterly penetration testing by third-party firm

## Cost Optimization

- Reserved Instances for baseline compute (3-year commitment: 60% savings)
- Spot Instances for batch processing and dev/test (up to 90% savings)
- S3 Intelligent-Tiering for infrequently accessed data
- Snowflake auto-suspend warehouses after 60 seconds of inactivity
- Monthly cost review with finance (target: <15% month-over-month growth)
