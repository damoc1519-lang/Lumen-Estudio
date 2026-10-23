-- Speed up workspace membership checks and support the user_id foreign key.
create index if not exists workspace_members_user_id_idx
  on public.workspace_members(user_id);
