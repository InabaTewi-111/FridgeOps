# FridgeOps アーキテクチャ v1

## 概要

フロントエンドは CloudFront で配信し、OAC 経由で private S3 bucket を Origin として安全に提供する（secure-by-default）。

API は API Gateway（HTTP API / apigatewayv2） + Lambda + DynamoDB で構成する。  
CORS の分断を避けるため、CloudFront の Behavior で `/api/*` を API Gateway に route し、同一ドメインから API を呼べるようにする。

FrontEnd: CloudFront distribution with a private S3 bucket origin via OAC.  
API: CloudFront routes `/api/*` to API Gateway (HTTP API / apigatewayv2), then Lambda reads/writes DynamoDB.  
Scope: v1 is only for verifiable E2E (apply → verify → destroy). v2 features are documented separately.

---

## 構成（v1）

~~~mermaid
flowchart LR
  U["User Browser"] --> CF["CloudFront"]

  CF -->|default| S3["S3 (private bucket)\nstatic assets"]
  CF -->|/api/* behavior| APIGW["API Gateway (HTTP API / apigatewayv2)\nroute: /api/items"]

  APIGW --> L["Lambda items\nGET/POST /api/items"]
  L --> DDB["DynamoDB items"]
  L --> CW["CloudWatch Logs/Metrics\n+ Alarm (min 1)"]

  CF -. SigV4 (OAC) .-> S3
~~~

---

## データフロー（v1 最小）

1. Browser → CloudFront: 静的ページ取得（OAC 経由で S3

