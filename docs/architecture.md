# FridgeOps アーキテクチャ v1

## 概要
フロントエンドは CloudFront で配信し、OAC により **プライベート S3 バケット**をオリジンとして安全に提供する（secure-by-default）。  
API は API Gateway + Lambda + DynamoDB で構成する。  
また CloudFront の Behavior で `/api/*` を API Gateway にルーティングし、同一ドメインから API を呼べるようにする（CORS の分断を避ける）。

## 構成図（Mermaid）

```mermaid
flowchart LR
  U[User Browser] --> CF[CloudFront]

  CF -->|OAC| S3[(S3 Private Bucket)\nstatic web]
  CF -->|/api/* behavior| APIGW[API Gateway]

  APIGW --> L[Lambda\n(list/add/suggest)]
  L --> DDB[(DynamoDB)\nitems]
  L --> SM[(Secrets Manager)\nOpenAI API Key]
  L --> CW[CloudWatch Logs/Metrics]

  subgraph Security
    OAC[Origin Access Control]
    IAM[IAM Roles/Policies]
  end

  OAC -. protects .-> S3
  IAM -. grants .-> L

## データフロー（最小）
1. ブラウザ → CloudFront：静的ページ取得（OAC 経由で S3 から配信）
2. ブラウザ → CloudFront `/api/*`：同一ドメインで API 呼び出し
3. CloudFront → API Gateway → Lambda：`/list` `/add` `/suggest` など
4. Lambda → DynamoDB：items の読み書き
5. Lambda → Secrets Manager：OpenAI API Key を実行時取得（repo/フロントに秘密情報を置かない）

## Non-goals（v1 でやらないこと）
- Cognito 等の認証導入（単一ユーザーのデモとして割り切る。拡張パスは ADR に記載）
- Lambda の VPC 内配置（NAT コストを避ける。必要になった時に設計理由と egress を明文化）
- 高度な推薦ロジック（まずは E2E を成立させ、コスト制御と安全な秘密情報管理を優先）
