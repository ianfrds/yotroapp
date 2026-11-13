-- ==============================================================================
-- YOTRO FINANCIAL MANAGER — USER ACCOUNT DELETION RPC
-- Deletes the authenticated user from auth.users (cascades to all user data)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  DELETE FROM auth.users WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
