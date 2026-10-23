alter table public.bookings add column if not exists source text not null default 'Sin registrar' check (source in ('Sin registrar','Instagram','Facebook','TikTok','WhatsApp','Recomendación','Otro'));
create table if not exists public.marketing_posts (id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade, title text not null check (char_length(trim(title)) between 1 and 200), network text not null check (network in ('Instagram','Facebook','TikTok','WhatsApp')), publish_date date not null, status text not null default 'Idea' check (status in ('Idea','Borrador','Programada','Publicada')), copy text not null default '', created_at timestamptz not null default now());
create index if not exists marketing_posts_owner_date_idx on public.marketing_posts(owner_id,publish_date);
alter table public.marketing_posts enable row level security;
revoke all on public.marketing_posts from anon;
grant select,insert,update,delete on public.marketing_posts to authenticated;
create policy "Owners manage their marketing posts" on public.marketing_posts for all to authenticated using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
