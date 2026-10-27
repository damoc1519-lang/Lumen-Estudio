drop index if exists public.finance_expenses_template_idx;
create index finance_expenses_template_workspace_idx
 on public.finance_expenses(expense_template_id,workspace_id)
 where expense_template_id is not null;
