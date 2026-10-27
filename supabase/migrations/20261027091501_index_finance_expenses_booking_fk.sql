create index finance_expenses_booking_workspace_idx
  on public.finance_expenses (booking_id, workspace_id)
  where booking_id is not null;
