# ADR-000: アーキテクチャ意思決定（FridgeOps）

- Status: Accepted
- Date: 2026-01-22

## 背景
本リポジトリはポートフォリオ用途であり、アプリ機能は最小構成とする。
一方で、以下を実装とドキュメントで示すことを目的とする。
- secure-by-default な静的配信（CloudFront + OAC + Private S3）
- GitHub Actions + OIDC による CI（長期 AWS Key を保持しない）
- API（API Gateway + Lambda + DynamoDB）による最小の E2E
- 監視（CloudWatch）およびコスト抑制の方針

## 決定事項

### D1. 静的配信は CloudFront + OAC + Private S3 とする
S3 バケットは公開しない。CloudFront のみが OAC 経由でオリジンにアクセスできる構成とする。

理由:
- 公開バケットや S3 直アクセス経路を避けられるため
- オリジンへのアクセス制御を明確にできるため
- OAC を利用した構成は現行の推奨に沿うため

### D2. CloudFront の Behavior で `/api/*` を API Gateway に転送する
CloudFront を入口として固定し、`/api/*` は API Gateway にルーティングする。

理由:
- フロントエンドから同一ドメインで API を呼び出せるため（CORS の分断を避ける）
- 静的配信と API を CloudFront の設定で分離できるため

### D3. Lambda は原則 VPC にアタッチしない（v1）
v1 では Lambda を VPC に入れない。必要になった場合のみ設計理由と egress 方針を明文化する。

理由:
- NAT Gateway を前提としたコスト/運用を避けるため
- 最小構成で E2E を成立させることを優先するため

### D4. OpenAI API Key は Secrets Manager（または SSM）に格納し、実行時に取得する
秘密情報はリポジトリ、CI、フロントエンドに保持しない。

理由:
- 秘密情報の漏えいリスクを下げるため
- 実運用に近い取り扱い方針を示すため

### D5. 認証は v1 では実装しない（単一ユーザーのデモ）
v1 では Cognito 等は導入しない。将来拡張の方針のみ記載する。

理由:
- 作品集の主目的（インフラ/IaC/運用/セキュリティ/コスト）に集中するため

## 影響
- 入口が CloudFront に集約され、配信・ルーティング・オリジン制御が一元化される。
- API 側はスロットリング等の制限設計が重要となる。
- 将来的に multi-user 化する場合は、認証導入とデータ分離設計が必要となる。

## 後続対応（別 ADR/別 doc で扱う）
- API のスロットリング/制限（Usage Plan 等）の具体化
- CloudWatch Alarm と簡易 runbook の整備
- 認証導入時の候補（Cognito / JWT Authorizer 等）の整理
