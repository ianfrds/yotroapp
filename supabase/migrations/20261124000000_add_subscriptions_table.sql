-- ==============================================================================
-- MIGRATION: ADD SUBSCRIPTIONS TABLE FOR RECURRING BILLS & REMINDERS
-- Follows Supabase Postgres Best Practices & Row Level Security (RLS)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  billing_day INTEGER NOT NULL DEFAULT 1,
  cycle TEXT NOT NULL DEFAULT 'monthly', -- 'monthly', 'yearly', 'weekly'
  category_id TEXT NOT NULL DEFAULT '',
  category_name TEXT NOT NULL DEFAULT 'Tagihan & Utilitas',
  wallet_id TEXT NOT NULL DEFAULT '',
  reminder_enabled BOOLEAN NOT NULL DEFAULT true,
  reminder_days_before INTEGER NOT NULL DEFAULT 1,
  last_paid_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);

-- Index for RLS & user_id lookups
CREATE INDEX IF NOT EXISTS subscriptions_user_id_idx ON public.subscriptions (user_id);

-- Auto-update updated_at timestamp
CREATE OR REPLACE TRIGGER set_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Enable Row Level Security (RLS)
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Policies (using cached (SELECT auth.uid()) and explicit TO authenticated)
CREATE POLICY "subscriptions_select_policy" ON public.subscriptions
  FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "subscriptions_insert_policy" ON public.subscriptions
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "subscriptions_update_policy" ON public.subscriptions
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "subscriptions_delete_policy" ON public.subscriptions
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);
