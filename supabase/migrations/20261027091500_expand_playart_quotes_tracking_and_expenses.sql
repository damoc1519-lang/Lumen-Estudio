alter table public.bookings add column if not exists client_email text not null default '';
alter table public.leads add column if not exists email text not null default '';

alter table public.quote_catalog add column if not exists internal_cost numeric(10,2) not null default 0 check (internal_cost >= 0);
alter table public.quote_catalog drop constraint if exists quote_catalog_kind_check;
alter table public.quote_catalog add constraint quote_catalog_kind_check check (kind in ('package','extra','zone','staff'));

alter table public.client_projects add column if not exists client_email text not null default '';

create table public.finance_expenses (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null default public.current_workspace_id() references public.workspaces(id) on delete cascade,
  booking_id uuid,
  expense_date date not null default current_date,
  category text not null check (category in ('Fotógrafo','Asistente','Aplicaciones','Servicios','Impresos','Otro')),
  provider text not null default '' check (char_length(provider) <= 160),
  description text not null check (char_length(trim(description)) between 1 and 240),
  amount numeric(10,2) not null check (amount > 0),
  created_at timestamptz not null default now(),
  foreign key (booking_id, workspace_id) references public.bookings(id, workspace_id) on delete set null (booking_id)
);

create index finance_expenses_workspace_date_idx on public.finance_expenses (workspace_id, expense_date desc);
create index finance_expenses_booking_idx on public.finance_expenses (booking_id) where booking_id is not null;
alter table public.finance_expenses enable row level security;
revoke all on public.finance_expenses from anon;
grant select, insert, update, delete on public.finance_expenses to authenticated;
create policy "Workspace members read finance expenses" on public.finance_expenses for select to authenticated
  using (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members add finance expenses" on public.finance_expenses for insert to authenticated
  with check (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members update finance expenses" on public.finance_expenses for update to authenticated
  using (workspace_id = (select public.current_workspace_id()))
  with check (workspace_id = (select public.current_workspace_id()));
create policy "Workspace members delete finance expenses" on public.finance_expenses for delete to authenticated
  using (workspace_id = (select public.current_workspace_id()));

insert into public.quote_catalog (workspace_id, name, description, kind, duration_hours, price, internal_cost, sort_order)
select w.id, v.name, v.description, v.kind, v.duration_hours, 0, 0, v.sort_order
from public.workspaces w
cross join (values
  ('Cobertura de 2 horas','Cobertura fotográfica y/o video; configura el precio final.','package',2,10),
  ('Cobertura de 4 horas','Cobertura fotográfica y/o video; configura el precio final.','package',4,11),
  ('Cobertura de 6 horas','Cobertura fotográfica y/o video; configura el precio final.','package',6,12),
  ('Cobertura de 8 horas','Cobertura fotográfica y/o video; configura el precio final.','package',8,13),
  ('Fotógrafo','Pago base por evento; se puede cambiar al cotizar.','staff',null,20),
  ('Asistente de fotografía','Pago base por evento; se puede cambiar al cotizar.','staff',null,21),
  ('Editor de video','Pago base por proyecto si trabaja como proveedor.','staff',null,22),
  ('Retoque fotográfico','Retoque adicional; configura precio y costo interno.','extra',null,30),
  ('Edición de video','Edición adicional; configura precio y costo interno.','extra',null,31),
  ('Trailer','Video corto de resumen; configura el precio final.','extra',null,32),
  ('Video completo','Video completo del evento; configura el precio final.','extra',null,33),
  ('Reel','Un reel para redes sociales; configura el precio final.','extra',null,34),
  ('Reel adicional','Precio por cada reel extra; configura el precio final.','extra',null,35),
  ('Álbum impreso','Impresión del álbum; configura precio y costo interno.','extra',null,36),
  ('Impresiones adicionales','Copias impresas adicionales; configura precio y costo interno.','extra',null,37),
  ('Sur de Quito','Recargo de traslado si aplica.','zone',null,40),
  ('Valles','Recargo de traslado si aplica.','zone',null,41),
  ('Fuera de Quito','Recargo de traslado si aplica.','zone',null,42)
) as v(name, description, kind, duration_hours, sort_order)
on conflict (workspace_id, kind, name) do nothing;
