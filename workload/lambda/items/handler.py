import json
import os
import time
import uuid
from decimal import Decimal

import boto3

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ.get("ITEMS_TABLE_NAME")


def _json_default(o):
    # DynamoDB uses Decimal for numbers. Convert to int if possible, else float.
    if isinstance(o, Decimal):
        try:
            if o % 1 == 0:
                return int(o)
        except Exception:
            pass
        return float(o)
    # Fallback: stringify unknown types
    return str(o)


def _cors_headers():
    return {
        "content-type": "application/json; charset=utf-8",
        "access-control-allow-origin": "*",
        "access-control-allow-methods": "GET,POST,DELETE,OPTIONS",
        "access-control-allow-headers": "content-type",
    }


def _resp(status: int, body=None):
    if body is None:
        body = {}
    return {
        "statusCode": status,
        "headers": _cors_headers(),
        "body": json.dumps(body, ensure_ascii=False, default=_json_default),
    }


def _resp_no_body(status: int):
    # for 204 etc.
    return {"statusCode": status, "headers": _cors_headers(), "body": ""}


def _table():
    if not TABLE_NAME:
        return None
    return dynamodb.Table(TABLE_NAME)


def _method(event):
    return (event.get("requestContext", {}).get("http", {}).get("method") or "").upper()


def _path(event):
    # HTTP API v2: rawPath is reliable
    return event.get("rawPath") or ""


def handler(event, context):
    table = _table()
    if not table:
        return _resp(
            500,
            {
                "error": "missing_table_env",
                "hint": "Set Lambda env var ITEMS_TABLE_NAME to DynamoDB table name",
            },
        )

    method = _method(event)
    path = _path(event)

    # CORS preflight
    if method == "OPTIONS":
        return _resp_no_body(204)

    # GET /items
    if method == "GET" and path == "/items":
        r = table.scan()
        items = r.get("Items", [])
        # sort: newest first when createdAt exists
        try:
            items.sort(key=lambda x: x.get("createdAt", 0), reverse=True)
        except Exception:
            pass
        return _resp(200, {"items": items})

    # POST /items
    if method == "POST" and path == "/items":
        try:
            payload = json.loads(event.get("body") or "{}")
        except Exception:
            return _resp(400, {"error": "invalid_json"})

        name = (payload.get("name") or "").strip()
        purchase_date = (payload.get("purchaseDate") or "").strip()

        if not name:
            return _resp(400, {"error": "missing_name"})

        item = {
            "id": str(uuid.uuid4()),
            "name": name,
            "createdAt": int(time.time()),
        }
        if purchase_date:
            item["purchaseDate"] = purchase_date

        table.put_item(Item=item)
        return _resp(200, item)

    # DELETE /items/{id}
    if method == "DELETE" and path.startswith("/items/"):
        item_id = path.split("/items/", 1)[1].strip()
        if not item_id:
            return _resp(400, {"error": "missing_id"})

        table.delete_item(Key={"id": item_id})
        # 204 is typical for delete success
        return _resp_no_body(204)

    return _resp(404, {"error": "not_found"})

