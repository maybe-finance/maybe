
-- DropForeignKey
ALTER TABLE "advisor" DROP CONSTRAINT "advisor_user_id_fkey";

-- AlterTable
CREATE SEQUENCE "advisor_id_seq";
ALTER TABLE "advisor" ADD COLUMN     "avatar_src" TEXT NOT NULL,
ADD COLUMN     "full_name" TEXT NOT NULL,
ALTER COLUMN "id" SET DEFAULT nextval('advisor_id_seq');
ALTER SEQUENCE "advisor_id_seq" OWNED BY "advisor"."id";

-- AlterTable
ALTER TABLE "message" DROP COLUMN "media_url",
ADD COLUMN     "media_src" TEXT;

-- AddForeignKey
ALTER TABLE "advisor" ADD CONSTRAINT "advisor_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
