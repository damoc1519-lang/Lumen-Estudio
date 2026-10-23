-- Keep invitation acceptance under RLS and expose only each invitee's own invite.
alter table public.workspaces add column if not exists member_count integer not null default 0;
update public.workspaces w set member_count=(select count(*) from public.workspace_members wm where wm.workspace_id=w.id);
create or replace function public.refresh_workspace_member_count()
returns trigger language plpgsql security definer set search_path = '' as $$
declare wid uuid;
begin
  wid := case when tg_op='DELETE' then old.workspace_id else new.workspace_id end;
  update public.workspaces set member_count=(select count(*) from public.workspace_members where workspace_id=wid) where id=wid;
  if tg_op='DELETE' then return old; else return new; end if;
end $$;
revoke all on function public.refresh_workspace_member_count() from public, anon, authenticated;
drop trigger if exists refresh_workspace_member_count on public.workspace_members;
create trigger refresh_workspace_member_count
after insert or delete on public.workspace_members
for each row execute function public.refresh_workspace_member_count();

grant insert on public.workspace_members to authenticated;
create policy "Invited users can join their invited workspace"
on public.workspace_members for insert to authenticated
with check (
  user_id=(select auth.uid())
  and exists (
    select 1 from public.workspace_invites wi
    where wi.workspace_id=workspace_members.workspace_id
      and lower(wi.email)=lower((select auth.jwt()->>'email'))
      and wi.accepted_at is null and wi.expires_at>now()
  )
  and not exists (
    select 1 from public.workspace_members existing
    where existing.user_id=(select auth.uid())
      and existing.workspace_id<>workspace_members.workspace_id
  )
);

create policy "Invitees can read their own invitation"
on public.workspace_invites for select to authenticated
using (lower(email)=lower((select auth.jwt()->>'email')) and accepted_at is null and expires_at>now());
revoke update on public.workspace_invites from authenticated;
grant update (accepted_at, accepted_user_id) on public.workspace_invites to authenticated;
create policy "Invitees can accept their own invitation"
on public.workspace_invites for update to authenticated
using (lower(email)=lower((select auth.jwt()->>'email')) and accepted_at is null and expires_at>now())
with check (lower(email)=lower((select auth.jwt()->>'email')) and accepted_at is not null and accepted_user_id=(select auth.uid()));

create or replace function public.accept_playart_invite()
returns boolean language plpgsql security invoker set search_path = '' as $$
declare current_user_id uuid := (select auth.uid()); user_email text := lower((select auth.jwt()->>'email')); workspace_to_join uuid; invite_id uuid;
begin
  if current_user_id is null or user_email is null then return false; end if;
  select wi.workspace_id,wi.id into workspace_to_join,invite_id
  from public.workspace_invites wi
  where lower(wi.email)=user_email and wi.accepted_at is null and wi.expires_at>now()
  order by wi.created_at limit 1 for update;
  if invite_id is null then return false; end if;
  if exists (select 1 from public.workspace_members wm where wm.user_id=current_user_id and wm.workspace_id<>workspace_to_join) then
    raise exception 'Esta cuenta ya pertenece a otro espacio';
  end if;
  insert into public.workspace_members(workspace_id,user_id,role)
  values(workspace_to_join,current_user_id,'member') on conflict(workspace_id,user_id) do nothing;
  update public.workspace_invites set accepted_at=now(),accepted_user_id=current_user_id where id=invite_id;
  return true;
end $$;
revoke all on function public.accept_playart_invite() from public,anon;
grant execute on function public.accept_playart_invite() to authenticated;
revoke all on function public.get_playart_team_summary() from public,anon,authenticated;
drop function public.get_playart_team_summary();
