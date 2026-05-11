-- ============================================================
-- Salon Purchasing Tracker — Supabase Schema
-- Template for reuse across interior design + salon projects
-- ============================================================

-- Projects (one per client / build-out)
CREATE TABLE projects (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,                      -- "Hair Salon McKinney"
  client_name TEXT,
  location    TEXT,
  designer    TEXT,
  gc          TEXT,
  status      TEXT DEFAULT 'active',              -- active | complete | archived
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Categories within a project
CREATE TABLE categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID REFERENCES projects(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,                      -- "Flooring — Tile", "Lighting", etc.
  sort_order  INTEGER DEFAULT 0
);

-- Line items (core table)
CREATE TABLE items (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id          UUID REFERENCES projects(id) ON DELETE CASCADE,
  category_id         UUID REFERENCES categories(id) ON DELETE SET NULL,
  room                TEXT,
  product_name        TEXT NOT NULL,
  manufacturer        TEXT,
  vendor              TEXT,
  sku                 TEXT,
  product_url         TEXT,
  size                TEXT,
  finish              TEXT,
  room_sqft           NUMERIC,
  overage_pct         NUMERIC DEFAULT 15,
  sqft_per_unit       NUMERIC,
  unit_type           TEXT,                       -- "sqft/case", "sqft/piece", "box"
  units_needed        INTEGER,
  unit_price          NUMERIC,
  total_price         NUMERIC,
  is_substitution     BOOLEAN DEFAULT FALSE,
  substitution_note   TEXT,                       -- "Replaces Tilebar Santo Mountain Beige"
  original_product    TEXT,
  designer_notes      TEXT,
  sort_order          INTEGER DEFAULT 0,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Generated column: sqft with overage (Postgres 12+)
ALTER TABLE items ADD COLUMN sqft_with_overage NUMERIC
  GENERATED ALWAYS AS (room_sqft * (1 + COALESCE(overage_pct, 15) / 100.0)) STORED;

-- Product images (Supabase Storage paths)
CREATE TABLE item_images (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id      UUID REFERENCES items(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,                     -- bucket/path/filename.jpg
  is_primary   BOOLEAN DEFAULT FALSE,
  uploaded_by  TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Client approvals
CREATE TABLE item_approvals (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id     UUID REFERENCES items(id) ON DELETE CASCADE,
  status      TEXT DEFAULT 'pending',             -- pending | approved | flagged
  reviewer    TEXT,
  reviewed_at TIMESTAMPTZ,
  UNIQUE(item_id)
);

-- Order tracking (order person fills this in)
CREATE TABLE order_tracking (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id           UUID REFERENCES items(id) ON DELETE CASCADE,
  status            TEXT DEFAULT 'not_ordered',   -- not_ordered | ordered | in_transit | delivered | backordered
  po_number         TEXT,
  vendor_contact    TEXT,
  order_date        DATE,
  expected_delivery DATE,
  actual_delivery   DATE,
  qty_ordered       INTEGER,
  actual_unit_cost  NUMERIC,
  order_notes       TEXT,
  ordered_by        TEXT,
  updated_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(item_id)
);

-- Per-item comments / notes thread
CREATE TABLE item_notes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id     UUID REFERENCES items(id) ON DELETE CASCADE,
  author      TEXT NOT NULL,
  role        TEXT,                               -- designer | client | order_person
  body        TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── INDEXES ──────────────────────────────────────────────────────────────
CREATE INDEX idx_items_project ON items(project_id);
CREATE INDEX idx_items_category ON items(category_id);
CREATE INDEX idx_order_tracking_status ON order_tracking(status);
CREATE INDEX idx_item_approvals_status ON item_approvals(status);

-- ── UPDATED_AT TRIGGER ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_items_updated BEFORE UPDATE ON items
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_projects_updated BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_order_updated BEFORE UPDATE ON order_tracking
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
