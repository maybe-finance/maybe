-- Remove duplicates
DELETE FROM valuation a
WHERE EXISTS (
		SELECT
			1
		FROM
			valuation b
		WHERE
			b.account_id = a.account_id
			AND b.source = a.source
			AND b.date = a.date
			AND b.id < a.id);

-- CreateIndex
CREATE UNIQUE INDEX "valuation_account_id_source_date_key" ON "valuation"("account_id", "source", "date");
