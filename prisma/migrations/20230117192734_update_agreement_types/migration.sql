-- Clear agreements
DELETE FROM "agreement";

-- AlterEnum
BEGIN;
CREATE TYPE "AgreementType_new" AS ENUM ('fee', 'form_adv_2a', 'form_adv_2b', 'form_crs', 'privacy_policy');
ALTER TABLE "agreement" ALTER COLUMN "type" TYPE "AgreementType_new" USING ("type"::text::"AgreementType_new");
ALTER TYPE "AgreementType" RENAME TO "AgreementType_old";
ALTER TYPE "AgreementType_new" RENAME TO "AgreementType";
DROP TYPE "AgreementType_old";
COMMIT;

-- DropIndex
DROP INDEX "agreement_type_revision_key";

-- CreateIndex
CREATE UNIQUE INDEX "agreement_type_revision_active_key" ON "agreement"("type", "revision", "active");

-- Insert initial agreements 
INSERT INTO 
	agreement("type", "revision", "src", "active") 
VALUES 
	('fee', '2023-01-11', 'agreements/limited-scope-advisory-agreement-2023-01-11.pdf', true),
	('form_adv_2a', '2022-09-07', 'agreements/form-ADV-2A-2022-09-07.pdf', true),
	('form_adv_2b', '2022-11-04', 'agreements/form-ADV-2B-2022-11-04.pdf', true),
	('form_crs', '2022-09-20', 'agreements/form-CRS-2022-09-20.pdf', true),
	('privacy_policy', '2023-01-11', 'agreements/advisor-privacy-policy-2023-01-11.pdf', true);
