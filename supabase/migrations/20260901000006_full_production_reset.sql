-- ====================================================================
-- RYZON CONVERT SUPABASE DATABASE SCHEMA
-- Migration: 20260901000006_full_production_reset.sql
-- Description: Clean database reset (0 records) & full production schema consolidation
-- ====================================================================

-- 1. SAFE TRUNCATE ALL AUTH AND PUBLIC TABLES
DO $$ 
BEGIN
    -- Truncate auth users & cascade
    BEGIN
        EXECUTE 'TRUNCATE auth.users CASCADE';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    -- Truncate public tables if they exist
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'webhook_events') THEN
        EXECUTE 'TRUNCATE TABLE public.webhook_events CASCADE';
    END IF;
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'kyc_submissions') THEN
        EXECUTE 'TRUNCATE TABLE public.kyc_submissions CASCADE';
    END IF;
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'transactions') THEN
        EXECUTE 'TRUNCATE TABLE public.transactions CASCADE';
    END IF;
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'crypto_deposit_addresses') THEN
        EXECUTE 'TRUNCATE TABLE public.crypto_deposit_addresses CASCADE';
    END IF;
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_bank_accounts') THEN
        EXECUTE 'TRUNCATE TABLE public.user_bank_accounts CASCADE';
    END IF;
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
        EXECUTE 'TRUNCATE TABLE public.profiles CASCADE';
    END IF;
END $$;

-- 2. ENSURE ALL TABLES EXIST WITH FULL CONSTRAINTS

-- PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    phone_number TEXT,
    pin_hash TEXT,
    settlement_mode TEXT DEFAULT 'AUTO_SETTLEMENT' CHECK (settlement_mode IN ('AUTO_SETTLEMENT', 'MANUAL_BALANCE')),
    wallet_balance_ngn NUMERIC(14, 2) DEFAULT 0.00 CHECK (wallet_balance_ngn >= 0.00),
    kyc_tier INT DEFAULT 0 CHECK (kyc_tier IN (0, 1)),
    kyc_status TEXT DEFAULT 'unverified' CHECK (kyc_status IN ('unverified', 'pending', 'verified', 'review', 'failed', 'rejected_underage')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- WEBHOOK EVENTS DEDUPLICATION TABLE
CREATE TABLE IF NOT EXISTS public.webhook_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id TEXT UNIQUE NOT NULL,
    provider TEXT NOT NULL DEFAULT 'BREET',
    received_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- KYC SUBMISSIONS TABLE
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

-- TRANSACTIONS LEDGER TABLE
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reference TEXT UNIQUE NOT NULL,
    breet_trade_id TEXT UNIQUE,
    type TEXT NOT NULL CHECK (type IN ('DEPOSIT_CONVERT', 'WITHDRAWAL')),
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')),
    crypto_token TEXT NOT NULL CHECK (crypto_token IN ('USDT', 'USDC')),
    crypto_amount NUMERIC(18, 6) NOT NULL DEFAULT 0.000000,
    chain TEXT NOT NULL CHECK (chain IN ('BSC', 'ARBITRUM', 'PLASMA')),
    tx_hash TEXT,
    exchange_rate NUMERIC(12, 2) NOT NULL,
    naira_amount NUMERIC(14, 2) NOT NULL,
    fee_naira NUMERIC(10, 2) DEFAULT 0.00,
    net_naira_payout NUMERIC(14, 2) DEFAULT 0.00,
    settlement_mode TEXT DEFAULT 'AUTO_SETTLEMENT' CHECK (settlement_mode IN ('AUTO_SETTLEMENT', 'MANUAL_BALANCE')),
    payout_bank_code TEXT,
    payout_account_number TEXT,
    payout_reference TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- CRYPTO DEPOSIT ADDRESSES TABLE
CREATE TABLE IF NOT EXISTS public.crypto_deposit_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    chain TEXT NOT NULL CHECK (chain IN ('BSC', 'ARBITRUM', 'PLASMA')),
    token TEXT NOT NULL CHECK (token IN ('USDT', 'USDC')),
    address TEXT UNIQUE NOT NULL,
    breet_asset_id TEXT,
    breet_label TEXT,
    breet_bank_id TEXT,
    breet_account_number TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    CONSTRAINT unique_user_chain_token UNIQUE(user_id, chain, token)
);

