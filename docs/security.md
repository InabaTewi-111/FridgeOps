# セキュリティ設計（Security）

本作品（FridgeOps/FridgeBox）は「クラウド構築 + 運用」を示すポートフォリオです。
ここでは、現時点のセキュリティ既定値（デフォルト）と設計上の取捨選択を簡潔に記録します。

---

## 1. 前提（Threat Model / Assumptions）
- 個人ポートフォリオ用途。まずは「デフォルトで安全」かつ「説明可能な取捨選択」を優先。
- 入口は CloudFront に集約。S3 は private な Origin として使用（直アクセス不可）。
- 単一ユーザーのデモを想定。認証（Cognito 等）は現段階では必須要件にしない（拡張パスは docs に記載）。

---

## 2. 主要コントロール（What we enforce）

### 2.1 S3：private + 公開事故防止
- S3 Bucket は **private** を維持。
- **Block Public Access** を有効化し、Public ACL/Policy による公開事故を防止。

### 2.2 CloudFront OAC：S3 直アクセスの遮断（入口統一）
- CloudFront は **OAC（Origin Access Control）** を使用して S3 にアクセス。
- Bucket Policy は「特定の CloudFront Distribution からのリクエストのみ許可」という方針で構成。
- これにより、S3 への直アクセス（バイパス）を遮断し、入口を CloudFront に統一。

**証跡**
- `docs/verify-s3-direct-403.txt`：S3 直アクセスが 403 になることを確認したログ。

### 2.3 通信（TLS）
- CloudFront 側で HTTPS を前提とし、（必要に応じて）HTTP→HTTPS リダイレクトを適用。
- TLS 設定は “安全な既定値” を採用（詳細は実装側の設定に準拠）。

---

## 3. シークレット（Secrets）
- API キー等の機密情報は **repo に入れない／フロントに配布しない／コードに埋め込まない**。
- 格納先は AWS Secrets Manager または SSM Parameter Store を想定し、Lambda 実行時に取得（拡張要件として扱う）。

---

## 4. CI/CD（Credential Hygiene）
- GitHub Actions は **OIDC** を使い、長期的な AWS Access Key を保持しない。
- Terraform は少なくとも `fmt / validate / plan` を CI で自動化（Day7-8 で実装）。

---

## 5. 監視・運用（Observability）
- CloudWatch Logs を基礎とし、Logs retention を設定。
- “尖った” アラーム（例：Lambda Errors / Throttles、API 5XX）を 1 つ以上作成。
- 10 行以内の簡易 Runbook を用意（Day13 で実装）。

---

## 6. 取捨選択と拡張パス
- 現段階では認証（Cognito 等）を必須にしない：単一ユーザーのデモとして複雑性/コストを抑えるため。
- 将来拡張：Cognito（JWT Authorizer）、WAF、セキュリティヘッダー、GuardDuty 等は段階的に追加可能。
