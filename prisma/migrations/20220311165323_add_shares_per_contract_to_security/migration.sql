-- AlterTable
ALTER TABLE "security" ADD COLUMN     "shares_per_contract" DECIMAL(36,18);

-- Remove incorrect derivative pricing from Plaid
DELETE FROM "security_pricing" sp USING "security" s
WHERE s.id = sp.security_id
	AND s. "plaid_type" = 'derivative'
	AND sp. "source" = 'plaid';