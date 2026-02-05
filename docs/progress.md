# FridgeOps 進捗ログ（毎日）

> 方針：基本は追記。resource address/label は必ず plan / state / apply からコピペ（推測しない）。
> ※2026-02-05：Day6〜Day10 は読みやすさのために表現だけ統一（事実は変えない）。

---

## Day6
### 今日のねらい
- 進捗ログ（ここ）を SSOT にする
- セキュリティ文書と検証チェックリストの土台を作る（Day6 内で完結させる想定）

### 今日やったこと
- 進捗ログのフォーマットを固定
- 既存の検証証跡（Day5）を参照できる状態に整理

### Terraform 変更（resource address/label）
- なし（クラウド資源の作成/変更はしていない）

### Outputs
- なし

### 検証/証跡（docs/verify-*.txt）
- docs/verify-s3-direct-403.txt（S3 直アクセスが 403 になる：Day5 の証跡）

### メモ
- infra/main は destroy 済み（クリーン）
- infra/bootstrap は remote state（S3）/ lock（DynamoDB）を保持したまま


## Day7
### 今日のねらい
- CI 用の OIDC まわりを用意して、GitHub Actions から plan を回す下地を作る

### Terraform 変更（resource address/label）
- Created:
  - aws_iam_openid_connect_provider.github_actions
  - aws_iam_role.tf_plan

### Outputs（重要）
- github_oidc_provider_arn
  - arn:aws:iam::529928146765:oidc-provider/token.actions.githubusercontent.com
- tf_plan_role_arn
  - arn:aws:iam::529928146765:role/fridgeops-ci-tf-plan

### メモ
- Day7 は「作ったところまで」。CI 完走（証跡が残る状態）は Day8 でやる


## Day8
### 今日のねらい
- GitHub Actions（OIDC）で terraform fmt/validate/plan を CI で完走させる（infra/ci + infra/main）
- “動いた証拠が残る” ところまで持っていく

### 今日の成果（証跡）
- GitHub Actions: terraform-ci が Success
  - OIDC → fmt/validate/plan が infra/ci / infra/main 両方で完走

### Terraform 変更（resource address/label）
- なし（今日は CI/変数/フォーマット修正のみ。クラウド資源の追加作成はなし）

### 詰まりポイントと解消（メモ）
- CI が var.github_repo の入力待ちで止まる
  - → infra/ci/variables.tf に default を追加して非対話化
- state lock 取得失敗（ConditionalCheckFailedException）
  - → infra/ci で terraform init 後に force-unlock でロック解除
- Terraform fmt（infra/main）で CI が落ちる
  - → infra/main で terraform fmt 実行して修正

### 変更したファイル
- infra/ci/variables.tf（github_repo に default 追加）
- infra/main/cloudfront_static.tf（fmt）
- infra/main/s3_static_bucket_policy.tf（fmt）

### Commit
- 6cda34f: Fix: set default github_repo for CI non-interactive plan
- d63a681: chore: terraform fmt for infra/main


## Day9
### 今日のねらい
- API の型を決める（REST を採用）
- MVP の API Contract を固定して、後工程のブレを止める（GET/POST /api/items）

### 今日の成果
- ADR 追加：docs/adr/ADR-0001.md（REST 採用 + Contract 固定）

### 変更（ファイル/コミット）
- New: docs/adr/ADR-0001.md
- Commit: 98080e6 (docs(adr): decide REST API and freeze MVP contract)

### 次にやること（Day10）
- DynamoDB（items）＋ Lambda（list/add）に着手
- Contract v1（GET/POST /api/items）前提でハンドラ作成


## Day10
### 今日のねらい
- DynamoDB（items テーブル）を IaC に追加
- infra/main を apply して、検証できる状態まで持っていく

### 結果（apply）
- Apply: Resources: 11 added, 0 changed, 0 destroyed

### Outputs（重要な出力）
- cloudfront_distribution_id: E2GH725XIVJDDY
- cloudfront_domain_name: d3nzcmll7ylltp.cloudfront.net
- static_bucket_name: fridgeops-dev-static-31be4264

### Terraform 変更（resource address/label）
- Read（data）:
  - data.aws_caller_identity.current
  - data.aws_iam_policy_document.static_bucket_policy
- Created（apply）:
  - aws_cloudfront_distribution.static
  - aws_cloudfront_origin_access_control.static
  - aws_s3_bucket.static
  - aws_s3_bucket_ownership_controls.static
  - aws_s3_bucket_policy.static
  - aws_s3_bucket_public_access_block.static
  - aws_s3_bucket_server_side_encryption_configuration.static
  - aws_s3_bucket_versioning.static
  - aws_s3_object.index_html
  - aws_dynamodb_table.items
  - random_id.bucket_suffix

### DynamoDB（items）
- tf address: aws_dynamodb_table.items
- name: fridgeops-dev-items
- arn: arn:aws:dynamodb:ap-northeast-1:529928146765:table/fridgeops-dev-items
- billing: PAY_PER_REQUEST
- key: id（S）
- sse: enabled
- ttl: expiresAt（enabled）

### 検証/証跡（docs/verify-*.txt）
- なし（未作成）

### メモ（確認コマンド）
- state:
  - terraform -chdir=infra/main state list
  - terraform -chdir=infra/main state show aws_dynamodb_table.items
- outputs:
  - terraform -chdir=infra/main output
- outputs 追加:
  - items_table_name: fridgeops-dev-items
