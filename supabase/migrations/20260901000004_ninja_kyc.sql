-- ====================================================================
-- RYZON CONVERT SUPABASE DATABASE SCHEMA
-- Migration: 20260901000004_ninja_kyc.sql
-- Description: Ninja Hosted KYC tracking, verification links, and webhook deduplication
-- ====================================================================

-- 1. ADD KYC COLUMNS TO PROFILES
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS kyc_status TEXT DEFAULT 'unverified' 
CHECK (kyc_status IN ('unverified', 'pending', 'verified', 'review', 'failed', 'rejected_underage')),
ADD COLUMN IF NOT EXISTS kyc_verification_id TEXT,
ADD COLUMN IF NOT EXISTS kyc_score NUMERIC(5, 2),
ADD COLUMN IF NOT EXISTS kyc_verified_at TIMESTAMP WITH TIME ZONE;

-- 2. CREATE KYC SUBMISSIONS AUDIT TABLE
CREATE TABLE IF NOT EXISTS public.kyc_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    link_id TEXT UNIQUE,
    hosted_url TEXT,
    verification_id TEXT,
    outcome TEXT,
    score NUMERIC(5, 2),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'review', 'failed', 'rejected_underage')),
    raw_provider_response JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.kyc_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own KYC submissions"
    ON public.kyc_submissions FOR SELECT
    USING (auth.uid() = user_id);

-- 3. WEBHOOK DEDUPLICATION TABLE
CREATE TABLE IF NOT EXISTS public.webhook_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id TEXT UNIQUE NOT NULL,
    provider TEXT NOT NULL DEFAULT 'NINJA',
    received_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_kyc_submissions_user_id ON public.kyc_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_webhook_events_event_id ON public.webhook_events(event_id);
