-- update plaid mortgage accounts
UPDATE "account"
SET
  "loan_provider" = json_build_object(
    'originationDate', plaid_liability->'mortgage'->>'origination_date',
    'originationPrincipal', plaid_liability->'mortgage'->'origination_principal_amount',
    'maturityDate', plaid_liability->'mortgage'->>'maturity_date',
    'interestRate', (
      CASE plaid_liability->'mortgage'->'interest_rate'->>'type'
        WHEN 'fixed' THEN json_build_object(
          'type', 'fixed',
          'rate', plaid_liability->'mortgage'->'interest_rate'->'percentage'
        )
        ELSE json_build_object(
          'type', 'variable'
        )
      END
    ),
    'loanDetail', json_build_object(
      'type', 'mortgage'
    )
  )
WHERE
  "loan_provider" IS NULL AND "plaid_liability"->>'mortgage' IS NOT NULL;

-- update plaid student loan accounts
UPDATE "account"
SET
  "loan_provider" = json_build_object(
    'originationDate', plaid_liability->'student'->>'origination_date',
    'originationPrincipal', plaid_liability->'student'->'origination_principal_amount',
    'maturityDate', plaid_liability->'student'->>'maturity_date',
    'interestRate', json_build_object(
      'type', 'fixed',
      'rate', plaid_liability->'student'->'interest_rate_percentage'
    ),
    'loanDetail', json_build_object(
      'type', 'student'
    )
  )
WHERE
  "loan_provider" IS NULL AND "plaid_liability"->>'student' IS NOT NULL;

-- update plaid credit accounts
UPDATE "account"
SET
  "credit_provider" = json_build_object(
    'isOverdue', plaid_liability->'credit'->>'is_overdue',
    'lastPaymentAmount', plaid_liability->'credit'->'last_payment_amount',
    'lastPaymentDate', plaid_liability->'credit'->>'last_payment_date',
    'lastStatementAmount', plaid_liability->'credit'->'last_statement_balance',
    'lastStatementDate', plaid_liability->'credit'->>'last_statement_issue_date',
    'minimumPayment', plaid_liability->'credit'->'minimum_payment_amount'
  )
WHERE
  "credit_provider" IS NULL AND "plaid_liability"->>'credit' IS NOT NULL;
