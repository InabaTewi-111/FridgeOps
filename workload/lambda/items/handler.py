import base64
import json
import logging
import os
import time
import uuid
from decimal import Decimal
from typing import Any, Dict, Optional, Tuple

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.getenv("ITEMS_TABLE_NAME")
if not TABLE_NAME:
    raise RuntimeError("Missing env var: ITEMS_TABLE_NAME")

ddb = boto3.resource("dynamodb")
table = ddb.Table(TABLE_NAME)


def _to_jsonable(x: Any) -> Any:
    """Convert DynamoDB Decimal / nested types to JSON-safe values."""
    if isinstance(x, Decimal):
        if x % 1 == 0:
            return int(x)
        return float(x)
    if isinstance(x, dict):
        return {k: _to_jsonable(v) for k, v in x.items()}
    if isinstance(x, list):
        return [_to_jsonable(v) for v in x]
    return x


def _to_ddb_safe(x: Any) -> Any:
    """
    Convert Python values to DynamoDB-safe values.
    - float -> Decimal(str(float))
    - recursively process dict/list
    """
    if isinstance(x, float):
        return Decimal(str(x))
    if isinstance(x, dict):
        return {k: _to_ddb_safe(v) for k, v in x.items()}
    if isinstance(x, list):
        return [_to_ddb_safe(v) for v in x]
    return x


def _resp(status: int, body: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json; charset=utf-8",
            # demo 用 *；之后同域 /api 再收敛也行
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "content-type",
            "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        },
        "body": json.dumps(body, ensure_ascii=False),
    }


def _method_path(event: Dict[str, Any]) -> Tuple[str, str]:
    """
    Support both API Gateway REST (v1) and HTTP API (v2).
    Return (METHOD, PATH).
    """
    rc = event.get("requestContext", {}) or {}

    # HTTP API v2
    http = rc.get("http")
    if isinstance(http, dict):
        method = (http.get("method") or "").upper()
        path = event.get("rawPath") or event.get("path") or ""
        return method, path

    # REST API v1
    method = (event.get("httpMethod") or "").upper()
    path = event.get("path") or ""
    return method, path


def _normalize_path(path: str) -> str:
    # make "/items/" behave like "/items"
    if path != "/" and path.endswith("/"):
        path = path.rstrip("/")
    return path


def _parse_json_body(event: Dict[str, Any]) -> Dict[str, Any]:
    body = event.get("body")
    if body is None or body == "":
        return {}

    if event.get("isBase64Encoded"):
        if not isinstance(body, str):
            raise ValueError("base64 body must be a string")
        body = base64.b64decode(body).decode("utf-8")

    if isinstance(body, str):
        return json.loads(body)
    if isinstance(body, dict):
        return body
    raise ValueError("invalid body type")


def _qs(event: Dict[str, Any]) -> Dict[str, str]:
    q = event.get("queryStringParameters") or {}
    # sometimes API GW sends None
    return {k: v for k, v in q.items() if v is not None}


def _encode_cursor(last_evaluated_key: Dict[str, Any]) -> str:
    raw = json.dumps(_to_jsonable(last_evaluated_key), ensure_ascii=False).encode("utf-8")
    return base64.urlsafe_b64encode(raw).decode("utf-8").rstrip("=")


def _decode_cursor(cursor: str) -> Dict[str, Any]:
    # add padding back
    pad = "=" * (-len(cursor) % 4)
    raw = base64.urlsafe_b64decode((cursor + pad).encode("utf-8")).decode("utf-8")
    obj = json.loads(raw)
    if not isinstance(obj, dict):
        raise ValueError("cursor must decode to an object")
    # DynamoDB key values should be scalar types; keep as-is
    return obj


def handler(event, context):
    method, path = _method_path(event)
    path = _normalize_path(path)
    logger.info("request: method=%s path=%s", method, path)

    # preflight
    if method == "OPTIONS":
        return _resp(200, {"ok": True})

    # ---- GET /items : list ----
    if method == "GET" and path.endswith("/items"):
        q = _qs(event)
        limit = 50
        if "limit" in q:
            try:
                limit = max(1, min(100, int(q["limit"])))
            except Exception:
                return _resp(400, {"error": "limit must be an integer (1..100)"})

        scan_args: Dict[str, Any] = {"Limit": limit}

        if "cursor" in q and q["cursor"]:
            try:
                scan_args["ExclusiveStartKey"] = _decode_cursor(q["cursor"])
            except Exception as e:
                return _resp(400, {"error": f"invalid cursor: {str(e)}"})

        resp = table.scan(**scan_args)

        items = _to_jsonable(resp.get("Items", []))
        lek = resp.get("LastEvaluatedKey")
        out: Dict[str, Any] = {"items": items, "count": len(items)}
        if lek:
            out["next_cursor"] = _encode_cursor(lek)

        return _resp(200, out)

    # ---- POST /items : add ----
    if method == "POST" and path.endswith("/items"):
        try:
            payload = _parse_json_body(event)
        except Exception as e:
            return _resp(400, {"error": f"invalid_json: {str(e)}"})

        name = (payload.get("name") or "").strip()
        if not name:
            return _resp(400, {"error": "name is required"})

        # expiresAt: epoch seconds (int) if provided
        expires_at = payload.get("expiresAt")
        if expires_at is not None:
            try:
                # allow numeric string
                expires_at = int(expires_at)
            except Exception:
                return _resp(400, {"error": "expiresAt must be an integer (epoch seconds)"})

        item_id = str(uuid.uuid4())
        now = int(time.time())

        item: Dict[str, Any] = {
            "id": item_id,
            "name": name,
            "createdAt": now,
        }

        if "quantity" in payload:
            item["quantity"] = payload["quantity"]
        if "unit" in payload:
            item["unit"] = payload["unit"]
        if expires_at is not None:
            item["expiresAt"] = expires_at

        # make DynamoDB serializer happy (floats -> Decimal)
        item = _to_ddb_safe(item)

        table.put_item(Item=item)
        return _resp(201, {"id": item_id})

    return _resp(404, {"error": "not_found"})
