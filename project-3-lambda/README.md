\# Project 3: Serverless S3-to-Lambda Pipeline with Least-Privilege IAM



\## What it does

A fully event-driven pipeline: uploading a file to an S3 bucket automatically triggers an AWS Lambda function, which reads the file's name and bucket, logs it, and returns a success response. No server runs continuously — the function only exists and costs money for the brief moment it's actually executing.



\## Architecture



File uploaded to S3 bucket

↓

S3 event fires (ObjectCreated)

↓

Lambda permission confirms S3 is allowed to invoke this function

↓

Bucket notification routes the event to the Lambda function

↓

Lambda executes lambda\_handler(event, context)

↓

Logs written to CloudWatch



\## Stack

\- Terraform (`\~> 5.0` AWS provider)

\- AWS S3 (event source)

\- AWS Lambda (Python 3.9 runtime)

\- AWS IAM (execution role + resource-based permission)

\- AWS CloudWatch (execution logging)



\## Security decisions

\- Lambda's IAM role is scoped to only what it needs to run and log — `AWSLambdaBasicExecutionRole`, granting CloudWatch logging only, nothing broader.

\- The `aws\_lambda\_permission` resource restricts invocation to this specific S3 bucket only, via `source\_arn` scoped to the bucket's ARN. Without this restriction, any S3 bucket in any AWS account could theoretically attempt to invoke this function — scoping it closes that gap.

\- `depends\_on` was used to explicitly force the invoke permission to be created before the bucket notification, since S3 rejects notification setup if the permission doesn't already exist — Terraform doesn't infer this ordering automatically from the code alone.



\## Problems hit and fixed

\- \*\*IAM role creation blocked\*\*: `deployUser` had no IAM permissions at all initially. Rather than granting broad `IAMFullAccess` immediately, first attempted a custom scoped policy limited to `lambda-\*` named roles.



\- \*\*Scoped policy proved insufficient\*\*: the custom policy needed to be expanded multiple times as Terraform's actual IAM read/verify calls (`ListRolePolicies`, `ListAttachedRolePolicies`, `ListInstanceProfilesForRole`) surfaced one at a time through repeated `AccessDenied` errors. After several rounds of reactively patching the policy, switched to the AWS-managed `IAMFullAccess` policy instead. This was a deliberate tradeoff, not a shortcut: IAM role management genuinely requires a wide set of read/write actions to work reliably with Terraform's plan/apply/destroy lifecycle, and scoping it narrowly is one of the harder least-privilege cases in AWS — even in real teams, tooling/CI identities often carry broader IAM permissions than application-facing ones.



\- \*\*Resource left "tainted" after a failed delete\*\*: a failed `terraform destroy` step (blocked by a missing permission mid-operation) left the IAM role marked as `tainted` in Terraform's state. The next `apply` correctly detected this and destroyed/recreated the role cleanly once permissions were fixed — a good example of Terraform's state tracking protecting against silent drift.

\- \*\*IAM propagation delay\*\*: after attaching `AWSLambda\_FullAccess` to `deployUser`, the very next `apply` still failed with the same `AccessDenied` error, even though `aws iam list-attached-user-policies` confirmed the policy was attached. Waiting \~30-60 seconds and retrying resolved it — AWS IAM permission changes are not always instant globally ("eventual consistency"), a known distributed-systems tradeoff worth expecting in future IAM work.



\## Known tradeoffs (deliberate, not overlooked)

\- `deployUser` now holds `IAMFullAccess`, broader than a real production CI/deploy identity should have long-term. A more mature setup would use a dedicated, tightly-scoped role specifically for Terraform automation, separate from a general-purpose deploy user, likely combined with AWS's `iam:PermissionsBoundary` feature to hard-cap what it could ever grant, even accidentally.

\- Lambda runtime is Python 3.9, an older supported version — a newer runtime (3.12/3.13) would be a simple future upgrade.



\## Verified, not assumed

\- After deployment, manually uploaded a test file via `aws s3 cp` and confirmed via `aws logs tail` that Lambda actually executed, correctly extracted the real filename and bucket name from the event payload, and logged them — not just that the pipeline deployed without error.



