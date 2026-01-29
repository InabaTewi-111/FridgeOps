# FridgeOps 進捗ログ（毎日）

> ルール：毎日「追記のみ」。過去分は書き換えない。Terraform の resource address/label は plan/apply 出力からコピーする（推測禁止）。

---

## 2026-01-29（Day6）
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
