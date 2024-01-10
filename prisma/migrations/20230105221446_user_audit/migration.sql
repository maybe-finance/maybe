-- DropForeignKey
ALTER TABLE "advisor" DROP CONSTRAINT "advisor_user_id_fkey";

-- AddForeignKey
ALTER TABLE "advisor" ADD CONSTRAINT "advisor_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- audit user creation/deletion
CREATE OR REPLACE FUNCTION log_user() RETURNS TRIGGER AS $$
  BEGIN
    INSERT INTO audit_event ("type", "model_type", "model_id", "data")
    VALUES (
      LOWER(TG_OP)::"AuditEventType",
      'User',
      COALESCE(NEW."id", OLD."id"),
      to_json(COALESCE(NEW, OLD))
    );
    RETURN NULL; -- result is ignored since this is an AFTER trigger
  END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER user_audit_event
  AFTER INSERT OR DELETE
  ON "user"
  FOR EACH ROW
  EXECUTE FUNCTION log_user();
