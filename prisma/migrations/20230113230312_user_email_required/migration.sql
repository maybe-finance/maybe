-- delete users who no longer exist in Auth0 (determined by lack of `email` which was populated during the migration)
DELETE FROM "user" WHERE "email" IS NULL;
ALTER TABLE "user" ALTER COLUMN "email" SET NOT NULL;
