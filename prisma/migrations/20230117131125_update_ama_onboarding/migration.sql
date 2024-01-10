ALTER TABLE "user" 
DROP COLUMN "goals_description",
DROP COLUMN "risk_tolerance",
ADD COLUMN  "risk_answers" JSONB NOT NULL DEFAULT '[]',
ADD COLUMN  "user_notes" TEXT,
ADD COLUMN  "goals_new" TEXT[];

UPDATE "user"
SET "goals_new" = "user"."goals";

ALTER TABLE "user"
DROP COLUMN "goals";

DROP TYPE "UserGoal";

ALTER TABLE "user"
RENAME COLUMN "goals_new" TO "goals";