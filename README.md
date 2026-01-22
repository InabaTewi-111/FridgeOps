# FridgeOps（FridgeBox）

冷蔵庫の食材を管理する、シンプルなメモアプリ（兼ポートフォリオ）。
アプリ側は最低限。主に AWS 側（設計 / IaC / 運用 / セキュリティ / コスト）を整理するための箱。

## Demo
- CloudFront: TBD
- API: TBD

## 何ができる（最小）
- list：登録済みの食材を一覧で返す
- add：食材を1件追加する

## 構成
- static：CloudFront →（OAC）→ S3（private）
- api：API Gateway → Lambda → DynamoDB

ポイント：
- S3 は private のまま。CloudFront 経由以外は通さない。
- CI は GitHub Actions + OIDC。Access Key は repo に置かない。

## 検証できる状態（DoD）
- CloudFront で表示できる
- S3 直アクセスは 403（CloudFront 経由のみ）
- GitHub Actions の OIDC で Terraform plan が通る（Key なし）
- API（list/add）が curl で動く
- CloudWatch Logs が見える + 最小 Alarm 1個
- destroy 後に主要リソースの残骸がない

## Repo
- infra/bootstrap/ : remote state + lock（初回だけ）
- infra/main/      : 本体インフラ（CloudFront/S3/API/Lambda/DDB）
- docs/            : 設計メモ・判断理由・運用メモ
  - adr/           : ADR（判断ログ）
- workload/
  - static/        : 静的フロント（1ページ）
  - api/           : Lambda（最小）

## 手順（ローカル）
1) bootstrap（初回だけ）
- cd infra/bootstrap
- terraform init
- terraform apply

2) main
- cd infra/main
- terraform init
- terraform apply

3) 出力を README の Demo に貼る

destroy は逆順（main → bootstrap）。

## CI（GitHub Actions）
- OIDC で plan を回す（Access Key は使わない）
- 最低限：fmt / validate / plan

## Docs（順に増やす）
- docs/architecture.md : 流れと理由（短く）
- docs/security.md     : OAC / IAM 最小権限
- docs/cost.md         : 概算と注意点
- docs/operations.md   : ログ / 監視 / 何か起きたとき
- docs/adr/ADR-000.md  : 最初の判断ログ

## メモ
- 多ユーザー化や凝った機能は後回し。今は「建てて壊せる」と「安全デフォルト」を優先。
