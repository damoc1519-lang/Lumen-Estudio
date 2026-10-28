-- Editable units and coverage choices for studio-created packages.
alter table public.quote_catalog
 add column if not exists unit_label text not null default 'unidad' check (char_length(unit_label) between 1 and 24),
 add column if not exists coverage_hours integer[] not null default '{}';
create unique index if not exists quote_catalog_id_workspace_unique on public.quote_catalog(id,workspace_id);

create table public.quote_package_components (
 id uuid primary key default gen_random_uuid(),
 workspace_id uuid not null default public.current_workspace_id() references public.workspaces(id) on delete cascade,
 package_id uuid not null,
 catalog_item_id uuid not null,
 people integer not null default 1 check (people between 1 and 20),
 hours integer not null default 4 check (hours between 1 and 24),
 quantity integer not null default 1 check (quantity between 1 and 1000),
 unique(package_id,catalog_item_id),
 foreign key(package_id,workspace_id) references public.quote_catalog(id,workspace_id) on delete cascade,
 foreign key(catalog_item_id,workspace_id) references public.quote_catalog(id,workspace_id) on delete cascade
);
create index quote_package_components_workspace_package_idx on public.quote_package_components(workspace_id,package_id);
create index quote_package_components_item_workspace_idx on public.quote_package_components(catalog_item_id,workspace_id);
alter table public.quote_package_components enable row level security;
revoke all on public.quote_package_components from anon;
grant select,insert,update,delete on public.quote_package_components to authenticated;
create policy "Members read package content" on public.quote_package_components for select to authenticated
 using (workspace_id=(select public.current_workspace_id()));
create policy "Members add package content" on public.quote_package_components for insert to authenticated
 with check (workspace_id=(select public.current_workspace_id()));
create policy "Members update package content" on public.quote_package_components for update to authenticated
 using (workspace_id=(select public.current_workspace_id()))
 with check (workspace_id=(select public.current_workspace_id()));
create policy "Members delete package content" on public.quote_package_components for delete to authenticated
 using (workspace_id=(select public.current_workspace_id()));
