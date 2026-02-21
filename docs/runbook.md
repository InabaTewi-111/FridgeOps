# FridgeOps Runbook (v1)

## Facts (ap-northeast-1)
- CloudFront: https://d3cjucnmtwwxvv.cloudfront.net
- Distribution ID: E24GQ7URINXRLI
- Static bucket: fridgeops-dev-static-26f5e151
- API base: https://os4mggbvz9.execute-api.ap-northeast-1.amazonaws.com
- DynamoDB: fridgeops-dev-items
- Lambda: fridgeops-dev-items
- Lambda role: arn:aws:iam::529928146765:role/fridgeops-dev-lambda-items-role

---

## Deploy / Update

Prereq:
- AWS CLI logged-in (ap-northeast-1)
- Terraform backend already configured (infra/bootstrap)
- Terraform already applied in infra/main

Commands:

terraform -chdir=infra/main init
terraform -chdir=infra/main apply

aws s3 cp infra/main/index.html s3://fridgeops-dev-static-26f5e151/index.html
aws s3 sync workload/static/ui/ s3://fridgeops-dev-static-26f5e151/ui/ --delete

aws cloudfront create-invalidation --distribution-id E24GQ7URINXRLI --paths "/*"

---

## Verify

- Open (frontend): https://d3cjucnmtwwxvv.cloudfront.net
- API base: https://os4mggbvz9.execute-api.ap-northeast-1.amazonaws.com

Quick API check:

curl -sS https://os4mggbvz9.execute-api.ap-northeast-1.amazonaws.com/items | head

Terraform outputs:

terraform -chdir=infra/main output -no-color

---

## Destroy / Cleanup

Destroy infra/main:

terraform -chdir=infra/main destroy

(Optional) Destroy infra/bootstrap:
Only when you want to remove remote state bucket + lock table.

terraform -chdir=infra/bootstrap destroy

Confirm state is empty:

terraform -chdir=infra/main state list
