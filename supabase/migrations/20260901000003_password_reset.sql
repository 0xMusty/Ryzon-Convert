-- ====================================================================
-- RYZON CONVERT FEATURE 1.5: PASSWORD RESET FLOW
-- Migration: 20260901000003_password_reset.sql
-- Description: Password reset OTP verification stored procedure
-- ====================================================================

-- STORED FUNCTION: VERIFY OTP AND AUTHORIZE PASSWORD RESET
CREATE OR REPLACE FUNCTION public.reset_password_with_otp(
    p_email TEXT,
    p_otp_code TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_valid BOOLEAN;
BEGIN
    v_is_valid := public.verify_email_otp(p_email, p_otp_code, 'PASSWORD_RESET');
    IF NOT v_is_valid THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