-- USER BANK ACCOUNTS TABLE
CREATE TABLE IF NOT EXISTS public.user_bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    bank_name TEXT NOT NULL,
    bank_code TEXT NOT NULL,
    account_number TEXT NOT NULL,
    account_name TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    CONSTRAINT unique_user_bank_account UNIQUE(user_id, bank_code, account_number)
);

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crypto_deposit_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kyc_submissions ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can view their own transactions" ON public.transactions;
CREATE POLICY "Users can view their own transactions" ON public.transactions FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their assigned deposit addresses" ON public.crypto_deposit_addresses;
CREATE POLICY "Users can view their assigned deposit addresses" ON public.crypto_deposit_addresses FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own bank accounts" ON public.user_bank_accounts;
CREATE POLICY "Users can view their own bank accounts" ON public.user_bank_accounts FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own bank accounts" ON public.user_bank_accounts;
CREATE POLICY "Users can insert their own bank accounts" ON public.user_bank_accounts FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own bank accounts" ON public.user_bank_accounts;
CREATE POLICY "Users can delete their own bank accounts" ON public.user_bank_accounts FOR DELETE USING (auth.uid() = user_id);

-- 3. ATOMIC BALANCE MANAGEMENT STORED PROCEDURES
CREATE OR REPLACE FUNCTION public.credit_user_balance(
    p_user_id UUID,
    p_amount NUMERIC(14, 2)
)
RETURNS NUMERIC(14, 2) AS $$
DECLARE
    v_new_balance NUMERIC(14, 2);
BEGIN
    UPDATE public.profiles
    SET wallet_balance_ngn = COALESCE(wallet_balance_ngn, 0.00) + p_amount,
        updated_at = TIMEZONE('utc'::text, NOW())
    WHERE id = p_user_id
    RETURNING wallet_balance_ngn INTO v_new_balance;

    RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.deduct_user_balance(
    p_user_id UUID,
    p_amount NUMERIC(14, 2)
)
RETURNS NUMERIC(14, 2) AS $$
DECLARE
    v_current_balance NUMERIC(14, 2);
    v_new_balance NUMERIC(14, 2);
BEGIN
    SELECT wallet_balance_ngn INTO v_current_balance
    FROM public.profiles
    WHERE id = p_user_id FOR UPDATE;

    IF v_current_balance IS NULL OR v_current_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance. Current balance: ₦%', COALESCE(v_current_balance, 0.00);
    END IF;

    UPDATE public.profiles
    SET wallet_balance_ngn = wallet_balance_ngn - p_amount,
        updated_at = TIMEZONE('utc'::text, NOW())
    WHERE id = p_user_id
    RETURNING wallet_balance_ngn INTO v_new_balance;

    RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RE-CREATE BULLETPROOF PROFILE TRIGGER FOR NEW SIGNUPS
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        email,
        first_name,
        last_name,
        phone_number,
        wallet_balance_ngn,
        kyc_tier,
        kyc_status,
        settlement_mode
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone_number', NEW.phone, ''),
        0.00,
        0,
        'unverified',
        'AUTO_SETTLEMENT'
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        first_name = CASE WHEN EXCLUDED.first_name <> '' THEN EXCLUDED.first_name ELSE public.profiles.first_name END,
        last_name = CASE WHEN EXCLUDED.last_name <> '' THEN EXCLUDED.last_name ELSE public.profiles.last_name END,
        updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    BEGIN
        INSERT INTO public.profiles (id, email)
        VALUES (NEW.id, COALESCE(NEW.email, 'user@ryzon.app'))
        ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ensure trigger is active
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
