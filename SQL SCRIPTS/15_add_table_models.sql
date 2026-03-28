-- CreateTable
CREATE TABLE "ai_models" (
    "id" SERIAL NOT NULL,
    "uuid" UUID NOT NULL DEFAULT gen_random_uuid(),
    "key" VARCHAR(100) NOT NULL,
    "display_name" VARCHAR(255) NOT NULL,
    "task" VARCHAR(50) NOT NULL,
    "description" TEXT,
    "is_active" BOOLEAN DEFAULT true,
    "active_version_id" INTEGER,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "ai_models_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ai_model_versions" (
    "id" SERIAL NOT NULL,
    "uuid" UUID NOT NULL DEFAULT gen_random_uuid(),
    "model_id" INTEGER NOT NULL,
    "version" VARCHAR(50) NOT NULL,
    "artifact_path" VARCHAR(500) NOT NULL,
    "artifact_sha256" VARCHAR(64) NOT NULL,
    "artifact_size_bytes" BIGINT,
    "format" VARCHAR(20) NOT NULL,
    "status" VARCHAR(20) NOT NULL DEFAULT 'draft',
    "release_notes" TEXT,
    "created_by" INTEGER,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "ai_model_versions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ai_models_uuid_key" ON "ai_models"("uuid");

-- CreateIndex
CREATE UNIQUE INDEX "ai_models_key_key" ON "ai_models"("key");

-- CreateIndex
CREATE INDEX "idx_ai_models_key" ON "ai_models"("key");

-- CreateIndex
CREATE INDEX "idx_ai_models_task" ON "ai_models"("task");

-- CreateIndex
CREATE UNIQUE INDEX "ai_model_versions_uuid_key" ON "ai_model_versions"("uuid");

-- CreateIndex
CREATE INDEX "idx_ai_model_versions_model" ON "ai_model_versions"("model_id");

-- CreateIndex
CREATE UNIQUE INDEX "unique_ai_model_version" ON "ai_model_versions"("model_id", "version");

-- AddForeignKey
ALTER TABLE "ai_models" ADD CONSTRAINT "ai_models_active_version_id_fkey" FOREIGN KEY ("active_version_id") REFERENCES "ai_model_versions"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "ai_model_versions" ADD CONSTRAINT "ai_model_versions_model_id_fkey" FOREIGN KEY ("model_id") REFERENCES "ai_models"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "ai_model_versions" ADD CONSTRAINT "ai_model_versions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION;
