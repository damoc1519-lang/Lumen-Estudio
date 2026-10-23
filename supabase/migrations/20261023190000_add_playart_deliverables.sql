create table public.deliverables (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null default public.current_workspace_id() references public.workspaces(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 200),
  client_name text not null default '' check (char_length(client_name) <= 160),
  due_date date not null,
  notes text not null default '' check (char_length(notes) <= 2000),
  status text not null default 'Pendiente' check (status in ('Pendiente', 'Entregado')),
  created_at timestamptz not null default now()
);

create index deliverables_workspace_due_date_idx
on public.deliverables (workspace_id, due_date, created_at);

alter table public.deliverables enable row level security;
grant select, insert, update, delete on public.deliverables to authenticated;

create policy "Workspace members can read deliverables"
on public.deliverables for select to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = deliverables.workspace_id
    and wm.user_id = (select auth.uid())
));

create policy "Workspace members can create deliverables"
on public.deliverables for insert to authenticated
with check (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = deliverables.workspace_id
    and wm.user_id = (select auth.uid())
));

create policy "Workspace members can update deliverables"
on public.deliverables for update to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = deliverables.workspace_id
    and wm.user_id = (select auth.uid())
))
with check (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = deliverables.workspace_id
    and wm.user_id = (select auth.uid())
));

create policy "Workspace members can delete deliverables"
on public.deliverables for delete to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = deliverables.workspace_id
    and wm.user_id = (select auth.uid())
));
