-- CreateTable
CREATE TABLE "auth_password_resets" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL,
    "token" TEXT NOT NULL,

    CONSTRAINT "auth_password_resets_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "auth_password_resets_token_key" ON "auth_password_resets"("token");
