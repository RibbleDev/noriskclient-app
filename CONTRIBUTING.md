## Contributing guidelines

Thank you for contributing to the NoRisk Client Mobile App.

Security and secrets
- Never commit secrets to the repository. This includes (but is not limited to):
  - API keys, client secrets, OAuth secrets
  - Service account JSON files (Google/Firebase)
  - Keystore files and signing keys (`*.jks`, `*.keystore`, `*.p12`, `*.pfx`)
  - `key.properties`, `.env` files, or other local configuration files containing credentials
  - Private key PEM files and other private keys

- Use environment variables, CI/CD secret stores, or a secrets manager to provide credentials during builds.
- If you must share a key with a team member, use an encrypted channel or a secure secret manager — do not check it into git.
- If you accidentally commit a secret, rotate it immediately and remove it from the repo history (see note below).

Recommended workflow for signing/build keys
- Keep `key.properties` and signing keystores out of the repo. Reference them from `local.properties` or inject via CI secrets.
- Add these files to `.gitignore` so they are not tracked.

Removing leaked secrets
- If a secret was committed, don't just delete the file: remove it from git history using tools such as `git filter-repo` or the BFG Repo-Cleaner, and then rotate the credentials.

Questions
- If you're unsure whether something is safe to commit, ask in an issue or contact a repository admin.
