# FridgeOps 進捗ログ（SSOT）

## 現状（Day12 / infra/main apply 済み）

v1（優先）
- CloudFront を入口に固定
  - default: private S3（OAC）
  - /api/*: API Gateway（HTTP API / apigatewayv2）
- API: Lambda items（list/add）+ DynamoDB
- CI: GitHub Actions + OIDC（long-lived key なし）
- Observability: CloudWatch（Logs + Alarm 最小 1つ）

v2（後で）
- OpenAI / cache / risk & cost control（v1 に混ぜない）

---

## Day1（repo の骨格）
- repo の骨格を作成（infra/bootstrap, infra/main, docs, workload の前提）
- README / docs の入口を用意（最低限）

Terraform 変更
- なし

---

## Day2（v1 の構成を先に固定）
- v1 の構成（CloudFront entry / OAC / /api/*）を文章と図で整理
- 以降の実装が迷子にならないように “入口” と “境界” を先に決めた


## Day3（bootstrap / remote state）
- state 分裂を防ぐ（S3 backend + DynamoDB lock）

Terraform 変更（resource address/label）
- Created（infra/bootstrap）
  - aws_s3_bucket.tfstate → S3 bucket: fridgeops-dev-tfstate-fd25e7e4
  - aws_dynamodb_table.tf_lock → DynamoDB table: fridgeops-dev-tf-lock


## Day4（infra/main の土台を作る）
やったこと
- infra/main の土台（static 側中心）を組み始めた
- apply/destroy の型を作るための下準備


---

## Day5（CloudFront + OAC の drift 収束 / 証跡）
- CloudFront + OAC の drift を潰して plan を安定化
- S3 direct 403（OAC 有効）の証跡を残した
- その日の main を destroy して “片付く” ところまで確認

証跡
- docs/verify-s3-direct-403.txt（S3 直アクセスが 403）

---

## Day6（ログ整備）
- 進捗ログのフォーマットを固定
- 既存の証跡（Day5）を参照できる状態に整理

---

## Day7（OIDC 基礎）
- CI 用の OIDC provider / role を作成（次で Actions を完走させる）

Terraform 変更（resource address/label）
- Created（infra/ci）
  - aws_iam_openid_connect_provider.github_actions
  - aws_iam_role.tf_plan

Outputs（重要）
- github_oidc_provider_arn:
  - arn:aws:iam::529928146765:oidc-provider/token.actions.githubusercontent.com
- tf_plan_role_arn:
  - arn:aws:iam::529928146765:role/fridgeops-ci-tf-plan

---

## Day8（CI 完走）
やったこと
- GitHub Actions（OIDC）で terraform fmt/validate/plan を完走（証跡が残る状態）

Terraform 変更
- なし（クラウド資源の追加作成なし）

---

## Day9（API 方針の履歴 / v1-v2 の整理）
やったこと（当時）
- docs/adr/ADR-0001.md を追加（REST 案 + Contract 固定）

メモ（いまの正）
- 実体は HTTP API（apigatewayv2）で固まっている
- REST 案は履歴として残す（Superseded 扱い）
- v1 を優先して “検収できる E2E” に寄せる方針に切り替えた

---

## Day10（DynamoDB + IAM）
やったこと
- DynamoDB（items）を追加
- Lambda 用 IAM（role/policy/attachment）を整理

DynamoDB（items）
- tf address: aws_dynamodb_table.items
- name: fridgeops-dev-items
- arn: arn:aws:dynamodb:ap-northeast-1:529928146765:table/fridgeops-dev-items
- billing: PAY_PER_REQUEST
- key: id（S）
- sse: enabled
- ttl: expiresAt（enabled）

IAM（items）
- policy:
  - aws_iam_policy.lambda_items_rw（fridgeops-dev-lambda-items-rw）
- role:
  - aws_iam_role.lambda_items（fridgeops-dev-lambda-items-role）
- attachments:
  - aws_iam_role_policy_attachment.lambda_items_basic（AWSLambdaBasicExecutionRole）
  - aws_iam_role_policy_attachment.lambda_items_rw（fridgeops-dev-lambda-items-rw）

---

## Day11（Lambda items 実装 + invoke 証跡）
証跡
- docs/verify-lambda-items-invoke.txt
  - lambda invoke で items の list/add を確認（GET empty → POST add → GET list）

実装（要点）
- workload/lambda/items/handler.py: GET /items, POST /items
- infra/main/lambda_items.tf: zip → aws_lambda_function.items
- outputs 追加: items_lambda_function_name / items_lambda_function_arn

当時の収尾
- terraform -chdir=infra/main destroy（Resources: 16 destroyed）
- state empty（main はクリーン）

---

## Day12（HTTP API + CloudFront /api/* 合流 / apply）
結果（apply）
- Apply complete! Resources: 22 added, 0 changed, 0 destroyed.

Outputs（参考：直近）
- cloudfront_distribution_id = E1NKKAKYVQ3EH9
- cloudfront_domain_name     = dilvuf142d1ls.cloudfront.net
- items_lambda_function_arn   = arn:aws:lambda:ap-northeast-1:529928146765:function:fridgeops-dev-items
- items_lambda_name           = fridgeops-dev-items
- items_table_name            = fridgeops-dev-items
- lambda_items_role_arn       = arn:aws:iam::529928146765:role/fridgeops-dev-lambda-items-role
- static_bucket_name          = fridgeops-dev-static-fc37572a

plan に出る主要（概観）
- API（HTTP API / apigatewayv2）:
  - aws_apigatewayv2_api.items
  - aws_apigatewayv2_integration.*
  - aws_apigatewayv2_route.*（GET/POST）
  - aws_apigatewayv2_stage.default
- Lambda:
  - aws_lambda_function.items
  - aws_lambda_permission.apigw_invoke
- DynamoDB:
  - aws_dynamodb_table.items
- Static:
  - aws_cloudfront_distribution.static
  - aws_cloudfront_origin_access_control.static
  - aws_s3_bucket.static / policy / object

## Day12: CloudFront /api/* Route (apply成功)

- `terraform -chdir=infra/main output` (apply後の出力)
  - cloudfront_distribution_id: E24GQ7URINXRLI
  - cloudfront_domain_name: d3cjucnmtwwxvv.cloudfront.net
  - static_bucket_name: fridgeops-dev-static-26f5e151
  - items_table_name: fridgeops-dev-items
  - items_lambda_function_name: fridgeops-dev-items
  - items_lambda_function_arn: arn:aws:lambda:ap-northeast-1:529928146765:function:fridgeops-dev-items
  - lambda_items_role_arn: arn:aws:iam::529928146765:role/fridgeops-dev-lambda-items-role

- 状態
  - Day12 の apply は成功（CloudFront / DynamoDB / Lambda の出力が揃っている）


  ## Day13: 方針変更（CloudFront 経由の API 転送をやめる）

- 方針変更（v1）
  - CloudFront の `/api/*` ルーティング（API Gateway への転送 / reverse proxy）を撤回し、CloudFront は静的配信（S3 + OAC）のみに戻した。
  - 理由: CloudFront + APIGW 転送は制約/差分が多く手戻りが発生しやすく、v1 のスコープ（静的配信の安全デフォルト + IaC 再現性）に対してコスト過大だったため。
- 検証
  - `docs/verify-cloudfront-root-200.txt`（CloudFront ルート `HTTP/2 200` を保存）

## Day14:フロントエンドの更新とUIの設置、V1の仕上げ
  - フロントエンドv1を実装し、完走した。
  - UI画像を作って実装を試した。
  - フロントエンドの微調整を行なった。
---

# v1 検収チェック（現行）

ルール
- チェックは必ず “実行ログ / コマンド出力 / 画面キャプチャ” を添付（docs/verify-*.txt）
- v2（OpenAI 等）はここに入れない

## 1. 実行情報（Run Info）
- Date:
- Git commit:
- AWS Region: ap-northeast-1
- State:
  - infra/bootstrap: 保持
  - infra/ci: 保持
  - infra/main: apply/destroy 対象

## 2. 重要な出力（Outputs）
- CloudFront Domain:
- CloudFront Distribution ID:
- Static S3 Bucket Name:
- DynamoDB Table Name:
- Lambda Name:
- 証跡:
  - docs/outputs-current.txt（terraform -chdir=infra/main output の全文）

## 3. DoD 検証（必須）

### 3.1 CloudFront で静的ページが表示できる
- [ ] CloudFront の URL にアクセスして 200/HTML が返る
- 証跡:
  - docs/verify-cf-root-200.txt（curl -I など）

### 3.2 S3 直アクセスが 403（バイパス不可 / OAC 有効）
- [ ] S3 オブジェクト直アクセスで 403 が返る（署名無し）
- 証跡:
  - docs/verify-s3-direct-403.txt

### 3.3 GitHub Actions（OIDC）で fmt/validate/plan が成功（AWS Key 不使用）
- [ ] Workflow が green（fmt/validate/plan）
- [ ] long-lived AWS Access Key を repo に置いていない
- 証跡:
  - docs/verify-ci-plan.txt（成功ログ抜粋）

### 3.4 API（list/add）が CloudFront 経由（同一ドメイン）で検証できる
- [ ] GET  /api/items が成功（200 + JSON）
- [ ] POST /api/items が成功
- [ ] POST 後に GET で反映される
- 証跡:
  - docs/verify-api-curl.txt（GET/POST の出力）
メモ
- v1 の API は HTTP API（apigatewayv2）
- 入口は CloudFront（/api/* → API）

### 3.5 監視（Logs + Alarm 最小 1つ）
- [ ] CloudWatch Logs が見える
- [ ] 尖った Alarm を 1 つ以上（例: Lambda Errors / API 5XX）
- 証跡:
  - docs/verify-alarm.txt（確認ログ）
  - （同ファイル末尾に 10 行以内の対応メモも一緒に貼る）

### 3.6 destroy 後に主要リソースの残骸がない
- [ ] terraform destroy が成功（エラー無し）
- [ ] 残るべきものは bootstrap/ci のみ
- 証跡:
  - docs/verify-destroy.txt（destroy 出力抜粋）

## 4. 追加メモ（任意）
- 詰まった点 / 回避策:
- 取捨選択の理由（短く）:
