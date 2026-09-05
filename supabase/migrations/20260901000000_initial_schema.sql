-- ====================================================================
-- RYZON CONVERT SUPABASE DATABASE SCHEMA
-- Migration: 20260901000000_initial_schema.sql
-- Description: Core tables, RLS policies, indexes, and auth triggers
-- ====================================================================

-- 1. PROFILES TABLE (Extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    phone_number TEXT,
    pin_hash TEXT, -- HMAC-SHA256 hashed 4-digit transaction PIN
    kyc_tier INT DEFAULT 0 CHECK (kyc_tier IN (0, 1)),
    is_kyc_verified BOOLEAN DEFAULT FALSE,
    nin_number TEXT, -- Encrypted/Hashed identity reference
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles RLS Policies
CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);


-- 2. CRYPTO DEPOSIT ADDRESSES TABLE
CREATE TABLE IF NOT EXISTS public.crypto_deposit_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    chain TEXT NOT NULL CHECK (chain IN ('BSC', 'ARBITRUM', 'PLASMA')),
    token TEXT NOT NULL CHECK (token IN ('USDT', 'USDC')),
    address TEXT UNIQUE NOT NULL,
    yellow_card_address_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    CONSTRAINT unique_user_chain_token UNIQUE(user_id, chain, token)
);

ALTER TABLE public.crypto_deposit_addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their assigned deposit addresses"
    ON public.crypto_deposit_addresses FOR SELECT
    USING (auth.uid() = user_id);


-- 3. USER BANK ACCOUNTS TABLE (Withdrawal Destinations)
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

ALTER TABLE public.user_bank_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own bank accounts"
    ON public.user_bank_accounts FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own bank accounts"
    ON public.user_bank_accounts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bank accounts"
    ON public.user_bank_accounts FOR DELETE
    USING (auth.uid() = user_id);


-- 4. TRANSACTIONS LEDGER TABLE (Double-Entry Log)
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reference TEXT UNIQUE NOT NULL, -- e.g. RYZ-DEP-89214 or RYZ-WTH-44910
    type TEXT NOT NULL CHECK (type IN ('DEPOSIT_CONVERT', 'WITHDRAWAL')),
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')),
    crypto_token TEXT NOT NULL CHECK (crypto_token IN ('USDT', 'USDC')),
    crypto_amount NUMERIC(18, 6) NOT NULL DEFAULT 0.000000,
    chain TEXT NOT NULL CHECK (chain IN ('BSC', 'ARBITRUM', 'PLASMA')),
    tx_hash TEXT,
    yellow_card_tx_id TEXT,
    exchange_rate NUMERIC(12, 2) NOT NULL, -- Exact rate applied by Yellow Card
    naira_amount NUMERIC(14, 2) NOT NULL,
    fee_naira NUMERIC(10, 2) DEFAULT 0.00, -- Flat ₦20 fee for withdrawals
    payout_bank_code TEXT,
    payout_account_number TEXT,
    payout_reference TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own transactions"
    ON public.transactions FOR SELECT
    USING (auth.uid() = user_id);


-- 5. AUTOMATIC PROFILE CREATION TRIGGER (On Supabase Auth Signup)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, first_name, last_name)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'first_name',
        NEW.raw_user_meta_data->>'last_name'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger execution
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 6. PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON public.transactions(status);
CREATE INDEX IF NOT EXISTS idx_crypto_deposit_addresses_user_id ON public.crypto_deposit_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_bank_accounts_user_id ON public.user_bank_accounts(user_id);
