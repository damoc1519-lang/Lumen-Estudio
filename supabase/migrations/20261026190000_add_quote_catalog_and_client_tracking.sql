create unique index if not exists bookings_id_workspace_unique
  on public.bookings (id, workspace_id);

create table public.quote_catalog (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null default public.current_workspace_id()
    references public.workspaces(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 120),
  description text not null default '' check (char_length(description) <= 300),
  kind text not null check (kind in ('package','extra','zone')),
  duration_hours integer check (duration_hours is null or duration_hours between 1 and 48),
  price numeric(10,2) not null default 0 check (price >= 0),
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (workspace_id, kind, name)
);

create index quote_catalog_workspace_order_idx
  on public.quote_catalog (workspace_id, active, sort_order, name);

alter table public.quote_catalog enable row level security;
revoke all on public.quote_catalog from anon;
grant select, insert, update, delete on public.quote_catalog to authenticated;
create policy "Workspace members read quote catalog"
  on public.quote_catalog for select to authenticated
  using (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members add quote catalog"
  on public.quote_catalog for insert to authenticated
  with check (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members update quote catalog"
  on public.quote_catalog for update to authenticated
  using (workspace_id = (select public.current_workspace_id()))
  with check (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members delete quote catalog"
  on public.quote_catalog for delete to authenticated
  using (workspace_id = (select public.current_workspace_id()));

create table public.client_projects (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null default public.current_workspace_id()
    references public.workspaces(id) on delete cascade,
  booking_id uuid not null,
  client_name text not null check (char_length(trim(client_name)) between 1 and 160),
  title text not null check (char_length(trim(title)) between 1 and 200),
  event_date date not null,
  tracking_token_hash text not null unique check (tracking_token_hash ~ '^[a-f0-9]{64}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (booking_id),
  unique (id, workspace_id),
  foreign key (booking_id, workspace_id)
    references public.bookings(id, workspace_id) on delete cascade
);

create index client_projects_workspace_event_date_idx
  on public.client_projects (workspace_id, event_date desc);

alter table public.client_projects enable row level security;
revoke all on public.client_projects from anon;
grant select, insert, update, delete on public.client_projects to authenticated;
create policy "Workspace members read client projects"
  on public.client_projects for select to authenticated
  using (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members create client projects"
  on public.client_projects for insert to authenticated
  with check (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members update client projects"
  on public.client_projects for update to authenticated
  using (workspace_id = (select public.current_workspace_id()))
  with check (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members delete client projects"
  on public.client_projects for delete to authenticated
  using (workspace_id = (select public.current_workspace_id()));

create table public.client_project_stages (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null,
  workspace_id uuid not null default public.current_workspace_id(),
  title text not null check (char_length(trim(title)) between 1 and 120),
  status text not null default 'Pendiente'
    check (status in ('Pendiente','En proceso','Completado')),
  sort_order integer not null default 0,
  updated_at timestamptz not null default now(),
  foreign key (project_id, workspace_id)
    references public.client_projects(id, workspace_id) on delete cascade,
  unique (project_id, sort_order)
);

create index client_project_stages_project_order_idx
  on public.client_project_stages (project_id, sort_order);

alter table public.client_project_stages enable row level security;
revoke all on public.client_project_stages from anon;
grant select, insert, update, delete on public.client_project_stages to authenticated;
create policy "Workspace members read project stages"
  on public.client_project_stages for select to authenticated
  using (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members create project stages"
  on public.client_project_stages for insert to authenticated
  with check (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members update project stages"
  on public.client_project_stages for update to authenticated
  using (workspace_id = (select public.current_workspace_id()))
  with check (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members delete project stages"
  on public.client_project_stages for delete to authenticated
  using (workspace_id = (select public.current_workspace_id()));
