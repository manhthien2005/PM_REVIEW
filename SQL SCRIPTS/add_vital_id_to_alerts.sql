-- Migration: Add vital_id to alerts table to link alerts with vitals
-- This allows tracking which vital reading triggered an alert

-- Add vital_id column to alerts table
ALTER TABLE alerts ADD COLUMN vital_id BIGINT;

-- Add comment to explain the column
COMMENT ON COLUMN alerts.vital_id IS 'References the specific vital reading that triggered this alert';

-- Create index for better query performance
CREATE INDEX idx_alerts_vital_id ON alerts(vital_id);

-- Add foreign key constraint (optional, since vitals uses composite primary key)
-- We'll use a soft reference approach for now due to the composite key complexity