- iam:
  - policy:
    - aws_iam_policy.lambda_items_rw: created
  - name: fridgeops-dev-lambda-items-rw
  - arn: arn:aws:iam::529928146765:policy/fridgeops-dev-lambda-items-rw
  - actions: dynamodb:GetItem, dynamodb:PutItem, dynamodb:UpdateItem, dynamodb:DeleteItem, dynamodb:Query, dynamodb:Scan
  - resource: arn:aws:dynamodb:ap-northeast-1:529928146765:table/fridgeops-dev-items
  - tf: infra/main/iam_lambda_items_policy.tf
  - role:
    - aws_iam_role.lambda_items: created
  - role_name: fridgeops-dev-lambda-items-role
  - role_arn: arn:aws:iam::529928146765:role/fridgeops-dev-lambda-items-role
  - attachments:
    - aws_iam_role_policy_attachment.lambda_items_basic: AWSLambdaBasicExecutionRole
    - aws_iam_role_policy_attachment.lambda_items_rw: fridgeops-dev-lambda-items-rw
  -- output: lambda_items_role_arn: arn:aws:iam::529928146765:role/fridgeops-dev-lambda-items-role
  - tf: infra/main/iam_lambda_items_role.tf
## Day11

### 検証/証跡 (docs/verify-*.txt)
- docs/verify-lambda-items-invoke.txt: lambda invokeで items の list/add を確認（GET empty -> POST add -> GET list）

### メモ（確認コマンド）
- init/validate:
  - terraform -chdir=infra/main init
  - terraform -chdir=infra/main validate
- plan（差分確認）:
  - terraform -chdir=infra/main plan -no-color | grep '^  # '
- lambda 動作確認（AWS CLI / HTTP API v2 形式、raw payload 指定）:
  - aws lambda invoke --cli-binary-format raw-in-base64-out --function-name fridgeops-dev-items --payload '{"version":"2.0","rawPath":"/items","requestContext":{"http":{"method":"GET"}}}' /tmp/invoke_get.json && cat /tmp/invoke_get.json
  - aws lambda invoke --cli-binary-format raw-in-base64-out --function-name fridgeops-dev-items --payload '{"version":"2.0","rawPath":"/items","requestContext":{"http":{"method":"POST"}},"headers":{"content-type":"application/json"},"body":"{\"name\":\"egg\",\"quantity\":2,\"unit\":\"pcs\"}"}' /tmp/invoke_post.json && cat /tmp/invoke_post.json

### 変更内容（実装）
- workload:
  - workload/lambda/items/handler.py: items API（GET /items, POST /items）実装
  - workload/lambda/items/requirements.txt: （現状なし）
- infra:
  - infra/main/s3_static_bucket.tf: required_providers に archive を追加
  - infra/main/lambda_items.tf: archive_fileでzip作成 → aws_lambda_function.items を作成
  - infra/main/outputs.tf: items_lambda_function_name / items_lambda_function_arn を追加
  - infra/main/.terraform.lock.hcl: provider更新（terraform init により archive 追加）

### 作成/更新したリソース（Terraform address / 実体）
- aws_lambda_function.items: created
  - function_name: fridgeops-dev-items
  - arn: arn:aws:lambda:ap-northeast-1:529928146765:function:fridgeops-dev-items
  - runtime: python3.11
  - handler: handler.handler
  - role: arn:aws:iam::529928146765:role/fridgeops-dev-lambda-items-role
  - env: ITEMS_TABLE_NAME=fridgeops-dev-items
  - tf: infra/main/lambda_items.tf
- iam:
  - aws_iam_policy.lambda_items_rw: arn:aws:iam::529928146765:policy/fridgeops-dev-lambda-items-rw
  - aws_iam_role.lambda_items: fridgeops-dev-lambda-items-role / arn:aws:iam::529928146765:role/fridgeops-dev-lambda-items-role
  - aws_iam_role_policy_attachment.lambda_items_basic: AWSLambdaBasicExecutionRole
  - aws_iam_role_policy_attachment.lambda_items_rw: fridgeops-dev-lambda-items-rw
- outputs:
  - items_lambda_function_name: fridgeops-dev-items
  - items_lambda_function_arn: arn:aws:lambda:ap-northeast-1:529928146765:function:fridgeops-dev-items
- 既存 outputs（参考）:
  - cloudfront_distribution_id: E2GH725XIVJDDY
  - cloudfront_domain_name: d3nzcmll7ylltp.cloudfront.net
  - items_table_name: fridgeops-dev-items
  - lambda_items_role_arn: arn:aws:iam::529928146765:role/fridgeops-dev-lambda-items-role
  - static_bucket_name: fridgeops-dev-static-31be4264

### state（残存リソース基線）
- terraform -chdir=infra/main state list:
  - data.archive_file.lambda_items_zip
  - data.aws_caller_identity.current
  - data.aws_iam_policy_document.lambda_items_rw
  - data.aws_iam_policy_document.static_bucket_policy
  - aws_cloudfront_distribution.static
  - aws_cloudfront_origin_access_control.static
  - aws_dynamodb_table.items
  - aws_iam_policy.lambda_items_rw
  - aws_iam_role.lambda_items
  - aws_iam_role_policy_attachment.lambda_items_basic
  - aws_iam_role_policy_attachment.lambda_items_rw
  - aws_lambda_function.items
  - aws_s3_bucket.static
  - aws_s3_bucket_ownership_controls.static
  - aws_s3_bucket_policy.static
  - aws_s3_bucket_public_access_block.static
  - aws_s3_bucket_server_side_encryption_configuration.static
  - aws_s3_bucket_versioning.static
  - aws_s3_object.index_html
  - random_id.bucket_suffix
### 今日收尾
- terraform -chdir=infra/main destroy: Destroy complete（Resources: 16 destroyed）
- terraform -chdir=infra/main state list: no output（state empty）
