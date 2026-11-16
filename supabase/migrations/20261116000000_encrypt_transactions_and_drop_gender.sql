-- ==============================================================================
-- MIGRATION: ENCRYPT TRANSACTIONS AMOUNT AND DROP GENDER FROM PROFILES
-- ==============================================================================

-- 1. Alter amount column in public.transactions to TEXT to allow storing
--    encrypted ciphertext (format: enc:v1:<base64-iv>:<base64-ciphertext>)
ALTER TABLE public.transactions 
  ALTER COLUMN amount TYPE TEXT USING amount::TEXT;

-- 2. Drop obsolete gender column from public.profiles table (UI is 100% gender-free)
ALTER TABLE public.profiles 
  DROP COLUMN IF EXISTS gender;
