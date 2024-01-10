-- CreateEnum
CREATE TYPE "AuditEventType" AS ENUM ('insert', 'update', 'delete');

-- CreateTable
CREATE TABLE "audit_event" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "type" "AuditEventType" NOT NULL,
    "model_type" TEXT NOT NULL,
    "model_id" INTEGER NOT NULL,
    "data" JSONB NOT NULL,
    "user_id" INTEGER,

    CONSTRAINT "audit_event_pkey" PRIMARY KEY ("id")
);

CREATE OR REPLACE FUNCTION log_conversation_messages()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
  
    -- Handles INSERT,UPDATE,DELETE events on changes to the message table
  INSERT INTO audit_event("type","model_type","model_id","data","user_id")
  VALUES(
    LOWER(TG_OP)::"AuditEventType",
    'Message',
    COALESCE(NEW."id",OLD."id"),
    to_json(COALESCE(NEW,OLD)),
      COALESCE(NEW."user_id",OLD."user_id")
  );
    
  RETURN COALESCE(NEW,OLD);
END;
$$;

CREATE OR REPLACE TRIGGER message_audit_event
  AFTER INSERT OR UPDATE OR DELETE
  ON message
  FOR EACH ROW
  EXECUTE PROCEDURE log_conversation_messages();
  