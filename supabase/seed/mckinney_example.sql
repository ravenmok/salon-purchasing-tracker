-- ============================================================
-- Example seed: Hair Salon McKinney (2026)
-- Run after migrations to pre-populate a sample project
-- ============================================================

INSERT INTO projects (name, client_name, location, designer)
VALUES ('Hair Salon McKinney', 'Devon', 'McKinney, TX', 'Caitlin')
RETURNING id;

-- After inserting, capture the project ID and insert categories + items
-- (In practice, use the app UI or a script with the returned UUID)
