##### \# Cloud DevSecOps Lab

##### 

##### Hands-on AWS \& GCP infrastructure projects with security built in — Terraform, CI/CD, IAM least-privilege, and DevSecOps practices. 

##### 

##### \## Projects

##### 

##### \### Project 1: Static Site on S3 with Automated, Security-Gated Deployment ✅

##### 

##### \*\*What it does:\*\*

##### A static website hosted on AWS S3, deployed automatically via GitHub Actions. Every push to `main` triggers a secret-scanning check before deployment is allowed to run.

##### 

##### \*\*Architecture:\*\*

##### ```mermaid

##### flowchart LR

##### &#x20;   A\[Developer pushes to main] --> B\[GitHub Actions triggered]

##### &#x20;   B --> C\[secret-scan job: gitleaks]

##### &#x20;   C -->|Pass| D\[deploy job: configure AWS credentials]

##### &#x20;   D --> E\[Upload index.html to S3]

##### &#x20;   E --> F\[Live site on S3 static hosting]

##### &#x20;   C -->|Fail| G\[Pipeline stops — deployment blocked]

##### 

##### &#x20;   style F fill:#2ecc71,color:#000

##### &#x20;   style G fill:#e74c3c,color:#fff

##### ```

##### 

##### \*\*Stack:\*\*

##### \- AWS S3 (static website hosting)

##### \- GitHub Actions (CI/CD)

##### \- gitleaks (secret scanning, required check)

##### \- IAM (scoped deploy user, not root)

##### 

##### \*\*Live site:\*\* http://cloud-devsecops-lab-lana-2026.s3-website-us-east-1.amazonaws.com

##### 

##### \*\*Security decisions:\*\*

##### \- Deployment uses a dedicated IAM user (`deployUser`) rather than root credentials

##### \- AWS credentials are stored as GitHub encrypted secrets, never committed to the repo

##### \- `.gitignore` explicitly excludes `.pem`, `.key`, `.env`, and credential files

##### \- Secret scanning (`gitleaks`) runs as a required job before deploy — a failed scan blocks the pipeline entirely

##### \- The S3 bucket policy grants public \*\*read-only\*\* access (`s3:GetObject`) scoped to this one bucket only — this is intentional for a public static site, and is separate from account-level access, which remains locked down

##### \- Verified the secret-scanning gate actually blocks bad deploys: an initial test using AWS's publicly documented example key silently passed (it's allowlisted by scanners as a known placeholder). A second test with a realistic-but-fake key was correctly detected, failing the scan and blocking deployment.

##### 

##### \*\*Known tradeoff (deliberate, not overlooked):\*\*

##### The `deployUser` IAM policy currently uses `AmazonS3FullAccess`. This is broader than necessary — a future iteration will scope this down to a custom policy limited to `s3:PutObject` / `s3:GetObject` on this specific bucket ARN only, following least-privilege principles.

##### 

##### \*\*Problems hit and fixed:\*\*

##### \- `AccessControlListNotSupported` error when uploading with `--acl public-read` — modern S3 buckets block ACLs by default. Fixed by disabling "Block Public Access" and applying an explicit bucket policy instead, which is the current recommended approach over ACLs.

##### \- GitHub rejected a push containing changes to `.github/workflows/` because the Personal Access Token lacked the `workflow` scope — regenerated the token with `repo` + `workflow` scopes.

##### 

##### \*\*AWS Cloud Practitioner exam relevance:\*\* IAM users/policies, S3 storage and access control, shared responsibility model (AWS secures the infrastructure; I'm responsible for configuring bucket permissions correctly).

##### 

##### \---

##### 

