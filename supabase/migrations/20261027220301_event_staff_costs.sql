-- Staff booked on an event is a planned commitment, not cash paid.
create table public.event_staff_assignments (
 id uuid primary key default gen_random_uuid(),
 workspace_id uuid not null default public.current_workspace_id() references public.workspaces(id) on delete cascade,
 booking_id uuid not null,
 role_key uuid not null,
 role_name text not null check (char_length(trim(role_name)) between 1 and 120),
 people integer not null check (people between 1 and 20),
 hours integer not null check (hours between 1 and 48),
 pay_per_person numeric(10,2) not null check (pay_per_person >= 0),
 client_rate_per_hour numeric(10,2) not null check (client_rate_per_hour >= 0),
 created_at timestamptz not null default now(),
 unique(id,workspace_id),
 unique(booking_id,role_key),
 foreign key (booking_id,workspace_id) references public.bookings(id,workspace_id) on delete cascade
);
create index event_staff_assignments_booking_workspace_idx on public.event_staff_assignments (booking_id,workspace_id);
alter table public.event_staff_assignments enable row level security;
revoke all on public.event_staff_assignments from anon;
grant select,insert,update,delete on public.event_staff_assignments to authenticated;
create policy "Members read event staff" on public.event_staff_assignments for select to authenticated
 using (workspace_id = (select public.current_workspace_id()));
create policy "Members add event staff" on public.event_staff_assignments for insert to authenticated
 with check (workspace_id = (select public.current_workspace_id()));
create policy "Members update event staff" on public.event_staff_assignments for update to authenticated
 using (workspace_id = (select public.current_workspace_id()))
 with check (workspace_id = (select public.current_workspace_id()));
create policy "Members delete event staff" on public.event_staff_assignments for delete to authenticated
 using (workspace_id = (select public.current_workspace_id()));

alter table public.finance_expenses add column assignment_id uuid unique;
alter table public.finance_expenses add constraint finance_expenses_assignment_workspace_fkey
 foreign key (assignment_id,workspace_id) references public.event_staff_assignments(id,workspace_id)
 on delete set null (assignment_id);
create index finance_expenses_assignment_workspace_idx on public.finance_expenses(assignment_id,workspace_id)
 where assignment_id is not null;

alter table public.finance_expenses drop constraint if exists finance_expenses_category_check;
alter table public.finance_expenses add constraint finance_expenses_category_check
 check (category in ('Fotógrafo','Asistente','Dron','Aplicaciones','Servicios','Impresos','Otro'));
alter table public.expense_templates drop constraint if exists expense_templates_category_check;
alter table public.expense_templates add constraint expense_templates_category_check
 check (category in ('Fotógrafo','Asistente','Dron','Aplicaciones','Servicios','Impresos','Otro'));
