# Laus Deo General Merchandise — Inventory & POS

This package is a Supabase-backed, multi-device inventory/POS website based on the uploaded `RECORDS(2).xlsx` workbook.

## Included
- Laus Deo logo extracted from the workbook
- Dashboard
- Inventory CRUD
- 50% mark-up calculation matching the workbook (`ROUNDUP(SRP*150%,0)`)
- Low-stock alerts
- Sales/POS cart
- Atomic cloud sale processing (stock is decremented in the database)
- Sales/transactions history
- Printable receipts
- Excel download with INVENTORY + TRANSACTIONS sheets
- Supabase Auth login
- Responsive desktop/mobile layout
- Workbook-inspired palette: yellow `#FFCA08`, orange `#F8931D`, brown `#39302A`, cream/off-white

## One-time Supabase setup
1. Open your Supabase project SQL Editor.
2. Run `schema.sql`.
3. In Supabase Authentication, create the staff/admin user(s) you want to use for login.
4. Deploy the contents of this folder to Netlify, Vercel, GitHub Pages (with appropriate configuration), or another static host.
5. Open the deployed site and sign in with the Supabase Auth email/password.

The website is configured for your Supabase project:
`https://tcpfxwbrvhsxzcgxitbw.supabase.co`

The browser key included in `index.html` is a publishable/anon-style key and is intended for frontend use. Never put a Supabase `service_role`/secret key in this site.

## Excel
The uploaded workbook is a template: the INVENTORY rows contain formulas and formatting, but no populated item names/quantities. The website therefore starts with an empty cloud inventory until real products are entered/imported.

Use **Download Excel** at any time to export the current cloud records. This creates:
- `INVENTORY`: CATEGORY, ITEM, SRP, MARK-UP PRICE, QUANTITY, STATUS
- `TRANSACTIONS`: DATE, RECEIPT, ITEM, QUANTITY, UNIT PRICE, TOTAL, CASHIER

## Important
The site is intentionally cloud-first: inventory and completed sales are stored in Supabase so multiple devices see the same records. Browser localStorage is not used as the inventory database.
