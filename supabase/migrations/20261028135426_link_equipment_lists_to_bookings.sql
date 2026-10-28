-- A checklist can be attached to a registered event. Legacy manual lists stay intact.
alter table public.event_equipment_checklists add column booking_id uuid;
alter table public.event_equipment_checklists add constraint event_equipment_checklists_booking_workspace_fkey
 foreign key (booking_id, workspace_id) references public.bookings(id, workspace_id) on delete cascade;
alter table public.event_equipment_checklists add constraint event_equipment_checklists_booking_unique unique (booking_id);
create index event_equipment_checklists_booking_workspace_idx
 on public.event_equipment_checklists(booking_id, workspace_id) where booking_id is not null;

create function public.create_event_equipment_checklist_for_booking(p_booking_id uuid)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare wid uuid := public.current_workspace_id();
        booking_row record;
        checklist uuid;
begin
 if wid is null then raise exception 'No tienes acceso al espacio Playart'; end if;
 if p_booking_id is null then raise exception 'Selecciona un evento registrado'; end if;
 select b.client_name,b.session_type,b.session_date into booking_row
 from public.bookings b where b.id=p_booking_id and b.workspace_id=wid and b.status<>'Cancelada';
 if not found then raise exception 'No se encontró una reserva activa en Playart'; end if;

 select l.id into checklist from public.event_equipment_checklists l
 where l.booking_id=p_booking_id and l.workspace_id=wid;
 if checklist is not null then return checklist; end if;
 if not exists (select 1 from public.equipment_inventory i where i.workspace_id=wid and i.active) then
  raise exception 'Agrega primero equipos al inventario base';
 end if;

 insert into public.event_equipment_checklists(workspace_id,booking_id,event_name,event_date)
 values (wid,p_booking_id,left(trim(booking_row.session_type)||' · '||trim(booking_row.client_name),200),booking_row.session_date)
 on conflict (booking_id) do nothing returning id into checklist;
 if checklist is null then
  select l.id into checklist from public.event_equipment_checklists l where l.booking_id=p_booking_id and l.workspace_id=wid;
  return checklist;
 end if;
 insert into public.event_equipment_checklist_items(workspace_id,checklist_id,item_name,category,quantity)
 select wid,checklist,i.name,i.category,i.quantity from public.equipment_inventory i
 where i.workspace_id=wid and i.active order by i.category,i.name;
 return checklist;
end $$;
revoke all on function public.create_event_equipment_checklist_for_booking(uuid) from public,anon;
grant execute on function public.create_event_equipment_checklist_for_booking(uuid) to authenticated;
