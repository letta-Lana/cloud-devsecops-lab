\# Project 4: GCP Storage Parity + Cloud Function Extension (Partial)



\## What it does

Part 1 (complete): A Google Cloud Storage bucket, provisioned via Terraform, with public read access granted through IAM bindings. A test HTML file was uploaded and confirmed publicly accessible — direct GCP equivalent of Project 1's S3 static site, proving the underlying cloud concepts (storage, public access control, IaC workflow) transfer across providers, not just AWS-specific knowledge.



Part 2 (blocked, documented as-is): An extension mirroring Project 3's S3→Lambda pipeline, this time as GCP Storage→Cloud Function. Goal: uploading a file to the bucket should automatically trigger a Cloud Function that logs the filename and bucket name, proving the event-driven pattern also transfers across providers. The bucket, Python code, service account, and all required IAM permissions were successfully created — the function itself failed to complete deployment at the final trigger-wiring stage.



\## Architecture (intended, Part 2)



File uploaded to bucket

↓

Eventarc detects the change

↓

Trigger routes event via Pub/Sub → Cloud Function

↓

Function executes, logs filename + bucket to Cloud Logging

## Stack

\- Terraform (`\~> 6.0` Google provider)

\- Google Cloud Storage (bucket)

\- Google Cloud Functions (2nd gen)

\- Google IAM (service account + project-level role bindings)

\- Google Cloud Build, Eventarc, Pub/Sub (supporting services required by 2nd-gen Cloud Functions)

\- Python 3.12



\## Security decisions

\- Storage bucket uses `uniform\_bucket\_level\_access`, required by an organization-level policy constraint on this account — a stricter, more modern access-control model than legacy per-object ACLs, conceptually similar to AWS's move away from ACLs.

\- Public read access on the bucket was granted explicitly via a `google\_storage\_bucket\_iam\_member` resource (`roles/storage.objectViewer` for `allUsers`) — GCP defaults to private, same as AWS, just a different mechanism (IAM bindings rather than a bucket policy document).

\- The Cloud Function's service account was granted only the specific roles needed for its job: `roles/logging.logWriter` (write execution logs) and `roles/eventarc.eventReceiver` (receive triggered events) — not a broad admin role.



\## Problems hit and fixed

\- \*\*Organization constraint blocking bucket creation\*\*: initial `apply` failed with `constraints/storage.uniformBucketLevelAccess`. Fixed by explicitly setting `uniform\_bucket\_level\_access = true` on the bucket resource, matching an org-wide policy rather than fighting it.

\- \*\*Cloud Functions API not enabled\*\*: first `apply` attempt on the function failed since the Cloud Functions API (and related APIs: Cloud Build, Cloud Run, Eventarc, Pub/Sub, which 2nd-gen functions depend on) had never been used on this project. Enabled via `gcloud services enable`.

\- \*\*IAM propagation delay\*\*: even after confirming via `gcloud services list --enabled` that the API was genuinely active, the very next `apply` failed with the same error. Waiting several minutes resolved it — a repeat of the same "eventual consistency" lesson from Project 3, this time with a longer delay since a whole API activation (not just a policy attachment) was involved.

\- \*\*Eventarc service account lacked bucket read access\*\*: trigger validation failed with `storage.buckets.get` denied for GCP's own managed Eventarc service account (a distinct identity from the function's own service account). Fixed by granting `roles/storage.objectViewer` to `service-{PROJECT\_NUMBER}@gcp-sa-eventarc.iam.gserviceaccount.com`.

\- \*\*Function's service account lacked event-receiving permission\*\*: separately from the above, the function's own service account needed `roles/eventarc.eventReceiver` explicitly granted to actually receive routed events, not just for Eventarc to validate the bucket.

\- \*\*Cloud Build's default service account lacked build permissions\*\*: function creation proceeded further but failed during the actual build step, since GCP's default Compute Engine service account (reused by Cloud Build) lacked `roles/cloudbuild.builds.builder`.

\- \*\*Final blocker (unresolved)\*\*: after all five permission fixes above, function creation still fails at trigger creation, with GCP's own error message citing two possible causes (Cloud Storage service agent unable to read the Eventarc-created Pub/Sub topic, or a bucket notification quota issue) without confirming which. This reflects a known, documented rough edge in 2nd-gen Cloud Functions' Storage-trigger wiring, distinct from the previous five errors in that even GCP's own tooling doesn't pinpoint a single definitive cause.



\## Known tradeoffs / current state

\- Part 1 (bucket + public file) is fully functional and verified in-browser.

\- Part 2 (Cloud Function trigger) has all supporting infrastructure correctly deployed but is not yet fully operational — left in this state deliberately rather than abandoning or reverting, since the five resolved permission errors already demonstrate real GCP IAM/event-architecture troubleshooting.

\- Six distinct permission/configuration issues were diagnosed and resolved (or attempted) in sequence for a single resource — worth noting as a genuine illustration of how fragmented GCP's identity model is across 2nd-gen Cloud Functions' supporting services (function's own service account, Eventarc's managed account, Cloud Build's default account), compared to AWS Lambda's simpler two-piece permission model (IAM role + resource-based Lambda permission).



