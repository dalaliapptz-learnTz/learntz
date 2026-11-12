"""Unit tests for the admin provisioning CLI tool."""

from __future__ import annotations

import unittest
from unittest.mock import MagicMock, patch

from scripts.provision_admin import (
    COUNTRY_SCOPED_ROLES,
    VALID_ROLES,
    ProvisioningError,
    SupabaseAdminClient,
    build_parser,
    main,
)


class TestProvisionAdminParser(unittest.TestCase):
    def setUp(self) -> None:
        self.parser = build_parser()

    def test_default_action_is_assign(self) -> None:
        args = self.parser.parse_args(["--email", "test@example.com", "--role", "super_admin"])
        self.assertEqual(args.action, "assign")
        self.assertEqual(args.role, "super_admin")
        self.assertEqual(args.email, "test@example.com")

    def test_invalid_role_rejected(self) -> None:
        with self.assertRaises(SystemExit):
            self.parser.parse_args(["--role", "invalid_role"])

    def test_country_scoped_roles_defined(self) -> None:
        for role in COUNTRY_SCOPED_ROLES:
            self.assertIn(role, VALID_ROLES)


class TestProvisionAdminExecution(unittest.TestCase):
    @patch.dict("os.environ", {"SUPABASE_URL": "http://127.0.0.1:54321", "SUPABASE_SERVICE_ROLE_KEY": "test-key"})
    @patch.object(SupabaseAdminClient, "assign_role")
    @patch.object(SupabaseAdminClient, "find_user_id_by_email")
    def test_assign_super_admin_success(self, mock_find: MagicMock, mock_assign: MagicMock) -> None:
        mock_find.return_value = "00000000-0000-0000-0000-000000000001"
        mock_assign.return_value = {"id": "role-1", "role": "super_admin"}

        exit_code = main(["--email", "admin@example.com", "--role", "super_admin"])

        self.assertEqual(exit_code, 0)
        mock_find.assert_called_once_with("admin@example.com")
        mock_assign.assert_called_once_with("00000000-0000-0000-0000-000000000001", "super_admin", None)

    @patch.dict("os.environ", {"SUPABASE_URL": "http://127.0.0.1:54321", "SUPABASE_SERVICE_ROLE_KEY": "test-key"})
    @patch.object(SupabaseAdminClient, "assign_role")
    @patch.object(SupabaseAdminClient, "find_user_id_by_email")
    def test_assign_country_admin_requires_country(self, mock_find: MagicMock, mock_assign: MagicMock) -> None:
        mock_find.return_value = "00000000-0000-0000-0000-000000000001"

        exit_code = main(["--email", "editor@example.com", "--role", "curriculum_editor"])
        self.assertEqual(exit_code, 1)
        mock_assign.assert_not_called()

    @patch.dict("os.environ", {"SUPABASE_URL": "http://127.0.0.1:54321", "SUPABASE_SERVICE_ROLE_KEY": "test-key"})
    @patch.object(SupabaseAdminClient, "assign_role")
    @patch.object(SupabaseAdminClient, "find_user_id_by_email")
    def test_assign_country_admin_with_country_success(self, mock_find: MagicMock, mock_assign: MagicMock) -> None:
        mock_find.return_value = "00000000-0000-0000-0000-000000000001"
        mock_assign.return_value = {"id": "role-2", "role": "curriculum_editor", "country_code": "TZ"}

        exit_code = main(["--email", "editor@example.com", "--role", "curriculum_editor", "--country", "TZ"])
        self.assertEqual(exit_code, 0)
        mock_assign.assert_called_once_with("00000000-0000-0000-0000-000000000001", "curriculum_editor", "TZ")


if __name__ == "__main__":
    unittest.main()
