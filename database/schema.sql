-- Execute uma vez no SQL Editor do Supabase.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.monthly_income (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reference_month date not null check (extract(day from reference_month) = 1),
  salary_amount numeric(14,2) not null default 0 check (salary_amount >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, reference_month)
);

create table if not exists public.additional_income (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  description text not null check (length(trim(description)) between 1 and 120),
  amount numeric(14,2) not null check (amount > 0),
  received_on date not null,
  reference_month date not null check (extract(day from reference_month) = 1),
  check (date_trunc('month', received_on)::date = reference_month),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  description text not null check (length(trim(description)) between 1 and 140),
  amount numeric(14,2) not null check (amount > 0),
  category text not null check (length(trim(category)) between 1 and 80),
  expense_type text not null check (expense_type in ('fixed','variable')),
  spent_on date not null,
  notes text check (notes is null or length(notes) <= 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists additional_income_user_month_idx on public.additional_income(user_id, reference_month);
create index if not exists expenses_user_date_idx on public.expenses(user_id, spent_on desc);
create index if not exists expenses_user_category_idx on public.expenses(user_id, category);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists monthly_income_updated_at on public.monthly_income;
create trigger monthly_income_updated_at before update on public.monthly_income for each row execute function public.set_updated_at();
drop trigger if exists additional_income_updated_at on public.additional_income;
create trigger additional_income_updated_at before update on public.additional_income for each row execute function public.set_updated_at();
drop trigger if exists expenses_updated_at on public.expenses;
create trigger expenses_updated_at before update on public.expenses for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name, email)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name',''), new.email)
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.monthly_income enable row level security;
alter table public.additional_income enable row level security;
alter table public.expenses enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using ((select auth.uid()) = id);
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

drop policy if exists "monthly_income_owner_all" on public.monthly_income;
create policy "monthly_income_owner_all" on public.monthly_income for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "additional_income_owner_all" on public.additional_income;
create policy "additional_income_owner_all" on public.additional_income for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "expenses_owner_all" on public.expenses;
create policy "expenses_owner_all" on public.expenses for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.monthly_income, public.additional_income, public.expenses to authenticated;
