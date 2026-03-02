# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, **do NOT open a public issue**.

Instead, report it privately by contacting the repository admin directly.

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You will receive a response within **48 hours**.

---

## Security Practices

### Secrets & Credentials
- Never commit secrets, API keys, tokens, or passwords to this repository
- Use `.env` files locally — they are blocked by `.gitignore`
- Use environment variables or a secrets manager in production
- Rotate any credential that is accidentally exposed immediately

### Dependencies
- Keep dependencies up to date
- Review changelogs before upgrading major versions
- Remove unused dependencies

### Access Control
- Use the principle of least privilege for all accounts and API tokens
- Revoke access immediately when no longer needed
- Enable 2FA on all accounts with repository access

### Branch Protection (recommended settings)
- Require pull request reviews before merging
- Require status checks to pass before merging
- Do not allow force pushes to `main`/`master`
- Do not allow branch deletions on protected branches

### Code Review
- All changes should go through a pull request
- Avoid committing directly to main/master
- Review diffs carefully for accidentally included secrets

---

## Supported Versions

| Branch | Supported |
|--------|-----------|
| main   | Yes       |
| others | Case by case |
