"""
Supabase REST API client (httpx-based).

Uses PostgREST under the hood — no native DB drivers needed,
so this works on Cloudflare Workers Python runtime.
"""
import os
from typing import Any, Optional
import httpx

_TIMEOUT = 10.0  # seconds


class _Table:
    """Chainable query builder for a single Supabase table."""

    def __init__(self, base: str, headers: dict, table: str) -> None:
        self._url = f"{base}/{table}"
        self._h = headers
        self._params: dict[str, Any] = {}

    # ---------- filter helpers ----------
    def eq(self, col: str, val: Any) -> "_Table":
        self._params[col] = f"eq.{val}"
        return self

    def in_(self, col: str, vals: list) -> "_Table":
        self._params[col] = "in.(" + ",".join(str(v) for v in vals) + ")"
        return self

    def not_in(self, col: str, vals: list) -> "_Table":
        self._params[col] = "not.in.(" + ",".join(str(v) for v in vals) + ")"
        return self

    def gte(self, col: str, val: Any) -> "_Table":
        self._params[col] = f"gte.{val}"
        return self

    # ---------- order / pagination ----------
    def order(self, col: str, desc: bool = False) -> "_Table":
        self._params["order"] = f"{col}.{'desc' if desc else 'asc'}"
        return self

    def limit(self, n: int) -> "_Table":
        self._params["limit"] = n
        return self

    def offset(self, n: int) -> "_Table":
        self._params["offset"] = n
        return self

    # ---------- execution ----------
    async def execute(self) -> list[dict]:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as c:
            r = await c.get(self._url, headers=self._h, params=self._params)
            r.raise_for_status()
            return r.json()

    async def insert(self, data: dict) -> dict:
        h = {**self._h, "Prefer": "return=representation"}
        async with httpx.AsyncClient(timeout=_TIMEOUT) as c:
            r = await c.post(self._url, headers=h, json=data)
            r.raise_for_status()
            rows = r.json()
            return rows[0] if rows else {}

    async def update(self, data: dict) -> dict:
        h = {**self._h, "Prefer": "return=representation"}
        async with httpx.AsyncClient(timeout=_TIMEOUT) as c:
            r = await c.patch(self._url, headers=h, params=self._params, json=data)
            r.raise_for_status()
            rows = r.json()
            return rows[0] if rows else {}

    async def delete(self) -> None:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as c:
            r = await c.delete(self._url, headers=self._h, params=self._params)
            r.raise_for_status()


class SupabaseClient:
    def __init__(self) -> None:
        url = os.environ.get("SUPABASE_URL", "").rstrip("/")
        key = os.environ.get("SUPABASE_SERVICE_KEY", "")
        self._base = f"{url}/rest/v1"
        self._h = {
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        }

    def table(self, name: str) -> _Table:
        return _Table(self._base, self._h, name)


_client: Optional[SupabaseClient] = None


def get_db() -> SupabaseClient:
    global _client
    if _client is None:
        _client = SupabaseClient()
    return _client
