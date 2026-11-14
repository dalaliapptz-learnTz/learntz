-- LearnTZ Supabase Seed Data
-- Super Admin user: superadmin@learntz.com / SuperAdmin1234!
DO $$
DECLARE
  superadmin_id uuid := '41155a55-38b3-4a3f-8c71-985d572de597';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = superadmin_id) THEN
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      invited_at,
      confirmation_token,
      confirmation_sent_at,
      recovery_token,
      recovery_sent_at,
      email_change_token_new,
      email_change,
      email_change_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      created_at,
      updated_at,
      phone,
      phone_confirmed_at,
      phone_change,
      phone_change_token,
      phone_change_sent_at,
      email_change_token_current,
      email_change_confirm_status,
      banned_until,
      reauthentication_token,
      reauthentication_sent_at,
      is_sso_user,
      deleted_at,
      is_anonymous
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      superadmin_id,
      'authenticated',
      'authenticated',
      'superadmin@learntz.com',
      -- 'SuperAdmin1234!' hashed with bcrypt
      '$2a$06$R4GAxt53vx6W.D95UgDvDeTLJuEznbhFH1ggroEqWBa2syR/WuXjS',
      now(),
      null,
      '',
      null,
      '',
      null,
      '',
      '',
      null,
      now(),
      '{"provider": "email", "providers": ["email"]}'::jsonb,
      '{"full_name": "System Super Admin"}'::jsonb,
      false,
      now(),
      now(),
      null,
      null,
      '',
      '',
      null,
      '',
      0,
      null,
      '',
      null,
      false,
      null,
      false
    );
  ELSE
    UPDATE auth.users
    SET
      confirmation_token = '',
      recovery_token = '',
      email_change_token_new = '',
      email_change = '',
      phone_change = '',
      phone_change_token = '',
      email_change_token_current = '',
      reauthentication_token = ''
    WHERE id = superadmin_id;
  END IF;

  INSERT INTO auth.identities (
    id,
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    superadmin_id,
    superadmin_id::text,
    superadmin_id,
    jsonb_build_object(
      'sub', superadmin_id::text,
      'email', 'superadmin@learntz.com',
      'email_verified', true,
      'phone_verified', false
    ),
    'email',
    now(),
    now(),
    now()
  ) ON CONFLICT (provider_id, provider) DO UPDATE SET
    identity_data = EXCLUDED.identity_data,
    updated_at = now();

  INSERT INTO public.user_roles (user_id, role)
  VALUES (superadmin_id, 'super_admin')
  ON CONFLICT (user_id, role, coalesce(country_code, '')) DO NOTHING;

END $$;
