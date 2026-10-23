-- Free seats and addresses when a previous invitation has expired.
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
  delete from public.workspace_invites where workspace_id=new.workspace_id and accepted_at is null and expires_at<=now();
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
