-- Remove only the unpriced examples inserted by the earlier catalog migration.
-- Packages and prices entered by Playart remain untouched.
delete from public.quote_catalog q
using (values
 ('Cobertura de 2 horas','package',10),('Cobertura de 4 horas','package',11),
 ('Cobertura de 6 horas','package',12),('Cobertura de 8 horas','package',13),
 ('Fotógrafo','staff',20),('Asistente de fotografía','staff',21),('Editor de video','staff',22),
 ('Retoque fotográfico','extra',30),('Edición de video','extra',31),('Trailer','extra',32),
 ('Video completo','extra',33),('Reel','extra',34),('Reel adicional','extra',35),
 ('Álbum impreso','extra',36),('Impresiones adicionales','extra',37),
 ('Sur de Quito','zone',40),('Valles','zone',41),('Fuera de Quito','zone',42)
) as seed(name,kind,sort_order)
where q.name=seed.name and q.kind=seed.kind and q.sort_order=seed.sort_order
 and q.price=0 and q.internal_cost=0
 and (q.description like '%configura%' or q.description like '%se puede cambiar%' or q.description like '%si trabaja como proveedor%' or q.description like '%si aplica%');

create table public.expense_templates (
 id uuid primary key default gen_random_uuid(),
 workspace_id uuid not null default public.current_workspace_id() references public.workspaces(id) on delete cascade,
 name text not null check (char_length(trim(name)) between 1 and 120),
 category text not null check (category in ('Fotógrafo','Asistente','Aplicaciones','Servicios','Impresos','Otro')),
 provider text not null default '' check (char_length(provider) <= 160),
 amount numeric(10,2) not null check (amount > 0),
 frequency text not null check (frequency in ('Mensual','Ocasional')),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(workspace_id,name),
 unique(id,workspace_id)
);
create index expense_templates_workspace_active_idx on public.expense_templates(workspace_id,active,name);
alter table public.expense_templates enable row level security;
revoke all on public.expense_templates from anon;
grant select,insert,update,delete on public.expense_templates to authenticated;
create policy "Members read expense templates" on public.expense_templates for select to authenticated
 using (workspace_id = (select public.current_workspace_id()));
create policy "Members add expense templates" on public.expense_templates for insert to authenticated
 with check (workspace_id = (select public.current_workspace_id()));
create policy "Members update expense templates" on public.expense_templates for update to authenticated
 using (workspace_id = (select public.current_workspace_id()))
 with check (workspace_id = (select public.current_workspace_id()));
create policy "Members delete expense templates" on public.expense_templates for delete to authenticated
 using (workspace_id = (select public.current_workspace_id()));

alter table public.finance_expenses add column expense_template_id uuid;
alter table public.finance_expenses add constraint finance_expenses_template_workspace_fkey
 foreign key (expense_template_id,workspace_id) references public.expense_templates(id,workspace_id)
 on delete set null (expense_template_id);
create index finance_expenses_template_idx on public.finance_expenses(expense_template_id) where expense_template_id is not null;

insert into public.quote_catalog(workspace_id,name,description,kind,price,internal_cost,sort_order)
select w.id, v.name, 'Configura precio de venta y pago por hora en Catálogo.', 'staff', 0, 0, v.sort_order
from public.workspaces w
cross join (values ('Asistente', 3), ('Cobertura dron', 4)) as v(name,sort_order)
on conflict (workspace_id,kind,name) do nothing;
