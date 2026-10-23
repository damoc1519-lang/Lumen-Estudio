create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  client_name text not null check (char_length(trim(client_name)) between 1 and 160),
  session_type text not null default 'Otro' check (char_length(session_type) between 1 and 80),
  session_date date not null,
  session_time time without time zone not null,
  place text not null default 'Por definir' check (char_length(place) <= 240),
  price numeric(10,2) not null default 0 check (price >= 0),
  paid numeric(10,2) not null default 0 check (paid >= 0),
  status text not null default 'Confirmada' check (status in ('Confirmada','Por confirmar','Pagada','Cancelada')),
  color text not null default 'peach' check (color in ('peach','sage','lavender','blue')),
  created_at timestamptz not null default now()
);

create index bookings_owner_date_idx on public.bookings (owner_id, session_date, session_time);

alter table public.bookings enable row level security;

revoke all on public.bookings from anon;
grant select, insert, update, delete on public.bookings to authenticated;

create policy "Owners can read their bookings"
on public.bookings for select to authenticated
using ((select auth.uid()) = owner_id);

create policy "Owners can create their bookings"
on public.bookings for insert to authenticated
with check ((select auth.uid()) = owner_id);

create policy "Owners can update their bookings"
on public.bookings for update to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "Owners can delete their bookings"
on public.bookings for delete to authenticated
using ((select auth.uid()) = owner_id);
