create table if not exists public.leads (id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade, client_name text not null check (char_length(trim(client_name)) between 1 and 160), phone text not null default '', service text not null default '', source text not null default 'Sin registrar' check (source in ('Sin registrar','Instagram','Facebook','TikTok','WhatsApp','Recomendación','Otro')), status text not null default 'Nueva' check (status in ('Nueva','Contactada','Cotización enviada','Seguimiento','Reservó','No concretada')), contact_date date not null default current_date, follow_up_date date, quoted_amount numeric(10,2) not null default 0 check (quoted_amount >= 0), notes text not null default '', lost_reason text not null default '', booking_id uuid references public.bookings(id) on delete set null, created_at timestamptz not null default now());
create index if not exists leads_owner_followup_idx on public.leads(owner_id,follow_up_date);
create index if not exists leads_owner_status_idx on public.leads(owner_id,status);
alter table public.leads enable row level security;
revoke all on public.leads from anon;
grant select,insert,update,delete on public.leads to authenticated;
create policy "Owners manage their leads" on public.leads for all to authenticated using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
alter publication supabase_realtime add table public.leads;
