-- Tune timescale chunk sizes

-- account_balance -> 30d
CREATE TEMP TABLE account_balance_data ON COMMIT DROP AS (
  SELECT * FROM account_balance
);

SELECT drop_chunks('account_balance', interval '0 days');
TRUNCATE account_balance;

SELECT set_chunk_time_interval('account_balance', interval '30 days');

INSERT INTO account_balance
SELECT * FROM account_balance_data;


-- security_pricing -> 30d
CREATE TEMP TABLE security_pricing_data ON COMMIT DROP AS (
  SELECT * FROM security_pricing
);

SELECT drop_chunks('security_pricing', interval '0 days');
TRUNCATE security_pricing;

SELECT set_chunk_time_interval('security_pricing', interval '30 days');

INSERT INTO security_pricing
SELECT * FROM security_pricing_data;