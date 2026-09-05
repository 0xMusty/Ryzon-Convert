-- ====================================================================
-- RYZON CONVERT FEATURE 1.3: CUSTOM EMAIL OTP ENGINE
-- Migration: 20260901000001_email_otps.sql
-- Description: Stores 6-digit OTPs with 5-minute expiry & verification procedure
-- ====================================================================

-- 1. EMAIL OTPS TABLE
CREATE TABLE IF NOT EXISTS public.email_otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    purpose TEXT NOT NULL CHECK (purpose IN ('REGISTRATION', 'PASSWORD_RESET')),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    attempts INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

ALTER TABLE public.email_otps ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'email_otps' AND policyname = 'Service role full access on email_otps') THEN
        CREATE POLICY "Service role full access on email_otps" ON public.email_otps FOR ALL USING (true);
    END IF;
END $$;

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_email_otps_email ON public.email_otps(email);
CREATE INDEX IF NOT EXISTS idx_email_otps_lookup ON public.email_otps(email, purpose, is_used, expires_at);

-- 2. STORED FUNCTION: GENERATE EMAIL OTP
CREATE OR REPLACE FUNCTION public.generate_email_otp(
    p_email TEXT,
    p_purpose TEXT
)
RETURNS TEXT AS $$
DECLARE
    v_otp TEXT;
BEGIN
    -- Invalidate existing unused OTPs for this email & purpose
    UPDATE public.email_otps
    SET is_used = TRUE
    WHERE email = LOWER(TRIM(p_email))
      AND purpose = p_purpose
      AND is_used = FALSE;

    -- Generate random 6-digit numeric OTP (100000 to 999999)
    v_otp := LPAD(FLOOR(RANDOM() * 900000 + 100000)::TEXT, 6, '0');

    -- Insert new OTP record with 5-minute expiration
    INSERT INTO public.email_otps (
        email,
        otp_code,
        purpose,
        expires_at
    ) VALUES (
        LOWER(TRIM(p_email)),
        v_otp,
        p_purpose,
        NOW() + INTERVAL '5 minutes'
    );

    RETURN v_otp;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. STORED FUNCTION: VERIFY EMAIL OTP
CREATE OR REPLACE FUNCTION public.verify_email_otp(
    p_email TEXT,
    p_otp_code TEXT,
    p_purpose TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_otp_record RECORD;
BEGIN
    -- Find latest valid unused OTP record
    SELECT * INTO v_otp_record
    FROM public.email_otps
    WHERE email = LOWER(TRIM(p_email))
      AND purpose = p_purpose
      AND is_used = FALSE
      AND expires_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_otp_record IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Update attempt count
    UPDATE public.email_otps
    SET attempts = attempts + 1
    WHERE id = v_otp_record.id;

    -- Check if code matches
    IF v_otp_record.otp_code = TRIM(p_otp_code) THEN
        -- Mark as used
        UPDATE public.email_otps
        SET is_used = TRUE
        WHERE id = v_otp_record.id;
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. GRANTS AND RLS POLICIES
DROP POLICY IF EXISTS "Public access on email_otps" ON public.email_otps;
CREATE POLICY "Public access on email_otps" ON public.email_otps FOR ALL USING (true) WITH CHECK (true);

GRANT ALL ON TABLE public.email_otps TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.generate_email_otp(TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.verify_email_otp(TEXT, TEXT, TEXT) TO anon, authenticated, service_role;

