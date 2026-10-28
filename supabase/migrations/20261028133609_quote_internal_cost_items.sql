-- Per-event estimated production costs belong to the quote model, not cash expenses.
alter table public.quote_catalog drop constraint if exists quote_catalog_kind_check;
alter table public.quote_catalog add constraint quote_catalog_kind_check
 check (kind in ('package','staff','extra','zone','cost'));
