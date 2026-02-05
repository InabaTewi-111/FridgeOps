# FridgeOps 進捗ログ（毎日）

> ルール：毎日「追記のみ」。過去分は書き換えない。Terraform の resource address/label は plan/apply 出力からコピーする（推測禁止）。

---

## Day6
### 今日の目的
- 進捗ログ（SSOT）を固定する
- セキュリティ文書と検証チェックリストの土台を作る（Day6 内で実施）

### Terraform 変更（resource address/label）
- N/A（Day6 はクラウド資源の作成/変更なし）

### Outputs（重要な出力）
- N/A

### 検証/証跡（docs/verify-*.txt）
- docs/verify-s3-direct-403.txt（S3 直アクセスが 403 になる証跡：Day5）

### メモ
- 現状：infra/main は destroy 済み（クリーン）。infra/bootstrap は remote state（S3）と lock（DynamoDB）を保持。

### Day7（途中）: CI（OIDC）進捗
- Created: aws_iam_openid_connect_provider.github_actions
- Output: github_oidc_provider_arn = arn:aws:iam::529928146765:oidc-provider/token.actions.githubusercontent.com
- Created: aws_iam_role.tf_plan（fridgeops-ci-tf-plan）
- Output: tf_plan_role_arn = arn:aws:iam::529928146765:role/fridgeops-ci-tf-plan
## Day8
### 今日の目的
- GitHub Actions（OIDC）で terraform fmt/validate/plan をCIで回す（infra/ci + infra/main）
- CI を「実行して証拠が残る状態」まで到達させる（Day8 完了条件）

### Terraform 変更（resource address/label）
- 変更なし（※今日はCI/変数/フォーマット修正のみ。クラウド資源の追加作成はなし）

### Outputs（重要な出力）
- N/A（変更なし）

### 検証/証跡
- GitHub Actions: terraform-ci が Success（OIDC → fmt/validate/plan が infra/ci / infra/main 両方で完走）

### やったこと / 詰まりポイントと解消
- CI が var.github_repo の入力待ちで停止 → infra/ci/variables.tf に default を追加して非対話化
- CI が state lock 取得失敗（ConditionalCheckFailedException）→ infra/ci で terraform init 後に force-unlock 
でロック解除
- CI が Terraform fmt (infra/main) で失敗 → infra/main で terraform fmt 実行してフォーマット修正

### 変更したファイル
- infra/ci/variables.tf（github_repo に default 追加）
- infra/main/cloudfront_static.tf（fmt）
- infra/main/s3_static_bucket_policy.tf（fmt）

### Commit
- 6cda34f: Fix: set default github_repo for CI non-interactive plan
- d63a681: chore: terraform fmt for infra/main

## Day9
### 今日の目的
- API の型を決める（REST API を採用）
- MVP の API Contract を固定して後工程のブレを止める

### 今日の成果
- ADR を追加：docs/adr/ADR-0001.md（REST 採用 + Contract 固定）

### 変更（ファイル/コミット）
- New: docs/adr/ADR-0001.md
- Commit: 98080e6 (docs(adr): decide REST API and freeze MVP contract)

### 次にやること（Day10 へ）
- DynamoDB（items テーブル）＋ Lambda（list/add）実装に着手
- Contract v1（GET/POST /api/items）前提でハンドラ作成

