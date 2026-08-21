# 🚀 Neon Portfolio

An animated single-page portfolio with a **Hall of Fame** for certificates
(courses, hackathons, internships, achievements), backed by **Supabase** for real
authentication and cloud storage.

**Live site:** `https://bharath7115.github.io/portfolio/` ← after you deploy

| File | What it is |
|---|---|
| `index.html` | The entire site (HTML + CSS + JS, no build step) |
| `supabase-setup.sql` | **Run this once** in Supabase to create tables + security rules |
| `data.json` | Offline fallback / first-run seed content |
| `.gitignore` | Keeps private backups out of git |

---

## Setup (one time, ~5 minutes)

### 1. Create the database
Supabase Dashboard → **SQL Editor** → **New query** → paste all of
`supabase-setup.sql` → **Run**. You should see two tables with `rowsecurity = true`.

### 2. Create your owner account
Dashboard → **Authentication** → **Users** → **Add user** → **Create new user**:
- Email: `bharathk9828@gmail.com`
- Password: whatever you like
- ✅ **Auto Confirm User** (so you can sign in immediately)

### 3. Close public signup ⚠️
Dashboard → **Authentication** → **Sign In / Providers** → turn **off** "Allow new users to sign up".

Your project currently has signups **open**, which means anyone could create an account.
Your data is still safe without this step — every write rule is pinned to your email address —
but disabling signup stops strangers from creating accounts in your project at all.

### 4. Open the site
Open `index.html`, click the **🔒 lock icon**, sign in. On first sign-in with an empty
database the site seeds itself from `data.json`.

---

## Daily use
1. Click **🔒** → sign in.
2. Use the **✎ / ＋** buttons: **+ Add Certificate**, edit profile, skills, education, personal details.
3. Watch the **saved ✓** badge in the admin bar — that's it. **No publish step**: edits are live
   for everyone the moment they save, on every device.
4. Click **Sign out** when done.

Certificate images you upload go to the Supabase `certificates` storage bucket and are served
as normal image URLs (so the database stays small and pages load fast).

---

## How security actually works
- **Sign-in is real** — Supabase Auth, bcrypt-hashed passwords, JWT sessions, server-verified.
  Not a client-side password check.
- **Row Level Security** is enforced by Postgres, not the browser. Even with the site's key,
  an anonymous visitor can only *read* public content; writes require a JWT whose email
  equals `bharathk9828@gmail.com`.
- **Personal Details** live in a separate `portfolio_private` table with **no anonymous read
  policy at all** — they are never sent to visitors, and are cleared from this browser's cache
  when you sign out.
- **The publishable key in `index.html` is meant to be public.** That's Supabase's design;
  it identifies the project and carries no privileges of its own. Never put a
  `sb_secret_...` / service-role key in this file.

If you ever change your email, update it in **both** `supabase-setup.sql` (`is_owner()`)
and `index.html` (`OWNER_EMAIL`).

---

## Deploy free on GitHub Pages
```bash
git init && git branch -M main && git add . && git commit -m "Neon portfolio with Supabase auth"
```
Create an empty **public** repo named `portfolio` at <https://github.com/new> (no README/.gitignore), then:
```bash
git remote add origin https://github.com/Bharath7115/portfolio.git && git push -u origin main
```
Repo **Settings → Pages → Source:** *Deploy from a branch* → **main** / **`/ (root)`** → **Save**.

Live at `https://bharath7115.github.io/portfolio/`. Name the repo `Bharath7115.github.io`
instead for the shorter root URL. Also works as-is on Netlify, Vercel, Cloudflare Pages.

**Auth for pushing:** GitHub needs a Personal Access Token, not your account password. Create one
at <https://github.com/settings/tokens> (classic, `repo` scope) and paste it at the password prompt.

---

## Backup & recovery
- **Backup** (admin bar) downloads everything, including private details — keep that file to yourself.
- **Import** restores from a backup and saves it to the cloud.
- **Forgot password?** Use the link in the sign-in dialog to get a reset email.
- Offline or Supabase unreachable? The site falls back to its local cache, then `data.json`,
  and simply disables editing.

---
Vanilla HTML/CSS/JS + `@supabase/supabase-js` from CDN. No build step, no framework.
