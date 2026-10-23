create table public.equipment_inventory (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null default public.current_workspace_id() references public.workspaces(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 160),
  category text not null default 'General' check (char_length(category) <= 60),
  quantity integer not null default 1 check (quantity between 1 and 999),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (id, workspace_id)
);
create index equipment_inventory_workspace_active_idx on public.equipment_inventory(workspace_id, active, category, name);
alter table public.equipment_inventory enable row level security;
grant select, insert, update, delete on public.equipment_inventory to authenticated;
create policy "Workspace members can read inventory" on public.equipment_inventory for select to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=equipment_inventory.workspace_id and wm.user_id=(select auth.uid())));
create policy "Workspace members can create inventory" on public.equipment_inventory for insert to authenticated with check (exists (select 1 from public.workspace_members wm where wm.workspace_id=equipment_inventory.workspace_id and wm.user_id=(select auth.uid())));
create policy "Workspace members can update inventory" on public.equipment_inventory for update to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=equipment_inventory.workspace_id and wm.user_id=(select auth.uid()))) with check (exists (select 1 from public.workspace_members wm where wm.workspace_id=equipment_inventory.workspace_id and wm.user_id=(select auth.uid())));
create policy "Workspace members can delete inventory" on public.equipment_inventory for delete to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=equipment_inventory.workspace_id and wm.user_id=(select auth.uid())));

create table public.event_equipment_checklists (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null default public.current_workspace_id() references public.workspaces(id) on delete cascade,
  event_name text not null check (char_length(trim(event_name)) between 1 and 200),
  event_date date not null,
  status text not null default 'Pendiente' check (status in ('Pendiente', 'Completada')),
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (id, workspace_id)
);
create index event_equipment_checklists_workspace_date_idx on public.event_equipment_checklists(workspace_id, event_date desc, created_at desc);
alter table public.event_equipment_checklists enable row level security;
grant select, insert, update, delete on public.event_equipment_checklists to authenticated;
create policy "Workspace members can read event checklists" on public.event_equipment_checklists for select to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=event_equipment_checklists.workspace_id and wm.user_id=(select auth.uid())));
create policy "Workspace members can create event checklists" on public.event_equipment_checklists for insert to authenticated with check (exists (select 1 from public.workspace_members wm where wm.workspace_id=event_equipment_checklists.workspace_id and wm.user_id=(select auth.uid())));
create policy "Workspace members can update event checklists" on public.event_equipment_checklists for update to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=event_equipment_checklists.workspace_id and wm.user_id=(select auth.uid()))) with check (exists (select 1 from public.workspace_members wm where wm.workspace_id=event_equipment_checklists.workspace_id and wm.user_id=(select auth.uid())));
create policy "Workspace members can delete event checklists" on public.event_equipment_checklists for delete to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=event_equipment_checklists.workspace_id and wm.user_id=(select auth.uid())));

create table public.event_equipment_checklist_items (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null default public.current_workspace_id() references public.workspaces(id) on delete cascade,
  checklist_id uuid not null,
  item_name text not null check (char_length(trim(item_name)) between 1 and 160),
  category text not null default 'General' check (char_length(category) <= 60),
  quantity integer not null default 1 check (quantity between 1 and 999),
  is_checked boolean not null default false,
  checked_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (checklist_id, workspace_id) references public.event_equipment_checklists(id, workspace_id) on delete cascade
);
create index event_equipment_checklist_items_parent_idx on public.event_equipment_checklist_items(workspace_id, checklist_id, category, item_name);
alter table public.event_equipment_checklist_items enable row level security;
grant select, insert, update, delete on public.event_equipment_checklist_items to authenticated;
create policy "Workspace members can read checklist items" on public.event_equipment_checklist_items for select to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=event_equipment_checklist_items.workspace_id and wm.user_id=(select auth.uid())));
create policy "Workspace members can create checklist items" on public.event_equipment_checklist_items for insert to authenticated with check (exists (select 1 from public.workspace_members wm where wm.workspace_id=event_equipment_checklist_items.workspace_id and wm.user_id=(select auth.uid())));
create policy "Workspace members can update checklist items" on public.event_equipment_checklist_items for update to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=event_equipment_checklist_items.workspace_id and wm.user_id=(select auth.uid()))) with check (exists (select 1 from public.workspace_members wm where wm.workspace_id=event_equipment_checklist_items.workspace_id and wm.user_id=(select auth.uid())));
create policy "Workspace members can delete checklist items" on public.event_equipment_checklist_items for delete to authenticated using (exists (select 1 from public.workspace_members wm where wm.workspace_id=event_equipment_checklist_items.workspace_id and wm.user_id=(select auth.uid())));

create or replace function public.create_event_equipment_checklist(p_event_name text, p_event_date date)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare wid uuid := public.current_workspace_id(); checklist uuid;
begin
  if wid is null then raise exception 'No tienes acceso al espacio Playart'; end if;
  if char_length(trim(p_event_name)) not between 1 and 200 then raise exception 'Escribe el nombre del evento'; end if;
  if p_event_date is null then raise exception 'Indica la fecha del evento'; end if;
  insert into public.event_equipment_checklists(workspace_id,event_name,event_date)
  values (wid,trim(p_event_name),p_event_date) returning id into checklist;
  insert into public.event_equipment_checklist_items(workspace_id,checklist_id,item_name,category,quantity)
  select wid,checklist,i.name,i.category,i.quantity
  from public.equipment_inventory i
  where i.workspace_id=wid and i.active=true
  order by i.category,i.name;
  return checklist;
end $$;
revoke all on function public.create_event_equipment_checklist(text,date) from public, anon;
grant execute on function public.create_event_equipment_checklist(text,date) to authenticated;

do $$
declare t text;
begin
  foreach t in array array['equipment_inventory','event_equipment_checklists','event_equipment_checklist_items'] loop
    if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
      execute format('alter publication supabase_realtime add table public.%I',t);
    end if;
  end loop;
end $$;
