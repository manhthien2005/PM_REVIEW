node.exe : Loaded Prisma config from prisma.config.ts.
At C:\Program Files\nodejs\npx.ps1:29 char:3
+   & $NODE_EXE $NPX_CLI_JS $args
+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (Loaded Prisma c...isma.config.ts.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 

-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "alert_severity" AS ENUM ('low', 'medium', 'high', 'critical');

-- CreateEnum
CREATE TYPE "risk_level" AS ENUM ('low', 'medium', 'high', 'critical');

-- CreateEnum
CREATE TYPE "sos_status" AS ENUM ('active', 'responded', 'cancelled', 'resolved');

-- CreateEnum
CREATE TYPE "user_role" AS ENUM ('user', 'admin');

-- CreateTable
CREATE TABLE "alerts" (
    "id" SERIAL NOT NULL,
    "uuid" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" INTEGER NOT NULL,
    "device_id" INTEGER,
    "alert_type" VARCHAR(50) NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "message" TEXT,
    "severity" VARCHAR(20) DEFAULT 'medium',
    "fall_event_id" INTEGER,
    "sos_event_id" INTEGER,
    "data" JSONB,
    "sent_at" TIMESTAMPTZ(6),
    "delivered_at" TIMESTAMPTZ(6),
    "read_at" TIMESTAMPTZ(6),
    "acknowledged_at" TIMESTAMPTZ(6),
    "sent_via" TEXT[] DEFAULT ARRAY['push']::TEXT[],
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMPTZ(6),

    CONSTRAINT "alerts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" BIGSERIAL NOT NULL,
    "time" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "user_id" INTEGER,
    "device_id" INTEGER,
    "action" VARCHAR(100) NOT NULL,
    "resource_type" VARCHAR(50),
    "resource_id" INTEGER,
    "details" JSONB,
    "ip_address" INET,
    "user_agent" TEXT,
    "status" VARCHAR(20),
    "error_message" TEXT,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id","time")
);

-- CreateTable
CREATE TABLE "devices" (
    "id" SERIAL NOT NULL,
    "uuid" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" INTEGER,
    "device_name" VARCHAR(100),
    "device_type" VARCHAR(50) DEFAULT 'smartwatch',
    "model" VARCHAR(100),
    "firmware_version" VARCHAR(20),
    "mac_address" VARCHAR(17),
    "serial_number" VARCHAR(100),
    "is_active" BOOLEAN DEFAULT true,
    "battery_level" SMALLINT,
    "signal_strength" SMALLINT,
    "last_seen_at" TIMESTAMPTZ(6),
    "last_sync_at" TIMESTAMPTZ(6),
    "mqtt_client_id" VARCHAR(100),
    "calibration_data" JSONB,
    "registered_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "devices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "emergency_contacts" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "relationship" VARCHAR(50),
    "priority" SMALLINT DEFAULT 1,
    "notify_via_sms" BOOLEAN DEFAULT true,
    "notify_via_call" BOOLEAN DEFAULT false,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "emergency_contacts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fall_events" (
    "id" SERIAL NOT NULL,
    "uuid" UUID NOT NULL DEFAULT gen_random_uuid(),
    "device_id" INTEGER NOT NULL,
    "detected_at" TIMESTAMPTZ(6) NOT NULL,
    "confidence" DECIMAL(4,3) NOT NULL,
    "model_version" VARCHAR(20),
    "latitude" DECIMAL(10,8),
    "longitude" DECIMAL(11,8),
    "location_accuracy" REAL,
    "address" TEXT,
    "user_notified_at" TIMESTAMPTZ(6),
    "user_responded_at" TIMESTAMPTZ(6),
    "user_cancelled" BOOLEAN DEFAULT false,
    "cancel_reason" VARCHAR(255),
    "sos_triggered" BOOLEAN DEFAULT false,
    "sos_triggered_at" TIMESTAMPTZ(6),
    "features" JSONB,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "fall_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "motion_data" (
    "time" TIMESTAMPTZ(6) NOT NULL,
    "device_id" INTEGER NOT NULL,
    "accel_x" REAL,
    "accel_y" REAL,
    "accel_z" REAL,
    "gyro_x" REAL,
    "gyro_y" REAL,
    "gyro_z" REAL,
    "magnitude" REAL,
    "sampling_rate" SMALLINT DEFAULT 50,

    CONSTRAINT "motion_data_pkey" PRIMARY KEY ("device_id","time")
);

-- CreateTable
CREATE TABLE "risk_explanations" (
    "id" SERIAL NOT NULL,
    "risk_score_id" INTEGER NOT NULL,
    "explanation_text" TEXT NOT NULL,
    "feature_importance" JSONB,
    "xai_method" VARCHAR(50),
    "recommendations" TEXT[],
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "risk_explanations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "risk_scores" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "device_id" INTEGER,
    "calculated_at" TIMESTAMPTZ(6) NOT NULL,
    "risk_type" VARCHAR(50) NOT NULL,
    "score" DECIMAL(5,2) NOT NULL,
    "risk_level" VARCHAR(20),
    "features" JSONB NOT NULL,
    "model_version" VARCHAR(20),
    "algorithm" VARCHAR(50),
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "risk_scores_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sos_events" (
    "id" SERIAL NOT NULL,
    "uuid" UUID NOT NULL DEFAULT gen_random_uuid(),
    "fall_event_id" INTEGER,
    "device_id" INTEGER NOT NULL,
    "user_id" INTEGER NOT NULL,
    "trigger_type" VARCHAR(20) NOT NULL,
    "triggered_at" TIMESTAMPTZ(6) NOT NULL,
    "latitude" DECIMAL(10,8),
    "longitude" DECIMAL(11,8),
    "address" TEXT,
    "status" VARCHAR(20) DEFAULT 'active',
    "resolved_at" TIMESTAMPTZ(6),
    "resolved_by_user_id" INTEGER,
    "resolution_notes" TEXT,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sos_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "system_metrics" (
    "time" TIMESTAMPTZ(6) NOT NULL,
    "metric_name" VARCHAR(100) NOT NULL,
    "value" REAL NOT NULL,
    "tags" JSONB,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "system_metrics_pkey" PRIMARY KEY ("metric_name","time")
);

-- CreateTable
CREATE TABLE "user_relationships" (
    "id" SERIAL NOT NULL,
    "patient_id" INTEGER NOT NULL,
    "caregiver_id" INTEGER NOT NULL,
    "relationship_type" VARCHAR(50),
    "is_primary" BOOLEAN DEFAULT false,
    "can_view_vitals" BOOLEAN DEFAULT true,
    "can_receive_alerts" BOOLEAN DEFAULT true,
    "can_view_location" BOOLEAN DEFAULT false,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "user_relationships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" SERIAL NOT NULL,
    "uuid" UUID NOT NULL DEFAULT gen_random_uuid(),
    "email" VARCHAR(255) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(20),
    "full_name" VARCHAR(100) NOT NULL,
    "date_of_birth" DATE,
    "gender" VARCHAR(10),
    "avatar_url" TEXT,
    "role" VARCHAR(20) NOT NULL DEFAULT 'user',
    "is_active" BOOLEAN DEFAULT true,
    "is_verified" BOOLEAN DEFAULT false,
    "blood_type" VARCHAR(5),
    "height_cm" SMALLINT,
    "weight_kg" DECIMAL(5,2),
    "medical_conditions" TEXT[],
    "medications" TEXT[],
    "allergies" TEXT[],
    "language" VARCHAR(10) DEFAULT 'vi',
    "timezone" VARCHAR(50) DEFAULT 'Asia/Ho_Chi_Minh',
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "last_login_at" TIMESTAMPTZ(6),
    "deleted_at" TIMESTAMPTZ(6),
    "token_version" INTEGER NOT NULL DEFAULT 1,
    "failed_login_attempts" INTEGER NOT NULL DEFAULT 0,
    "locked_until" TIMESTAMPTZ(6),

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "password_reset_tokens" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "token_hash" VARCHAR(255) NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "used_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "ip_address" INET,
    "user_agent" TEXT,

    CONSTRAINT "password_reset_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vitals" (
    "time" TIMESTAMPTZ(6) NOT NULL,
    "device_id" INTEGER NOT NULL,
    "heart_rate" SMALLINT,
    "spo2" DECIMAL(4,2),
    "temperature" DECIMAL(4,2),
    "blood_pressure_sys" SMALLINT,
    "blood_pressure_dia" SMALLINT,
    "hrv" SMALLINT,
    "respiratory_rate" SMALLINT,
    "signal_quality" SMALLINT,
    "motion_artifact" BOOLEAN DEFAULT false,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vitals_pkey" PRIMARY KEY ("device_id","time")
);

-- CreateTable
CREATE TABLE "users_archive" (
    "id" SERIAL NOT NULL,
    "original_id" INTEGER NOT NULL,
    "uuid" UUID NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "user_data" JSON NOT NULL,
    "archived_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "archived_by" INTEGER,

    CONSTRAINT "users_archive_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "system_settings" (
    "setting_key" VARCHAR(100) NOT NULL,
    "setting_group" VARCHAR(50) NOT NULL,
    "setting_value" JSONB NOT NULL,
    "description" TEXT,
    "is_editable" BOOLEAN DEFAULT true,
    "updated_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_by" INTEGER,

    CONSTRAINT "system_settings_pkey" PRIMARY KEY ("setting_key")
);

-- CreateTable
CREATE TABLE "sleep_sessions" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "device_id" INTEGER,
    "start_time" TIMESTAMPTZ(6) NOT NULL,
    "end_time" TIMESTAMPTZ(6) NOT NULL,
    "sleep_score" SMALLINT,
    "phases" JSONB,
    "wake_count" SMALLINT DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sleep_sessions_pkey" PRIMARY KEY ("id")
);

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
CREATE UNIQUE INDEX "alerts_uuid_key" ON "alerts"("uuid");

-- CreateIndex
CREATE INDEX "idx_alerts_user" ON "alerts"("user_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "audit_logs_time_idx" ON "audit_logs"("time" DESC);

-- CreateIndex
CREATE INDEX "idx_audit_logs_user" ON "audit_logs"("user_id", "time" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "devices_uuid_key" ON "devices"("uuid");

-- CreateIndex
CREATE INDEX "idx_devices_user" ON "devices"("user_id");

-- CreateIndex
CREATE INDEX "idx_devices_uuid" ON "devices"("uuid");

-- CreateIndex
CREATE UNIQUE INDEX "fall_events_uuid_key" ON "fall_events"("uuid");

-- CreateIndex
CREATE INDEX "motion_data_time_idx" ON "motion_data"("time" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "sos_events_uuid_key" ON "sos_events"("uuid");

-- CreateIndex
CREATE INDEX "idx_system_metrics_tags" ON "system_metrics" USING GIN ("tags");

-- CreateIndex
CREATE INDEX "system_metrics_time_idx" ON "system_metrics"("time" DESC);

-- CreateIndex
CREATE INDEX "idx_relationships_caregiver" ON "user_relationships"("caregiver_id");

-- CreateIndex
CREATE INDEX "idx_relationships_patient" ON "user_relationships"("patient_id");

-- CreateIndex
CREATE UNIQUE INDEX "unique_patient_caregiver" ON "user_relationships"("patient_id", "caregiver_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_uuid_key" ON "users"("uuid");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "idx_users_created_at" ON "users"("created_at" DESC);

-- CreateIndex
CREATE INDEX "idx_users_email" ON "users"("email");

-- CreateIndex
CREATE INDEX "idx_users_role" ON "users"("role");

-- CreateIndex
CREATE INDEX "idx_password_reset_tokens_hash" ON "password_reset_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "idx_password_reset_tokens_user" ON "password_reset_tokens"("user_id");

-- CreateIndex
CREATE INDEX "idx_vitals_device_time" ON "vitals"("device_id", "time" DESC);

-- CreateIndex
CREATE INDEX "vitals_time_idx" ON "vitals"("time" DESC);

-- CreateIndex
CREATE INDEX "idx_users_archive_original_id" ON "users_archive"("original_id");

-- CreateIndex
CREATE INDEX "idx_sleep_sessions_user_time" ON "sleep_sessions"("user_id", "start_time" DESC);

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
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_fall_event_id_fkey" FOREIGN KEY ("fall_event_id") REFERENCES "fall_events"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_sos_event_id_fkey" FOREIGN KEY ("sos_event_id") REFERENCES "sos_events"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "devices" ADD CONSTRAINT "devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "emergency_contacts" ADD CONSTRAINT "emergency_contacts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "fall_events" ADD CONSTRAINT "fall_events_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "motion_data" ADD CONSTRAINT "motion_data_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "risk_explanations" ADD CONSTRAINT "risk_explanations_risk_score_id_fkey" FOREIGN KEY ("risk_score_id") REFERENCES "risk_scores"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "risk_scores" ADD CONSTRAINT "risk_scores_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "risk_scores" ADD CONSTRAINT "risk_scores_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "sos_events" ADD CONSTRAINT "sos_events_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "sos_events" ADD CONSTRAINT "sos_events_fall_event_id_fkey" FOREIGN KEY ("fall_event_id") REFERENCES "fall_events"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "sos_events" ADD CONSTRAINT "sos_events_resolved_by_user_id_fkey" FOREIGN KEY ("resolved_by_user_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "sos_events" ADD CONSTRAINT "sos_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "user_relationships" ADD CONSTRAINT "user_relationships_caregiver_id_fkey" FOREIGN KEY ("caregiver_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "user_relationships" ADD CONSTRAINT "user_relationships_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "password_reset_tokens" ADD CONSTRAINT "password_reset_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "vitals" ADD CONSTRAINT "vitals_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "system_settings" ADD CONSTRAINT "system_settings_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "sleep_sessions" ADD CONSTRAINT "sleep_sessions_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "sleep_sessions" ADD CONSTRAINT "sleep_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "ai_models" ADD CONSTRAINT "ai_models_active_version_id_fkey" FOREIGN KEY ("active_version_id") REFERENCES "ai_model_versions"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "ai_model_versions" ADD CONSTRAINT "ai_model_versions_model_id_fkey" FOREIGN KEY ("model_id") REFERENCES "ai_models"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "ai_model_versions" ADD CONSTRAINT "ai_model_versions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

