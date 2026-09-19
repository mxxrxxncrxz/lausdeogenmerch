-- Laus Deo General Merchandise
-- Run this in Supabase SQL Editor before using the website.
create extension if not exists pgcrypto;

create table if not exists public.inventory (
  id uuid primary key default gen_random_uuid(),
  category text default '',
  item text not null,
  srp numeric(12,2) not null default 0,
  markup_price numeric(12,2) not null default 0,
  quantity integer not null default 0 check (quantity >= 0),
  low_stock_threshold integer not null default 5 check (low_stock_threshold >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  receipt_no text unique not null,
  total numeric(12,2) not null default 0,
  cashier_email text,
  created_at timestamptz not null default now()
);

create table if not exists public.transaction_items (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  inventory_id uuid references public.inventory(id) on delete set null,
  item_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null default 0
);

alter table public.inventory enable row level security;
alter table public.transactions enable row level security;
alter table public.transaction_items enable row level security;

drop policy if exists "inventory authenticated read" on public.inventory;
drop policy if exists "inventory authenticated write" on public.inventory;
drop policy if exists "transactions authenticated read" on public.transactions;
drop policy if exists "transaction_items authenticated read" on public.transaction_items;

create policy "inventory authenticated read" on public.inventory for select to authenticated using (true);
create policy "inventory authenticated write" on public.inventory for all to authenticated using (true) with check (true);
create policy "transactions authenticated read" on public.transactions for select to authenticated using (true);
create policy "transaction_items authenticated read" on public.transaction_items for select to authenticated using (true);

-- Sale RPC: validates stock, inserts receipt + line items, and decrements inventory
-- in one database transaction.
create or replace function public.complete_sale(p_items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sale_id uuid;
  v_receipt text;
  v_total numeric(12,2) := 0;
  v_item jsonb;
  v_inv inventory%rowtype;
  v_qty integer;
  v_price numeric(12,2);
  v_email text := coalesce((select auth.jwt()->>'email'),'');
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if jsonb_array_length(p_items) = 0 then raise exception 'Cart is empty'; end if;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_inv from inventory where id=(v_item->>'inventory_id')::uuid for update;
    if not found then raise exception 'Product not found'; end if;
    v_qty := (v_item->>'quantity')::integer;
    if v_qty <= 0 then raise exception 'Invalid quantity'; end if;
    if v_inv.quantity < v_qty then raise exception 'Insufficient stock for %', v_inv.item; end if;
    v_price := v_inv.markup_price;
    v_total := v_total + (v_price * v_qty);
  end loop;

  v_receipt := 'LD-' || to_char(now(),'YYYYMMDD-HH24MISS') || '-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,5));
  insert into transactions(receipt_no,total,cashier_email) values(v_receipt,v_total,v_email) returning id into v_sale_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_inv from inventory where id=(v_item->>'inventory_id')::uuid for update;
    v_qty := (v_item->>'quantity')::integer;
    insert into transaction_items(transaction_id,inventory_id,item_name,quantity,unit_price)
      values(v_sale_id,v_inv.id,v_inv.item,v_qty,v_inv.markup_price);
    update inventory set quantity=quantity-v_qty, updated_at=now() where id=v_inv.id;
  end loop;

  return jsonb_build_object('receipt_no',v_receipt,'total',v_total);
end;
$$;

revoke all on function public.complete_sale(jsonb) from public;
grant execute on function public.complete_sale(jsonb) to authenticated;

-- Optional: paste inventory rows from Excel here if you already have real stock data.
-- Example:
-- insert into public.inventory(category,item,srp,markup_price,quantity,low_stock_threshold)
-- values ('Grocery','Sample Item',10,12,25,5);
