# ADR-0001: API を REST にする（旧案）

- Status: Superseded
- Date: 2026-02-05
- Superseded-By: ADR-0002
- Superseded-Date: 2026-02-06

## Context
MVP の API を REST / HTTP のどちらで作るか決めたかった。合わせて v1 の contract を先に固定して迷子を防ぐ狙い。

## Decision（旧案）
API Gateway は REST API を採用する。

## Options（当時の候補）
- REST API（API Gateway v1）
- HTTP API（API Gateway v2 / apigatewayv2）

## Rationale（メモ）
- 「運用の統制 / cost brake」を語りやすい（Usage Plan / API key / throttling）
- 認証・検証・段階運用の説明の引き出しが多い
- 当時は “安さ” より “コントロール性と説明可能性” を優先した

## Consequences（旧案の影響）
- 構成が多少重くなる可能性はあるが、MVP 範囲では許容の想定
- 以降の実装は REST 前提で進むはずだった

## Why Superseded
現状の IaC は HTTP API（apigatewayv2）で構築されており、v1 では「検収できる E2E」と「実装の一貫性」を最優先する方針に切り替えたため。
API 種別と v1 contract は ADR-0002 で再決定する。