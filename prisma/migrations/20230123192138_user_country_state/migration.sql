ALTER TABLE "user" ADD COLUMN "country" TEXT, ADD COLUMN "state" TEXT;

UPDATE "user"
SET
  "country" = (
    CASE
      WHEN "residence" IS NOT NULL THEN 'US'
      ELSE NULL
    END
  ),
  "state" = (
    CASE "residence"
      WHEN 'Alabama' THEN 'AL'
      WHEN 'California' THEN 'CA'
      WHEN 'Colorado' THEN 'CO'
      WHEN 'Delaware' THEN 'DE'
      WHEN 'District Of Columbia' THEN 'DC'
      WHEN 'Florida' THEN 'FL'
      WHEN 'Illinois' THEN 'IL'
      WHEN 'Indiana' THEN 'IN'
      WHEN 'Massachusetts' THEN 'MA'
      WHEN 'Nevada' THEN 'NV'
      WHEN 'New Jersey' THEN 'NJ'
      WHEN 'New York' THEN 'NY'
      WHEN 'Ohio' THEN 'OH'
      WHEN 'Oregon' THEN 'OR'
      WHEN 'Pennsylvania' THEN 'PA'
      WHEN 'South Carolina' THEN 'SC'
      WHEN 'Texas' THEN 'TX'
      WHEN 'Virginia' THEN 'VA'
      ELSE NULL
    END
  );

ALTER TABLE "user" DROP COLUMN "residence";
