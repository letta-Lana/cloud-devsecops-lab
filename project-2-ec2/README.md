\# Project 2: EC2 Instance via Terraform with Basic Hardening



\## What it does

An AWS EC2 instance provisioned entirely through Terraform (infrastructure-as-code, not console clicks), running nginx, with SSH locked to a single IP and key-only authentication verified.



\## Architecture

Terraform (main.tf) → AWS API → Security Group + Key Pair + EC2 Instance

↓

nginx installed \& enabled

↓

Publicly reachable on port 80

SSH reachable on port 22 (single IP only)



\## Stack

\- Terraform (`\~> 5.0` AWS provider)

\- Amazon Linux 2023 (`t3.micro`, free-tier eligible)

\- nginx

\- AWS Systems Manager (used read-only, to look up current AMI IDs)



\## Security decisions

\- SSH ingress restricted to a single `/32` CIDR (my IP only), not open to the internet

\- HTTP (port 80) open to the world — intentional, it's a public web server

\- Key-only SSH authentication — verified directly via `sshd\_config` (`PasswordAuthentication no`), not assumed

\- Private SSH key excluded from git via `.gitignore`, verified with `git check-ignore` before committing

\- `nginx` set to persist across reboots (`systemctl enable`)

\- IAM: `deployUser` granted `AmazonEC2FullAccess` and `AmazonSSMReadOnlyAccess` — broader than strictly necessary; a future iteration should scope this to a custom least-privilege policy



\## Problems hit and fixed

\- \*\*Wrong region AMI\*\*: initial AMI ID was for `us-east-1`, but resources are in `eu-west-2` — AMI IDs are region-specific. Fixed by querying the correct AMI via AWS Systems Manager Parameter Store instead of hardcoding an ID (the professional approach, since it stays current automatically).

\- \*\*Free-tier instance type mismatch\*\*: `t2.micro` isn't free-tier eligible on this account/region; `t3.micro` is. Verified directly with `aws ec2 describe-instance-types` rather than guessing.

\- \*\*SSH key passphrase issue\*\*: initial key generation via CLI flags (`-N '""'`) didn't produce a truly blank passphrase due to Windows shell quoting. Regenerated interactively, which required also forcing Terraform to replace the EC2 instance (`terraform apply -replace`) since AWS key pairs are only injected into a server at first boot — updating the key pair resource alone doesn't retroactively update an already-running instance.



\## Cost note

This instance is stopped/terminated when not actively being tested, per free-tier hygiene (see repo root README for the reasoning).

