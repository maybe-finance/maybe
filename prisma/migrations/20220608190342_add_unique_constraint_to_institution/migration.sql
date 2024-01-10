/*
  Warnings:

  - A unique constraint covering the columns `[name,url]` on the table `institution` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "institution_name_url_key" ON "institution"("name", "url");
