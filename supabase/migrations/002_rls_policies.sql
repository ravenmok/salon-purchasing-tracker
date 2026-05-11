-- ============================================================
-- Row Level Security — Role-based access
-- Roles: designer | client | order_person
-- Pass role via JWT custom claim: app_metadata.role
-- ============================================================

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_notes ENABLE ROW LEVEL SECURITY;

-- Helper: extract role from JWT
CREATE OR REPLACE FUNCTION auth_role() RETURNS TEXT AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'role',
    (current_setting('request.jwt.claims', true)::json->'app_metadata'->>'role')
  );
$$ LANGUAGE sql STABLE;

-- ── PROJECTS ─────────────────────────────────────────────────────────────
-- Everyone in the project can read; only designer can write
CREATE POLICY "read_projects" ON projects FOR SELECT USING (true);
CREATE POLICY "designer_write_projects" ON projects FOR ALL
  USING (auth_role() = 'designer') WITH CHECK (auth_role() = 'designer');

-- ── ITEMS ─────────────────────────────────────────────────────────────────
CREATE POLICY "read_items" ON items FOR SELECT USING (true);
CREATE POLICY "designer_write_items" ON items FOR INSERT UPDATE DELETE
  USING (auth_role() = 'designer') WITH CHECK (auth_role() = 'designer');

-- ── IMAGES ────────────────────────────────────────────────────────────────
CREATE POLICY "read_images" ON item_images FOR SELECT USING (true);
CREATE POLICY "designer_write_images" ON item_images FOR INSERT UPDATE DELETE
  USING (auth_role() = 'designer') WITH CHECK (auth_role() = 'designer');

-- ── APPROVALS — client can read+write their own ───────────────────────────
CREATE POLICY "read_approvals" ON item_approvals FOR SELECT USING (true);
CREATE POLICY "client_write_approvals" ON item_approvals FOR INSERT UPDATE
  USING (auth_role() IN ('client','designer'))
  WITH CHECK (auth_role() IN ('client','designer'));

-- ── ORDER TRACKING — order_person can read+write ──────────────────────────
CREATE POLICY "read_order_tracking" ON order_tracking FOR SELECT USING (true);
CREATE POLICY "order_write_tracking" ON order_tracking FOR INSERT UPDATE
  USING (auth_role() IN ('order_person','designer'))
  WITH CHECK (auth_role() IN ('order_person','designer'));

-- ── NOTES — anyone can add notes ──────────────────────────────────────────
CREATE POLICY "read_notes" ON item_notes FOR SELECT USING (true);
CREATE POLICY "anyone_write_notes" ON item_notes FOR INSERT
  WITH CHECK (true);
