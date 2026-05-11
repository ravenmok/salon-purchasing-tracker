# Salon Purchasing Tracker

A portable, role-based purchasing schedule app for interior design and salon build-out projects. Built by Lighthaus / Raven Home Co.

## What it does

One URL, three views — same data, different lenses:

| Role | What they see | What they can do |
|------|--------------|-----------------|
| **Designer** | Full product cards with specs, photos | Edit sqft, upload photos, add items, leave notes |
| **Client** | Same visual cards, clean layout | Approve ✓ or Flag ⚑ each item, add questions |
| **Order Person** | Dense table — all 27+ items | Set status, enter PO#, vendor contact, dates, export CSV |

Progress bar and cost pills update live based on role (confirmed vs. approved).

---

## Quick start (static version — no backend)

1. Open `clients/mckinney_2026/HAV_McKinney_App.html` in any browser
2. All state (checkboxes, notes, approvals, order tracking) persists in `localStorage`
3. Switch roles with the tabs in the header
4. Order person: use **Export CSV** to get a clean ordering spreadsheet

No server, no login, no dependencies. Works offline. Share the HTML file directly.

---

## Full version (Supabase backend)

For multi-user, real-time, persistent-across-devices:

### 1. Create a Supabase project
```
supabase.com → New Project
```

### 2. Run migrations
```bash
# In Supabase SQL Editor, run in order:
supabase/migrations/001_initial_schema.sql
supabase/migrations/002_rls_policies.sql
```

### 3. Configure env
```bash
cp .env.example .env
# Fill in your Supabase URL and anon key
```

### 4. Enable Storage bucket
In Supabase dashboard → Storage → New bucket: `product-images` (public read, auth write)

### 5. Set user roles
In Supabase Auth → Users → Edit user → app_metadata:
```json
{ "role": "designer" }   // or "client" or "order_person"
```

---

## File structure

```
salon-purchasing-tracker/
├── clients/
│   └── mckinney_2026/          ← Example: Hair Salon McKinney
│       ├── HAV_McKinney_App.html        (interactive tracker)
│       ├── HAV_McKinney_Schedule_PRINT.html  (printable schedule)
│       └── HAV_McKinney_Purchasing_Schedule.csv
├── supabase/
│   ├── migrations/
│   │   ├── 001_initial_schema.sql      (projects, items, order_tracking, approvals)
│   │   └── 002_rls_policies.sql        (role-based row security)
│   └── seed/
│       └── mckinney_example.sql
├── .env.example
└── README.md
```

---

## Starting a new client project

1. Duplicate `clients/mckinney_2026/HAV_McKinney_App.html`
2. Find and replace `McKinney` with the new client name
3. Update the `ALL_ITEMS` array in the `<script>` block with the new schedule
4. Update `COST_ITEMS` with items that have confirmed pricing
5. Deliver the HTML file — client opens it in browser, no install needed

For the Supabase version: `INSERT INTO projects (name, client_name, ...)` and build items via the UI.

---

## Schema overview

```
projects → categories → items
                          ↓
                    item_images       (Supabase Storage)
                    item_approvals    (client: approved | flagged)
                    order_tracking    (PO#, dates, status)
                    item_notes        (threaded comments)
```

---

Built with: vanilla HTML/CSS/JS · Supabase (Postgres + Storage + Auth) · localStorage fallback
