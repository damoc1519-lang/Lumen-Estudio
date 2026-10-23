-- Shared Playart workspace for accounts that existed when this migration ran.
-- Future signups are not enrolled automatically.
create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);
create table if not exists public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','member')),
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);
insert into public.workspaces(name)
select 'Playart'
where not exists (select 1 from public.workspaces where name = 'Playart');

alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
create policy "Members can read their own memberships"
on public.workspace_members for select to authenticated
using (user_id = (select auth.uid()));
create policy "Members can read their workspace"
on public.workspaces for select to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = workspaces.id and wm.user_id = (select auth.uid())
));

insert into public.workspace_members(workspace_id, user_id, role)
select w.id, u.id, case when u.rn = 1 then 'owner' else 'member' end
from (
  select id, row_number() over (order by created_at, id) rn
  from auth.users where deleted_at is null
) u
cross join lateral (
  select id from public.workspaces where name = 'Playart' order by created_at limit 1
) w
on conflict (user_id) do nothing;

create or replace function public.current_workspace_id()
returns uuid
language sql stable security invoker set search_path = public
as $$
  select workspace_id from public.workspace_members
  where user_id = (select auth.uid()) limit 1
$$;
revoke all on function public.current_workspace_id() from public;
grant execute on function public.current_workspace_id() to authenticated;

do $$
declare t text; p record;
begin
  foreach t in array array['bookings', 'marketing_posts', 'leads'] loop
    execute format('alter table public.%I add column if not exists workspace_id uuid references public.workspaces(id)', t);
    execute format('update public.%I set workspace_id=(select id from public.workspaces where name=''Playart'' order by created_at limit 1) where workspace_id is null', t);
    execute format('alter table public.%I alter column workspace_id set default public.current_workspace_id()', t);
    execute format('alter table public.%I alter column workspace_id set not null', t);
    execute format('create index if not exists %I on public.%I(workspace_id)', t || '_workspace_id_idx', t);
    execute format('alter table public.%I enable row level security', t);
    for p in select policyname from pg_policies where schemaname='public' and tablename=t loop
      execute format('drop policy %I on public.%I', p.policyname, t);
    end loop;
    if t = 'bookings' then
      execute 'create policy "Workspace members can read bookings" on public.bookings for select to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=bookings.workspace_id and wm.user_id=(select auth.uid())))';
      execute 'create policy "Workspace members can create bookings" on public.bookings for insert to authenticated with check (exists (select 1 from public.workspace_members wm where wm.workspace_id=bookings.workspace_id and wm.user_id=(select auth.uid())))';
      execute 'create policy "Workspace members can update bookings" on public.bookings for update to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=bookings.workspace_id and wm.user_id=(select auth.uid()))) with check (exists (select 1 from public.workspace_members wm where wm.workspace_id=bookings.workspace_id and wm.user_id=(select auth.uid())))';
      execute 'create policy "Workspace members can delete bookings" on public.bookings for delete to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=bookings.workspace_id and wm.user_id=(select auth.uid())))';
    else
      execute format('create policy %I on public.%I for all to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=%I.workspace_id and wm.user_id=(select auth.uid()))) with check (exists (select 1 from public.workspace_members wm where wm.workspace_id=%I.workspace_id and wm.user_id=(select auth.uid())))', 'Workspace members manage ' || t, t, t, t);
    end if;
  end loop;
end $$;
