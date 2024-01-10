CREATE OR REPLACE FUNCTION calculate_return_dietz(p_account_id account.id%type, p_start date, p_end date, out percentage numeric, out amount numeric) AS $$
  DECLARE
    v_start date := GREATEST(p_start, (SELECT MIN(date) FROM account_balance WHERE account_id = p_account_id));
    v_end date := p_end;
    v_days int := v_end - v_start;
  BEGIN
    SELECT
      ROUND((b1.balance - b0.balance - flows.net) / NULLIF(b0.balance + flows.weighted, 0), 4) AS "percentage",
      b1.balance - b0.balance - flows.net AS "amount"
    INTO
      percentage, amount
    FROM
      account a
      LEFT JOIN LATERAL (
        SELECT
          COALESCE(SUM(-fw.flow), 0) AS "net",
          COALESCE(SUM(-fw.flow * fw.weight), 0) AS "weighted"
        FROM (
          SELECT
            SUM(it.amount) AS flow,
            (v_days - (it.date - v_start))::numeric / v_days AS weight
          FROM
            investment_transaction it
          WHERE
            it.account_id = a.id
            AND it.date BETWEEN v_start AND v_end
            -- filter for investment_transactions that represent external flows
            AND (
              (it.plaid_type = 'cash' AND it.plaid_subtype IN ('contribution', 'deposit', 'withdrawal'))
              OR (it.plaid_type = 'transfer' AND it.plaid_subtype IN ('transfer', 'send', 'request'))
              OR (it.plaid_type = 'buy' AND it.plaid_subtype IN ('contribution'))
              OR (it.finicity_transaction_id IS NOT NULL AND it.finicity_investment_transaction_type IN ('contribution', 'deposit', 'transfer'))
            )
          GROUP BY
            it.date
        ) fw
      ) flows ON TRUE
      LEFT JOIN LATERAL (
        SELECT
          ab.balance AS "balance"
        FROM
          account_balance ab
        WHERE
          ab.account_id = a.id AND ab.date <= v_start
        ORDER BY
          ab.date DESC
        LIMIT 1
      ) b0 ON TRUE
      LEFT JOIN LATERAL (
        SELECT
          COALESCE(ab.balance, a.current_balance) AS "balance"
        FROM
          account_balance ab
        WHERE
          ab.account_id = a.id AND ab.date <= v_end
        ORDER BY
          ab.date DESC
        LIMIT 1
      ) b1 ON TRUE
    WHERE
      a.id = p_account_id;
  END;
$$ LANGUAGE plpgsql STABLE;

