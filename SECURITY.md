# Security Policy

## Supported versions

Security fixes are made on the current `main` branch and released in the next
published gem version.

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability. Email
hello@goodworksonearth.org with a description, reproduction steps, affected
versions, and any suggested mitigation. We will acknowledge receipt, assess
the report privately, and coordinate disclosure and a fix.

## Deployment guidance

Configure `current_user`, `admin`, `asset_scope`, and (when needed)
`legacy_blob_scope` in every host application. Do not expose Active Storage
blob URLs as a substitute for this engine's authorized media routes.
