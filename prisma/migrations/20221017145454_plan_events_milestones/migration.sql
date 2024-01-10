/*
  Warnings:

  - You are about to drop the column `events` on the `plan` table. All the data in the column will be lost.
  - You are about to drop the column `milestones` on the `plan` table. All the data in the column will be lost.

*/
-- CreateEnum
CREATE TYPE "PlanEventFrequency" AS ENUM ('monthly', 'yearly');

-- CreateEnum
CREATE TYPE "PlanMilestoneType" AS ENUM ('year', 'net_worth');

-- CreateTable
CREATE TABLE "plan_event" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "plan_id" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "start_year" INTEGER CHECK ("start_year" > 0),
    "start_milestone_id" INTEGER,
    "end_year" INTEGER CHECK ("end_year" > 0),
    "end_milestone_id" INTEGER,
    "frequency" "PlanEventFrequency" NOT NULL DEFAULT 'yearly',
    "initial_value" DECIMAL(19,4),
    "initial_value_ref" TEXT,
    "rate" DECIMAL(6,4) NOT NULL DEFAULT 0,

    CONSTRAINT "plan_event_pkey" PRIMARY KEY ("id"),

    CONSTRAINT "start_check" CHECK (num_nonnulls("start_year", "start_milestone_id") <= 1),
    CONSTRAINT "end_check" CHECK (num_nonnulls("end_year", "end_milestone_id") <= 1),
    CONSTRAINT "initial_value_check" CHECK (num_nonnulls("initial_value", "initial_value_ref") = 1)
);

-- CreateTable
CREATE TABLE "plan_milestone" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "plan_id" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "type" "PlanMilestoneType" NOT NULL,
    "year" INTEGER CHECK ("year" > 0),
    "expense_multiple" DOUBLE PRECISION CHECK ("expense_multiple" >= 0),
    "expense_years" INTEGER CHECK ("expense_years" >= 0),

    CONSTRAINT "plan_milestone_pkey" PRIMARY KEY ("id"),

    -- constraints for validating discriminated union
    CONSTRAINT "type_year_check" CHECK ("type" <> 'year' OR ("year" IS NOT NULL)),
    CONSTRAINT "type_net_worth_check" CHECK ("type" <> 'net_worth' OR ("expense_multiple" IS NOT NULL AND "expense_years" IS NOT NULL))
);

-- AddForeignKey
ALTER TABLE "plan_event" ADD CONSTRAINT "plan_event_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_event" ADD CONSTRAINT "plan_event_start_milestone_id_fkey" FOREIGN KEY ("start_milestone_id") REFERENCES "plan_milestone"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_event" ADD CONSTRAINT "plan_event_end_milestone_id_fkey" FOREIGN KEY ("end_milestone_id") REFERENCES "plan_milestone"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_milestone" ADD CONSTRAINT "plan_milestone_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- migrate milestones
INSERT INTO plan_milestone (plan_id, name, type, year, expense_multiple, expense_years)
SELECT
  p.id,
  m.name,
  m.type::"PlanMilestoneType",
  m.year,
  m.expense_multiple,
  m.expense_years
FROM
  plan p,
  jsonb_to_recordset(p.milestones) AS m("name" text, "type" text, "year" int, "expense_multiple" float, "expense_years" int);

-- migrate plans
INSERT INTO plan_event (plan_id, name, start_year, end_year, frequency, initial_value, initial_value_ref, rate)
SELECT
  p.id,
  e.name,
  e.start,
  e.end,
  e.frequency::"PlanEventFrequency",
  CASE WHEN v.initial_value IN ('income', 'expenses') THEN NULL ELSE v.initial_value::decimal END AS "initial_value",
  CASE WHEN v.initial_value IN ('income', 'expenses') THEN v.initial_value ELSE NULL END AS "initial_value_ref",
  v.rate
FROM
  plan p,
  jsonb_to_recordset(p.events) AS e("name" text, "start" int, "end" int, "frequency" text, "value" jsonb)
  LEFT JOIN LATERAL (
    SELECT 
      COALESCE(e.value->>'initialValue', e.value->>'value') AS "initial_value",
      COALESCE((e.value->>'rate')::decimal, 0) AS "rate"
  ) v ON true;

-- drop plan/milestone json columns
ALTER TABLE "plan" DROP COLUMN "events", DROP COLUMN "milestones";