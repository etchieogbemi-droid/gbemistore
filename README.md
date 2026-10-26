# GBEMI’s STORE

A blue-and-pink Supabase ecommerce/order-management application.

## Setup
1. `npm install`
2. Copy `.env.example` to `.env`
3. Add your Supabase URL and anon/publishable key.
4. Run `supabase/schema.sql` in the Supabase SQL Editor.
5. Create two Storage buckets named `product-images` and `store-assets`, both public.
6. Put `store-hero.jpg` and `store-logo.png` in `public/`.
7. `npm run dev`

## Admin
Create a normal Supabase Auth user first. Then, in the SQL editor, promote that user's UUID:
`update public.profiles set role='admin' where id='USER_UUID';`

Never put a Supabase service-role key in this project or GitHub.

## Order workflow
Fresh Order / Send Account Details → Received Payment → Processing → On Its Way (3 Days) → Pickup Station Details → Completed.

Customers can create requests and view their own orders. Only admins can confirm payment or advance order status.

## Receipts
The admin dashboard includes a print-friendly receipt window for selected orders, including customer name, phone, location, product code, quantity and amount.
