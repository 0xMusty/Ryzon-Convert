-- Notifications table & automatic triggers
CREATE TABLE IF NOT EXISTS public.notifications (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title         text NOT NULL,
  message       text NOT NULL,
  type          text NOT NULL DEFAULT 'info', -- 'deposit', 'withdrawal', 'kyc', 'system'
  is_read       boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Function & Trigger to auto-create notification when a transaction occurs
CREATE OR REPLACE FUNCTION public.handle_new_transaction_notification()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type = 'DEPOSIT' OR NEW.type = 'CRYPTO_SELL' THEN
    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES (
      NEW.user_id,
      'Deposit Received',
      'Your deposit of ' || COALESCE(NEW.crypto_amount::text, '0') || ' ' || COALESCE(NEW.crypto_token, 'crypto') || ' was credited as ₦' || COALESCE(NEW.naira_amount::text, '0.00') || '.',
      'deposit'
    );
  ELSIF NEW.type = 'WITHDRAWAL' THEN
    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES (
      NEW.user_id,
      'Withdrawal Processed',
      'Your withdrawal of ₦' || COALESCE(NEW.naira_amount::text, '0.00') || ' to your bank account has been completed.',
      'withdrawal'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_new_transaction_notification ON public.transactions;

CREATE TRIGGER trg_new_transaction_notification
  AFTER INSERT ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_transaction_notification();
