create extension if not exists pgcrypto;

create type public.user_role as enum ('customer','admin');
create type public.order_status as enum ('fresh','paid','processing','on_way','pickup','completed');

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null,
 phone text not null,
 email text not null,
 location text not null,
 role public.user_role not null default 'customer',
 created_at timestamptz not null default now()
);

create table if not exists public.products (
 id uuid primary key default gen_random_uuid(),
 code text unique not null,
 name text not null,
 description text not null default '',
 price numeric(12,2) not null check(price>=0),
 stock_quantity integer not null default 0 check(stock_quantity>=0),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table if not exists public.product_images (
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.products(id) on delete cascade,
 image_url text not null,
 sort_order integer not null default 0,
 created_at timestamptz not null default now()
);

create table if not exists public.consumer_requests (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references public.profiles(id) on delete cascade,
 product_id uuid not null references public.products(id) on delete restrict,
 quantity integer not null check(quantity>0),
 note text default '',
 status text not null default 'pending',
 order_id uuid,
 created_at timestamptz not null default now()
);

create table if not exists public.orders (
 id uuid primary key default gen_random_uuid(),
 order_number text unique not null default ('GBS-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8))),
 customer_id uuid not null references public.profiles(id) on delete restrict,
 status public.order_status not null default 'fresh',
 total_amount numeric(12,2) not null default 0,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

alter table public.consumer_requests drop constraint if exists consumer_requests_order_id_fkey;
alter table public.consumer_requests add constraint consumer_requests_order_id_fkey foreign key(order_id) references public.orders(id) on delete set null;

create table if not exists public.order_items (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete cascade,
 product_id uuid not null references public.products(id) on delete restrict,
 quantity integer not null check(quantity>0),
 amount numeric(12,2) not null check(amount>=0)
);

create table if not exists public.order_status_history (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete cascade,
 status public.order_status not null,
 changed_by uuid references public.profiles(id),
 created_at timestamptz not null default now()
);

create table if not exists public.payment_details (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete cascade,
 details text not null,
 sent_by uuid references public.profiles(id),
 created_at timestamptz not null default now()
);

create table if not exists public.pickup_details (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete cascade,
 station text not null,
 phone text not null default '',
 sent_by uuid references public.profiles(id),
 created_at timestamptz not null default now()
);

create table if not exists public.messages (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete cascade,
 sender_id uuid not null references public.profiles(id) on delete cascade,
 message text not null,
 created_at timestamptz not null default now()
);

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,full_name,phone,email,location) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','Customer'),coalesce(new.raw_user_meta_data->>'phone',''),new.email,coalesce(new.raw_user_meta_data->>'location',''));
 return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.consumer_requests enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;
alter table public.payment_details enable row level security;
alter table public.pickup_details enable row level security;
alter table public.messages enable row level security;

create policy "profiles own or admin" on public.profiles for select using(id=auth.uid() or public.is_admin());
create policy "profiles own update" on public.profiles for update using(id=auth.uid() or public.is_admin()) with check(id=auth.uid() or public.is_admin());
create policy "profiles insert self" on public.profiles for insert with check(id=auth.uid());

create policy "products public read" on public.products for select using(true);
create policy "products admin write" on public.products for all using(public.is_admin()) with check(public.is_admin());
create policy "images public read" on public.product_images for select using(true);
create policy "images admin write" on public.product_images for all using(public.is_admin()) with check(public.is_admin());

create policy "requests own/admin read" on public.consumer_requests for select using(customer_id=auth.uid() or public.is_admin());
create policy "requests customer create" on public.consumer_requests for insert with check(customer_id=auth.uid());
create policy "requests admin update" on public.consumer_requests for update using(public.is_admin()) with check(public.is_admin());

create policy "orders own/admin read" on public.orders for select using(customer_id=auth.uid() or public.is_admin());
create policy "orders customer create" on public.orders for insert with check(customer_id=auth.uid() or public.is_admin());
create policy "orders admin update" on public.orders for update using(public.is_admin()) with check(public.is_admin());

create policy "items own/admin read" on public.order_items for select using(exists(select 1 from orders o where o.id=order_id and (o.customer_id=auth.uid() or public.is_admin())));
create policy "items customer/admin insert" on public.order_items for insert with check(exists(select 1 from orders o where o.id=order_id and (o.customer_id=auth.uid() or public.is_admin())));
create policy "items admin update" on public.order_items for update using(public.is_admin()) with check(public.is_admin());

create policy "history own/admin read" on public.order_status_history for select using(exists(select 1 from orders o where o.id=order_id and (o.customer_id=auth.uid() or public.is_admin())));
create policy "history admin insert" on public.order_status_history for insert with check(public.is_admin());

create policy "payment own/admin read" on public.payment_details for select using(exists(select 1 from orders o where o.id=order_id and (o.customer_id=auth.uid() or public.is_admin())));
create policy "payment admin insert" on public.payment_details for insert with check(public.is_admin());

create policy "pickup own/admin read" on public.pickup_details for select using(exists(select 1 from orders o where o.id=order_id and (o.customer_id=auth.uid() or public.is_admin())));
create policy "pickup admin insert" on public.pickup_details for insert with check(public.is_admin());

create policy "messages own/admin read" on public.messages for select using(exists(select 1 from orders o where o.id=order_id and (o.customer_id=auth.uid() or public.is_admin())));
create policy "messages customer/admin insert" on public.messages for insert with check(sender_id=auth.uid() and exists(select 1 from orders o where o.id=order_id and (o.customer_id=auth.uid() or public.is_admin())));

-- Storage policies for product images. Create the bucket in Supabase Storage first.
insert into storage.buckets(id,name,public) values('product-images','product-images',true) on conflict(id) do nothing;
create policy "public product images" on storage.objects for select using(bucket_id='product-images');
create policy "admin product image upload" on storage.objects for insert with check(bucket_id='product-images' and public.is_admin());
create policy "admin product image update" on storage.objects for update using(bucket_id='product-images' and public.is_admin()) with check(bucket_id='product-images' and public.is_admin());
create policy "admin product image delete" on storage.objects for delete using(bucket_id='product-images' and public.is_admin());

-- Automatic updated_at.
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
drop trigger if exists products_touch on public.products;
create trigger products_touch before update on public.products for each row execute procedure public.touch_updated_at();
drop trigger if exists orders_touch on public.orders;
create trigger orders_touch before update on public.orders for each row execute procedure public.touch_updated_at();