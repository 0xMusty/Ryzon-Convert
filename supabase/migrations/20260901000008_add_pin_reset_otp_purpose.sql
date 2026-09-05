-- Migration: Add PIN_RESET to email_otps purpose check constraint
ALTER TABLE public.email_otps DROP CONSTRAINT IF EXISTS email_otps_purpose_check;
ALTER TABLE public.email_otps ADD CONSTRAINT email_otps_purpose_check 
  CHECK (purpose = ANY (ARRAY['REGISTRATION'::text, 'PASSWORD_RESET'::text, 'PIN_RESET'::text]));
