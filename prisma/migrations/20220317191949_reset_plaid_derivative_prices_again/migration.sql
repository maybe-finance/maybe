-- Remove incorrect derivative pricing from Plaid
DELETE FROM "security_pricing" sp USING "security" s
WHERE s.id = sp.security_id
	AND s. "plaid_type" = 'derivative'
	AND sp. "source" = 'plaid';

-- Set `pricing_last_synced_at` to null so that derivatives re-sync from Plaid
UPDATE security SET pricing_last_synced_at = NULL WHERE plaid_type = 'derivative';