from __future__ import annotations

import os
from urllib.parse import quote

import httpx


class SupabaseWorkerClient:
    def __init__(self, base_url: str, service_role_key: str) -> None:
        if not base_url.startswith("http://") and not base_url.startswith("https://"):
            raise ValueError("SUPABASE_URL must be an HTTP(S) URL.")
        if not service_role_key:
            raise ValueError("SUPABASE_SERVICE_ROLE_KEY is required.")
        self._base_url = base_url.rstrip("/")
        self._headers = {
            "apikey": service_role_key,
            "Authorization": f"Bearer {service_role_key}",
        }
        self._client = httpx.Client(timeout=httpx.Timeout(120, connect=10))

    @classmethod
    def from_environment(cls) -> SupabaseWorkerClient:
        return cls(
            os.environ.get("SUPABASE_URL", ""),
            os.environ.get("SUPABASE_SERVICE_ROLE_KEY", ""),
        )

    def claim(self) -> dict | None:
        response = self._client.post(
            f"{self._base_url}/rest/v1/rpc/claim_curriculum_import_job",
            headers=self._headers,
            json={},
        )
        response.raise_for_status()
        return response.json()

    def download(self, bucket: str, path: str) -> bytes:
        encoded_path = quote(path, safe="/")
        response = self._client.get(
            f"{self._base_url}/storage/v1/object/{quote(bucket, safe='')}/{encoded_path}",
            headers=self._headers,
        )
        response.raise_for_status()
        return response.content

    def complete(self, job_id: str, pages: list[dict], metadata: dict) -> None:
        response = self._client.post(
            f"{self._base_url}/rest/v1/rpc/complete_curriculum_import",
            headers=self._headers,
            json={"p_job_id": job_id, "p_pages": pages, "p_metadata": metadata},
        )
        response.raise_for_status()

    def renew_lease(self, job_id: str) -> None:
        response = self._client.post(
            f"{self._base_url}/rest/v1/rpc/renew_curriculum_import_lease",
            headers=self._headers,
            json={"p_job_id": job_id},
        )
        response.raise_for_status()

    def fail(
        self,
        job_id: str,
        message: str,
        error_code: str,
        *,
        retryable: bool,
        page_number: int | None = None,
    ) -> None:
        response = self._client.post(
            f"{self._base_url}/rest/v1/rpc/fail_curriculum_import",
            headers=self._headers,
            json={
                "p_job_id": job_id,
                "p_error": message[:1000],
                "p_error_code": error_code,
                "p_retryable": retryable,
                "p_page_number": page_number,
                "p_details": {},
            },
        )
        response.raise_for_status()

    def close(self) -> None:
        self._client.close()
