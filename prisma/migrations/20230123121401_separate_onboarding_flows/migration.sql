ALTER TABLE "user" 
DROP COLUMN "onboarded",
ADD COLUMN  "onboarding" JSONB;

UPDATE "user"
SET "onboarding" = 
  CASE 
    WHEN "onboarding_steps" IS NULL THEN NULL 
    ELSE json_build_object(
      'main', json_build_object(
        'markedComplete', false,
        'steps', "onboarding_steps"
      ),
      'sidebar', json_build_object(
        'markedComplete', false,
        'steps', "onboarding_steps"
      )
    )
  END;

ALTER TABLE "user"
DROP COLUMN "onboarding_steps";
