UPDATE account
SET
  start_date = COALESCE((loan->>'originationDate')::date, start_date)
WHERE
  type = 'LOAN' AND loan IS NOT NULL;
