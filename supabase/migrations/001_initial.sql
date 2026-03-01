-- DealForward: initial schema
-- Run via: supabase db push  OR paste into Supabase SQL editor

CREATE TABLE IF NOT EXISTS deals (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        TEXT NOT NULL,
  company     TEXT NOT NULL,
  stage       TEXT NOT NULL
                CHECK (stage IN ('prospect','qualify','demo','proposal','negotiation','closed_won','closed_lost')),
  amount      DOUBLE PRECISION NOT NULL DEFAULT 0,
  probability INTEGER          NOT NULL DEFAULT 0 CHECK (probability BETWEEN 0 AND 100),
  owner       TEXT NOT NULL,
  contact_name  TEXT,
  contact_email TEXT,
  notes       TEXT,
  competitors JSONB   NOT NULL DEFAULT '[]',
  close_date  TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS calls (
  id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title            TEXT NOT NULL,
  date             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  duration_seconds INTEGER     NOT NULL DEFAULT 0,
  participants     JSONB       NOT NULL DEFAULT '[]',
  audio_path       TEXT,
  transcript       TEXT,
  summary          TEXT,
  sentiment        TEXT CHECK (sentiment IN ('positive','neutral','negative')),
  keywords         JSONB NOT NULL DEFAULT '[]',
  next_steps       JSONB NOT NULL DEFAULT '[]',
  talk_ratio       JSONB NOT NULL DEFAULT '{"rep":50,"prospect":50}',
  deal_id          BIGINT REFERENCES deals(id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at on deals
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS deals_updated_at ON deals;
CREATE TRIGGER deals_updated_at
  BEFORE UPDATE ON deals
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Indexes
CREATE INDEX IF NOT EXISTS idx_calls_date     ON calls (date DESC);
CREATE INDEX IF NOT EXISTS idx_calls_deal_id  ON calls (deal_id);
CREATE INDEX IF NOT EXISTS idx_deals_stage    ON deals (stage);
CREATE INDEX IF NOT EXISTS idx_deals_created  ON deals (created_at DESC);
