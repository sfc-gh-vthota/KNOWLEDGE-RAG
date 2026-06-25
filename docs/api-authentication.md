# API Authentication Guide

## Overview

All API access uses OAuth 2.0 with JWT bearer tokens. This guide covers authentication flows for service-to-service and user-facing applications.

## Authentication Flows

### Client Credentials Flow (Service-to-Service)

Use this for backend services, cron jobs, and automated pipelines.

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id=YOUR_CLIENT_ID
&client_secret=YOUR_CLIENT_SECRET
&scope=read:data write:data
```

Response:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "read:data write:data"
}
```

### Authorization Code Flow (User-Facing Apps)

Use this for web applications where a user logs in interactively.

1. Redirect user to: `GET /oauth/authorize?client_id=X&redirect_uri=Y&response_type=code&scope=Z`
2. User authenticates and consents
3. Callback receives authorization code
4. Exchange code for token: `POST /oauth/token` with `grant_type=authorization_code`

### Refresh Token Flow

Access tokens expire after 1 hour. Use refresh tokens to obtain new access tokens without re-authentication.

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token=YOUR_REFRESH_TOKEN
&client_id=YOUR_CLIENT_ID
```

Refresh tokens expire after 30 days of inactivity.

## Rate Limits

| Tier | Requests/min | Burst | Use Case |
|------|-------------|-------|----------|
| Free | 60 | 10 | Development, testing |
| Standard | 600 | 50 | Production applications |
| Premium | 6,000 | 200 | High-throughput services |
| Enterprise | Custom | Custom | Contact sales |

Rate limit headers are included in every response:
- `X-RateLimit-Limit`: Your tier's limit
- `X-RateLimit-Remaining`: Requests remaining in current window
- `X-RateLimit-Reset`: Unix timestamp when the window resets

When rate limited, you'll receive HTTP 429. Implement exponential backoff with jitter.

## Token Best Practices

1. **Never log tokens** — Treat tokens as passwords. Redact from logs and error messages.
2. **Store securely** — Use environment variables or secret managers (AWS Secrets Manager, HashiCorp Vault). Never hardcode.
3. **Minimize scope** — Request only the scopes your application needs.
4. **Rotate secrets** — Client secrets should be rotated every 90 days.
5. **Validate on receipt** — Always verify token signatures and expiration before trusting claims.

## API Key Management

For simple integrations, API keys are available as an alternative to OAuth:

- Generate keys at: developer-portal.internal.corp/keys
- Keys are scoped to specific services and environments
- Production keys require security team approval
- Keys can be revoked instantly from the developer portal
- Maximum 5 active keys per application

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| 401 Unauthorized | Token expired or invalid | Refresh the token or re-authenticate |
| 403 Forbidden | Insufficient scope | Request additional scopes |
| 429 Too Many Requests | Rate limit exceeded | Implement backoff, consider upgrading tier |
| invalid_client | Wrong client_id/secret | Verify credentials, check for rotation |
| invalid_grant | Refresh token expired | User must re-authenticate |
