/*
  Warnings:

  - A unique constraint covering the columns `[finicity_customer_id]` on the table `user` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "user_finicity_customer_id_key" ON "user"("finicity_customer_id");
