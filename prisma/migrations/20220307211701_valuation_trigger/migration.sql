-- the valuation_changed trigger is used to keep `account.start_date` and `account.current_balance` in sync with the account's valuations
CREATE OR REPLACE FUNCTION valuation_changed() RETURNS TRIGGER LANGUAGE plpgsql AS $$
  BEGIN
    UPDATE account AS a
    SET 
      start_date = account_value_start_date(a.id),
      current_balance = (SELECT v.amount FROM valuation v WHERE v.account_id = a.id ORDER BY v.date DESC LIMIT 1)
    WHERE 
      (a.id = NEW.account_id OR a.id = OLD.account_id) 
      AND a.valuation_method = 'valuation';
    RETURN NULL;
  END;
$$;

CREATE OR REPLACE TRIGGER valuation_changed
  AFTER INSERT OR UPDATE OF account_id, amount, date OR DELETE
  ON valuation
  FOR EACH ROW
  EXECUTE FUNCTION valuation_changed();