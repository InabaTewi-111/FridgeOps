# 最終検証チェックリスト（Day14）

> 目的：apply → 検証 → destroy を「再現可能な手順」と「証跡」で残す。  
> ルール：チェックは「実行ログ or コマンド出力 or 画面キャプチャ」を必ず添付（docs/verify-*.txt）。

---

## 0. 実行情報（Run Info）
- Date:
- Git commit:
- AWS Region:
- State:
  - infra/bootstrap:（保持）
  - infra/ci:（保持）
  - infra/main:（apply/destroy 対象）

## 1. 重要な出力（Outputs）
- CloudFront Domain:
- CloudFront Distribution ID:
- Static S3 Bucket Name:
- API Endpoint（REST）:
- （任意）CI PlanRole ARN:
- （任意）OIDC Provider ARN:

---

## 2. DoD 検証（必須）

### 2.1 CloudFront で静的ページが表示できる
- [ ] CloudFront の URL にアクセスして 200/HTML が返る
- 証跡：
  - docs/verify-cf-root-200.txt（例：curl -I の結果 or 画面キャプチャ）

### 2.2 S3 直アクセスが 403（バイパス不可 / OAC 有効）
- [ ] S3 オブジェクト直アクセスで 403 が返る（署名無し）
- 証跡：
  - docs/verify-s3-direct-403.txt（既存/再生成）

### 2.3 GitHub Actions（OIDC）で fmt/validate/plan が成功（AWS Key 不使用）
- [ ] Workflow が green（fmt/validate/plan）
- [ ] AWS Access Key を repo に保存していない（Secrets に置かない）
- 証跡：
  - docs/verify-ci-plan.txt（成功ログの抜粋）

### 2.4 API（list/add）が curl で検証できる
- [ ] GET /items が成功し、Contract 通りの JSON を返す
- [ ] POST /items が成功し、追加後に GET で反映される
- 証跡：
  - docs/verify-api-curl.txt（GET/POST の出力）

### 2.5 フロントエンド MVP の可用性（同域 /api、4態）
- [ ] 同域で `/api/items` を呼べる（CloudFront /api/* → API Gateway）
- [ ] list/add が UI から実行できる
- [ ] 状態が最低限揃っている：
  - [ ] Loading（通信中の表示）
  - [ ] Empty（空リストの表示）
  - [ ] Error（失敗時の表示）
  - [ ] Success（追加成功後の反映）
- 証跡：
  - docs/verify-frontend-usable.txt（各状態の確認ログ/キャプチャ）

### 2.6 監視・運用（Logs + Alarm + Runbook）
- [ ] CloudWatch Logs retention を設定
- [ ] 尖った Alarm を 1 つ以上作成（例：Lambda Errors / API 5XX）
- [ ] Runbook（10行以内）を用意
- 証跡：
  - docs/verify-alarm.txt
  - docs/runbook.md

### 2.7 destroy 後に残骸がない（再現可能なクリーンアップ）
- [ ] terraform destroy が成功（エラー無し）
- [ ] 後片付けが完了（残るべきもの：bootstrap/ci のみ）
- 証跡：
  - docs/verify-destroy.txt（destroy 出力の抜粋）

---

## 3. 追加メモ（任意）
- 詰まった点 / 回避策：
- 取捨選択の理由（短く）：
