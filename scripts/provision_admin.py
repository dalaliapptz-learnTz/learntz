#!/usr/bin/env python3
"""LearnTZ Administrative Provisioning CLI

Allows authorized database operators to safely assign, revoke, and inspect
user roles (such as super_admin, country_admin, curriculum_admin) using
the Supabase service-role credential.

Usage:
  python3 scripts/provision_admin.py --email admin@learntz.com --role super_admin
  python3 scripts/provision_admin.py --email editor@learntz.com --role curriculum_editor --country TZ
  python3 scripts/provision_admin.py --action list --email admin@learntz.com
  python3 scripts/provision_admin.py --action revoke --email old@learntz.com --role super_admin
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any


VALID_ROLES = (
    "super_admin",
    "country_admin",
    "content_admin",
    "finance_admin",
    "support_admin",
    "parent",
    "learner",
    "curriculum_editor",
    "curriculum_reviewer",
    "curriculum_approver",
    "curriculum_admin",
)

COUNTRY_SCOPED_ROLES = (
    "country_admin",
    "curriculum_editor",
    "curriculum_reviewer",
    "curriculum_approver",
    "curriculum_admin",
)


class ProvisioningError(Exception):
    """Raised for operational or validation failures."""


class SupabaseAdminClient:
    def __init__(self, base_url: str, service_role_key: str) -> None:
        if not base_url:
            raise ProvisioningError("SUPABASE_URL is required (pass --url or set SUPABASE_URL).")
        if not service_role_key:
            raise ProvisioningError(
                "SUPABASE_SERVICE_ROLE_KEY is required (pass --key or set SUPABASE_SERVICE_ROLE_KEY)."
            )
        self.base_url = base_url.rstrip("/")
        self.service_role_key = service_role_key

    def _request(
        self,
        endpoint: str,
        *,
        method: str = "GET",
        data: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> Any:
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        req_headers = {
            "apikey": self.service_role_key,
            "Authorization": f"Bearer {self.service_role_key}",
            "Content-Type": "application/json",
        }
        if headers:
            req_headers.update(headers)

        payload_bytes = json.dumps(data).encode("utf-8") if data is not None else None
        req = urllib.request.Request(url, data=payload_bytes, headers=req_headers, method=method)

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                body = resp.read().decode("utf-8")
                return json.loads(body) if body.strip() else None
        except urllib.error.HTTPError as error:
            error_body = error.read().decode("utf-8")
            try:
                parsed = json.loads(error_body)
                msg = parsed.get("message") or parsed.get("msg") or parsed.get("error") or error_body
            except Exception:
                msg = error_body
            raise ProvisioningError(f"API Error ({error.code}): {msg}") from error
        except urllib.error.URLError as error:
            raise ProvisioningError(f"Connection failed: {error.reason}") from error

    def find_user_id_by_email(self, email: str) -> str:
        """Finds auth user UUID by email address using the Admin Auth API."""
        encoded_email = urllib.parse.quote(email.strip().lower())
        response = self._request(f"auth/v1/admin/users?email={encoded_email}")
        users = response.get("users", []) if isinstance(response, dict) else []
        matching = [u for u in users if u.get("email", "").lower() == email.strip().lower()]
        if not matching:
            raise ProvisioningError(f"No auth user found with email: {email}")
        return matching[0]["id"]

    def assign_role(self, user_id: str, role: str, country_code: str | None = None) -> dict[str, Any]:
        """Calls RPC assign_user_role."""
        return self._request(
            "rest/v1/rpc/assign_user_role",
            method="POST",
            data={
                "p_user_id": user_id,
                "p_role": role,
                "p_country_code": country_code.upper() if country_code else None,
            },
        )

    def revoke_role(self, user_id: str, role: str, country_code: str | None = None) -> bool:
        """Calls RPC revoke_user_role."""
        return bool(
            self._request(
                "rest/v1/rpc/revoke_user_role",
                method="POST",
                data={
                    "p_user_id": user_id,
                    "p_role": role,
                    "p_country_code": country_code.upper() if country_code else None,
                },
            )
        )

    def list_roles(self, user_id: str | None = None) -> list[dict[str, Any]]:
        """Queries public.user_roles."""
        endpoint = "rest/v1/user_roles?select=id,user_id,role,country_code,created_at"
        if user_id:
            endpoint += f"&user_id=eq.{user_id}"
        return self._request(endpoint) or []


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="LearnTZ Operator Admin Provisioning CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--action",
        choices=["assign", "revoke", "list"],
        default="assign",
        help="Action to perform (default: assign)",
    )
    parser.add_argument("--email", help="Target user's email address")
    parser.add_argument("--user-id", help="Target user's UUID (alternative to email)")
    parser.add_argument(
        "--role",
        choices=VALID_ROLES,
        help="Role to assign or revoke",
    )
    parser.add_argument(
        "--country",
        help="2-letter ISO country code (e.g. TZ, KE). Required for country-scoped roles.",
    )
    parser.add_argument(
        "--url",
        default=os.environ.get("SUPABASE_URL", "http://127.0.0.1:54321"),
        help="Supabase Project API URL (default: SUPABASE_URL or http://127.0.0.1:54321)",
    )
    parser.add_argument(
        "--key",
        default=os.environ.get("SUPABASE_SERVICE_ROLE_KEY", ""),
        help="Supabase Service Role Key (default: SUPABASE_SERVICE_ROLE_KEY)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        client = SupabaseAdminClient(args.url, args.key)

        user_id = args.user_id
        if not user_id and args.email:
            user_id = client.find_user_id_by_email(args.email)
        elif not user_id and args.action != "list":
            raise ProvisioningError("Either --email or --user-id is required.")

        if args.action == "list":
            assignments = client.list_roles(user_id)
            if not assignments:
                print(f"No role assignments found{' for user ' + user_id if user_id else ''}.")
            else:
                print(f"Found {len(assignments)} role assignment(s):")
                print("-" * 70)
                print(f"{'USER ID':<38} {'ROLE':<22} {'COUNTRY'}")
                print("-" * 70)
                for item in assignments:
                    print(
                        f"{item.get('user_id', ''):<38} "
                        f"{item.get('role', ''):<22} "
                        f"{item.get('country_code') or '(global)'}"
                    )
            return 0

        if not args.role:
            raise ProvisioningError("--role is required for assign and revoke actions.")

        if args.role in COUNTRY_SCOPED_ROLES and not args.country:
            raise ProvisioningError(f"Role '{args.role}' requires a country code (e.g. --country TZ).")

        if args.action == "assign":
            result = client.assign_role(user_id, args.role, args.country)
            country_display = args.country.upper() if args.country else "global"
            print(
                f"✅ Successfully assigned role '{args.role}' ({country_display}) "
                f"to user {args.email or user_id}."
            )
            return 0

        if args.action == "revoke":
            success = client.revoke_role(user_id, args.role, args.country)
            if success:
                print(f"✅ Successfully revoked role '{args.role}' from user {args.email or user_id}.")
            else:
                print(f"ℹ️ No matching assignment found for role '{args.role}' on user {args.email or user_id}.")
            return 0

        raise ProvisioningError(f"Unknown action: {args.action}")

    except ProvisioningError as err:
        print(f"❌ Error: {err}", file=sys.stderr)
        return 1
    except Exception as err:
        print(f"💥 Unexpected Error: {err}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
