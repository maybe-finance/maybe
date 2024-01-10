-- now that we are using the new balance calculation, remove the old initial transactions
DELETE FROM transaction WHERE name = 'INITIAL_TRANSACTION';
DELETE FROM investment_transaction WHERE name = 'INITIAL_TRANSACTION';