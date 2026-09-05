-- ====================================================================
-- RYZON CONVERT FEATURE 1.4: 4-DIGIT PIN SECURITY & LOCKOUT ENGINE
-- Migration: 20260901000002_pin_security.sql
-- Description: HMAC-SHA256 PIN hashing, verification & 3-strikes lockout
-- ====================================================================

-- 1. ADD PIN SECURITY COLUMNS TO PUBLIC.PROFILES
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS failed_pin_attempts INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS pin_locked_until TIMESTAMP WITH TIME ZONE;

-- 2. STORED FUNCTION: SET USER PIN
CREATE OR REPLACE FUNCTION public.set_user_pin(
    p_user_id UUID,
    p_pin_code TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    IF LENGTH(TRIM(p_pin_code)) != 4 THEN
        RAISE EXCEPTION 'PIN must be exactly 4 numeric digits';
    END IF;

    UPDATE public.profiles
    SET pin_hash = encode(hmac(p_pin_code::bytea, p_user_id::text::bytea, 'sha256'), 'hex'),
        failed_pin_attempts = 0,
        pin_locked_until = NULL,
        updated_at = NOW()
    WHERE id = p_user_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. STORED FUNCTION: VERIFY USER PIN WITH 3-STRIKES LOCKOUT
CREATE OR REPLACE FUNCTION public.verify_user_pin(
    p_user_id UUID,
    p_pin_code TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_profile RECORD;
    v_computed_hash TEXT;
    v_attempts INT;
    v_locked_until TIMESTAMP WITH TIME ZONE;
BEGIN
    SELECT * INTO v_profile
    FROM public.profiles
    WHERE id = p_user_id;

    IF v_profile IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'User profile not found');
    END IF;

    IF v_profile.pin_hash IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'PIN has not been created yet');
    END IF;

    -- Check lockout
    IF v_profile.pin_locked_until IS NOT NULL AND v_profile.pin_locked_until > NOW() THEN
        RETURN jsonb_build_object(
            'success', false,
            'locked', true,
            'message', 'PIN entry is temporarily locked due to 3 incorrect attempts. Please try again later.'
        );
    END IF;

    -- Compute HMAC-SHA256 hash using user ID as salt
    v_computed_hash := encode(hmac(p_pin_code::bytea, p_user_id::text::bytea, 'sha256'), 'hex');

    -- Correct PIN
    IF v_profile.pin_hash = v_computed_hash THEN
        UPDATE public.profiles
        SET failed_pin_attempts = 0,
            pin_locked_until = NULL
        WHERE id = p_user_id;

        RETURN jsonb_build_object('success', true, 'locked', false);
    ELSE
        -- Incorrect PIN
        v_attempts := v_profile.failed_pin_attempts + 1;
        IF v_attempts >= 3 THEN
            v_locked_until := NOW() + INTERVAL '15 minutes';
            UPDATE public.profiles
            SET failed_pin_attempts = v_attempts,
                pin_locked_until = v_locked_until
            WHERE id = p_user_id;

            RETURN jsonb_build_object(
                'success', false,
                'locked', true,
                'message', 'Incorrect PIN. You have exceeded 3 attempts. PIN locked for 15 minutes.'
            );
        ELSE
            UPDATE public.profiles
            SET failed_pin_attempts = v_attempts
            WHERE id = p_user_id;

            RETURN jsonb_build_object(
                'success', false,
                'locked', false,
                'attempts_remaining', 3 - v_attempts,
                'message', 'Incorrect PIN. ' || (3 - v_attempts)::text || ' attempt(s) remaining.'
            );
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
