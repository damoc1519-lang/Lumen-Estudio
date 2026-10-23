-- Invite teammates into the shared Playart workspace (4 seats incl. pending invites).
create table public.workspace_invites (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null default public.current_workspace_id() references public.workspaces(id) on delete cascade,
  email text not null check (position('@' in email) > 1),
  invited_by uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '30 days'),
  accepted_at timestamptz,
  accepted_user_id uuid references auth.users(id) on delete set null
);
create unique index workspace_invites_pending_email_idx
  on public.workspace_invites(workspace_id, lower(email)) where accepted_at is null;
create index workspace_invites_workspace_idx on public.workspace_invites(workspace_id);
alter table public.workspace_invites enable row level security;
grant select, insert, delete on public.workspace_invites to authenticated;
create policy "Workspace members can read invites"
on public.workspace_invites for select to authenticated
using (workspace_id = public.current_workspace_id());
create policy "Workspace members can create invites"
on public.workspace_invites for insert to authenticated
with check (workspace_id = public.current_workspace_id() and invited_by = (select auth.uid()));
create policy "Workspace members can cancel invites"
on public.workspace_invites for delete to authenticated
using (workspace_id = public.current_workspace_id() and accepted_at is null);

create or replace function public.guard_playart_invite_capacity()
returns trigger language plpgsql security definer set search_path = '' as $$
declare member_count integer; pending_count integer;
begin
  if not exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id = new.workspace_id and wm.user_id = (select auth.uid())
  ) then raise exception 'Solo miembros de Playart pueden invitar personas'; end if;
  new.email := lower(trim(new.email));
  perform pg_advisory_xact_lock(hashtext(new.workspace_id::text));
  select count(*) into member_count from public.workspace_members where workspace_id = new.workspace_id;
  select count(*) into pending_count from public.workspace_invites
    where workspace_id = new.workspace_id and accepted_at is null and expires_at > now();
  if member_count + pending_count >= 4 then
    raise exception 'El espacio permite hasta cuatro personas, contando invitaciones pendientes';
  end if;
  if exists (
    select 1 from auth.users u join public.workspace_members wm on wm.user_id = u.id
    where wm.workspace_id = new.workspace_id and lower(u.email) = new.email
  ) then raise exception 'Esa persona ya tiene acceso al espacio'; end if;
  return new;
end $$;
revoke all on function public.guard_playart_invite_capacity() from public, anon, authenticated;
create trigger guard_playart_invite_capacity
before insert on public.workspace_invites
for each row execute function public.guard_playart_invite_capacity();

-- Existing invitees must sign in with the invited address before joining.
create or replace function public.accept_playart_invite()
returns boolean language plpgsql security definer set search_path = '' as $$
declare current_user_id uuid := (select auth.uid()); user_email text; workspace_to_join uuid; invite_id uuid;
begin
  if current_user_id is null then return false; end if;
  select lower(u.email) into user_email from auth.users u
  where u.id = current_user_id and u.email_confirmed_at is not null;
  if user_email is null then return false; end if;
  select wi.workspace_id, wi.id into workspace_to_join, invite_id
  from public.workspace_invites wi
  where lower(wi.email) = user_email and wi.accepted_at is null and wi.expires_at > now()
  order by wi.created_at limit 1 for update;
  if invite_id is null then return false; end if;
  if exists (select 1 from public.workspace_members wm where wm.user_id=current_user_id and wm.workspace_id<>workspace_to_join) then
    raise exception 'Esta cuenta ya pertenece a otro espacio';
  end if;
  insert into public.workspace_members(workspace_id,user_id,role)
  values (workspace_to_join,current_user_id,'member') on conflict (workspace_id,user_id) do nothing;
  update public.workspace_invites set accepted_at=now(),accepted_user_id=current_user_id where id=invite_id;
  return true;
end $$;
revoke all on function public.accept_playart_invite() from public, anon;
grant execute on function public.accept_playart_invite() to authenticated;

create or replace function public.get_playart_team_summary()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare workspace_to_read uuid; result jsonb;
begin
  select wm.workspace_id into workspace_to_read from public.workspace_members wm
  where wm.user_id=(select auth.uid()) order by wm.created_at limit 1;
  if workspace_to_read is null then raise exception 'No tienes acceso al espacio Playart'; end if;
  select jsonb_build_object(
    'member_count', (select count(*) from public.workspace_members where workspace_id=workspace_to_read),
    'invites', coalesce((select jsonb_agg(jsonb_build_object('id',wi.id,'email',wi.email,'created_at',wi.created_at,'expires_at',wi.expires_at) order by wi.created_at)
      from public.workspace_invites wi where wi.workspace_id=workspace_to_read and wi.accepted_at is null and wi.expires_at>now()), '[]'::jsonb)
  ) into result;
  return result;
end $$;
revoke all on function public.get_playart_team_summary() from public, anon;
grant execute on function public.get_playart_team_summary() to authenticated;

-- Delete one consultation/client record and its directly linked booking/payment record atomically.
create or replace function public.delete_playart_client_record(p_lead_id uuid default null, p_booking_id uuid default null)
returns void language plpgsql security invoker set search_path = '' as $$
declare linked_booking_id uuid; linked_lead_id uuid; affected integer;
begin
  if (p_lead_id is null) = (p_booking_id is null) then raise exception 'Indica una consulta o una reserva para eliminar'; end if;
  if p_lead_id is not null then
    select l.booking_id into linked_booking_id from public.leads l where l.id=p_lead_id;
    if not found then raise exception 'La consulta ya no existe o no tienes acceso'; end if;
    delete from public.leads where id=p_lead_id;
    if linked_booking_id is not null then delete from public.bookings where id=linked_booking_id; end if;
  else
    select l.id into linked_lead_id from public.leads l where l.booking_id=p_booking_id;
    if linked_lead_id is not null then delete from public.leads where id=linked_lead_id; end if;
    delete from public.bookings where id=p_booking_id;
    get diagnostics affected = row_count;
    if affected=0 then raise exception 'La reserva ya no existe o no tienes acceso'; end if;
  end if;
end $$;
revoke all on function public.delete_playart_client_record(uuid,uuid) from public, anon;
grant execute on function public.delete_playart_client_record(uuid,uuid) to authenticated;
