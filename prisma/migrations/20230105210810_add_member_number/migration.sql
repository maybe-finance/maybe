-- AlterTable
ALTER TABLE "user" ADD COLUMN "member_number" INT;

CREATE SEQUENCE user_member_number_seq;

UPDATE "user"
  SET "member_number" = "u"."number"
  FROM (
    SELECT "id", nextval('user_member_number_seq') AS "number"
    FROM "user"
    ORDER BY "id" ASC
  ) "u"
  WHERE "user"."id" = "u"."id";

ALTER TABLE "user" ALTER COLUMN "member_number" SET DEFAULT nextval('user_member_number_seq');
ALTER TABLE "user" ALTER COLUMN "member_number" SET NOT NULL;

ALTER SEQUENCE user_member_number_seq OWNED BY "user"."member_number";

-- CreateIndex
CREATE UNIQUE INDEX "user_member_number_key" ON "user"("member_number");
