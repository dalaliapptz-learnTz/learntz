-- ============================================================================
-- LearnTZ Design System 2.0 Brand Colors Synchronization
-- Canonical Tokens: Deep Academic Blue (#0F4C81) and Savannah Green (#15803D)
-- ============================================================================

update public.countries
set
  primary_brand_color = 4279192705, -- 0xFF0F4C81 (Deep Academic Blue)
  accent_brand_color = 4279599165,  -- 0xFF15803D (Savannah Green)
  updated_at = now();
