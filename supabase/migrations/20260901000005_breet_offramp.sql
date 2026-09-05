-- ====================================================================
-- RYZON CONVERT SUPABASE DATABASE SCHEMA
-- Migration: 20260901000005_breet_offramp.sql
-- Description: Breet Off-Ramp integration, dual settlement mode preference, and NGN wallet balance
-- ====================================================================

-- 1. ADD SETTLEMENT MODE & WALLET BALANCE TO PROFILES
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS settlement_mode TEXT DEFAULT 'AUTO_SETTLEMENT' 
CHECK (settlement_mode IN ('AUTO_SETTLEMENT', 'MANUAL_BALANCE')),
ADD COLUMN IF NOT EXISTS wallet_balance_ngn NUMERIC(14, 2) DEFAULT 0.00;

-- 2. ENHANCE DEPOSIT ADDRESSES FOR BREET ASSETS
ALTER TABLE public.crypto_deposit_addresses
ADD COLUMN IF NOT EXISTS breet_asset_id TEXT,
ADD COLUMN IF NOT EXISTS breet_label TEXT,
ADD COLUMN IF NOT EXISTS breet_bank_id TEXT,
ADD COLUMN IF NOT EXISTS breet_account_number TEXT;

-- 3. ENHANCE TRANSACTIONS TABLE FOR BREET WEBHOOKS AND DUAL SETTLEMENT
ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS breet_trade_id TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS settlement_mode TEXT DEFAULT 'AUTO_SETTLEMENT' CHECK (settlement_mode IN ('AUTO_SETTLEMENT', 'MANUAL_BALANCE')),
ADD COLUMN IF NOT EXISTS net_naira_payout NUMERIC(14, 2) DEFAULT 0.00;

-- 4. INDEXES FOR FAST WEBHOOK RECONCILIATION
CREATE INDEX IF NOT EXISTS idx_transactions_breet_trade_id ON public.transactions(breet_trade_id);
CREATE INDEX IF NOT EXISTS idx_crypto_deposit_addresses_breet_label ON public.crypto_deposit_addresses(breet_label);
