# MBR2 Scope of Works FY27 — Supabase + installable app

## 1. Supabase (≈10 min)
1. Create a free project at supabase.com.
2. SQL Editor → paste all of `supabase/schema.sql` → Run.
3. Authentication → Users → **Add user** (email + password, tick *Auto confirm*) for the manager and each staff member.
4. Back in SQL Editor, link each user to a staff name (exactly as shown in the app; manager uses `Manager`) using the commented examples at the bottom of schema.sql.
5. Project Settings → API: copy **Project URL** and **anon public key** into `config.js`.

## 2. Host the folder (HTTPS needed for install)
Upload this whole folder to any static host: Netlify Drop (drag-and-drop at app.netlify.com/drop), Cloudflare Pages, GitHub Pages, or Vercel. (Supabase Storage can't serve web pages.)

## 3. Install
- **Phone (Android/Chrome):** open the link → menu → *Install app* (or tap the green **Install** button in the app).
- **iPhone (Safari):** open the link → Share → *Add to Home Screen*.
- **Computer (Chrome/Edge):** open the link → click the install icon in the address bar or the **Install** button.

## Notes
- Staff can edit only their own lines; the manager can edit all (enforced by the database, not just the app).
- Works offline; unsaved edits queue and sync when back online. Live updates arrive in real time.
- After changing any file, bump `V` in `sw.js` (e.g. `mbr2-v2`) so devices pick up the update.
- Existing data in the old Apps Script sheet is not migrated; start fresh or ask for an import script.
