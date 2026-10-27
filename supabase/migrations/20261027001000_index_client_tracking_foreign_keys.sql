create index if not exists client_projects_booking_workspace_idx
  on public.client_projects (booking_id, workspace_id);

create index if not exists client_project_stages_project_workspace_idx
  on public.client_project_stages (project_id, workspace_id);