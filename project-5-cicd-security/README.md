\# Project 5: CI/CD Security Pipeline (Cloud-Agnostic)



\## What it does

A GitHub Actions pipeline that runs three automated security checks on every push to `main`: secret scanning, static code analysis (SAST), and dependency vulnerability scanning. Unlike a scan that only reports findings, this pipeline gates on the results — a failure blocks the pipeline from completing successfully, removing the need for a human to notice and act on a finding manually. Deliberately cloud-agnostic: no AWS/GCP resources involved, focused purely on application and pipeline security, distinct from Projects 1-4's infrastructure focus.



\## Architecture



Push to GitHub

↓

┌────────────┬────────────┬──────────────────┐

↓            ↓            ↓

secret-scan   sast-scan   dependency-scan

(gitleaks)    (Bandit)    (pip-audit)

↓            ↓            ↓

└── all three must pass for a green pipeline ──┘



\## Stack

\- Python 3.12, Flask (minimal demo app — the app itself isn't the point, it exists to give the scanners real code and real dependencies to check)

\- GitHub Actions

\- gitleaks (secret scanning)

\- Bandit (Python-specific SAST)

\- pip-audit (dependency vulnerability scanning against a known-CVE database)



\## Security decisions

\- All three checks run as independent, parallel jobs rather than one combined script — a failure in one is clearly attributable, and jobs can be triaged separately.

\- No `needs:` dependency chain between the three jobs (unlike Project 1, where deploy waited on the scan) — here, each job is itself the gate; there's no downstream deploy step to protect in this project.

\- Dependency pinning (`flask==X.X.X` rather than an unpinned `flask`) is required for `pip-audit` to check exact, known versions against its vulnerability database — an unpinned dependency can't be meaningfully scanned.



\## Problems hit and fixed

\- \*\*Workflow file in the wrong location\*\*: initially created `.github/workflows/` inside the project subfolder rather than the repository root. GitHub Actions only recognizes workflow files at the repo root — the workflow was silently never triggered until moved. A good reminder that GitHub Actions has stricter location requirements than Terraform, which doesn't care where `.tf` files live.

\- \*\*Bandit correctly flagged a real vulnerability\*\*: `app.run(debug=True)` in `app.py` — Flask's debug mode exposes an interactive debugger capable of executing arbitrary code if the app were ever exposed publicly with it enabled. Fixed by setting `debug=False`. This was the SAST check working exactly as intended, not a false positive.

\- \*\*pip-audit path mismatch\*\*: the workflow initially pointed at `requirements.txt` from the repo root, but the file lives inside `project-5-cicd-security/`. Fixed by specifying the full relative path in the workflow file.

\- \*\*pip-audit correctly flagged a real, CVE-numbered vulnerability\*\*: once the path was fixed, the scan found Flask `3.0.0` (the originally pinned version) vulnerable under `PYSEC-2026-2151`, with a fix available in `3.1.3`. Fixed by upgrading the pinned version and reinstalling locally to match — genuine proof the dependency scanner catches real, current vulnerabilities, not just a configuration exercise.

\- \*\*Local pip/Windows install friction (unrelated to the pipeline itself)\*\*: local `pip install` repeatedly failed to fully replace an in-use `flask.exe` file due to Windows file-locking, and a separate pip self-upgrade attempt partially broke pip entirely (`ModuleNotFoundError: No module named 'pip'`), fixed via `python -m ensurepip --upgrade`. Running the terminal as Administrator resolved the underlying file-lock issue. Worth noting this was purely a local development-environment issue — the GitHub Actions pipeline installs dependencies fresh in a clean Linux environment on every run and was unaffected by any of this.

\- \*\*Transient git-history error in secret-scan\*\*: an early run of `secret-scan` failed with a git "ambiguous argument" error tied to a specific commit reference, unrelated to any actual secret. Resolved itself on the next push once the branch history moved past the affected commit.



\## Known tradeoffs

\- The demo Flask app is intentionally minimal — its only purpose is to give the three scanners something real to check, not to demonstrate application functionality.

\- No `needs:` gating to a deploy step exists in this project, since there's nothing to deploy — in a real pipeline, these same three jobs would typically gate an actual deployment or merge-to-main step, as demonstrated conceptually in Project 1's `secret-scan → deploy` pattern.



