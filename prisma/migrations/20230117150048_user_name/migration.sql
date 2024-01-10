-- AlterTable
ALTER TABLE "user" ADD COLUMN "name" TEXT GENERATED ALWAYS AS (
  CASE
    WHEN first_name IS NULL THEN last_name
    WHEN last_name IS NULL THEN first_name
    ELSE first_name || ' ' || last_name
  END
) STORED;
