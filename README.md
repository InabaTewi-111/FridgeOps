# FridgeOps (FridgeBox)

冷蔵庫の食材を管理する、シンプルなメモアプリ（兼ポートフォリオ）。

A simple fridge item memo app (portfolio project).

## MVP
- 食材を手入力で登録する：`name`, `storedAt`, `keepDays`
- 期限日 `expiresAt` はバックエンドで計算する（`storedAt + keepDays`）
- 一覧で残日数を表示し、期限が近い/期限切れは強調表示する
- （任意）GPT API で `keepDays` の目安を提案する（手動で上書き可）

## Fields
- `itemId`
- `name`
- `storedAt` (YYYY-MM-DD)
- `keepDays` (number)
- `expiresAt` (computed)
- `createdAt`

## Notes
- API Key などの秘密情報はコミットしない（`.env` を使用、`.gitignore` に含める）
