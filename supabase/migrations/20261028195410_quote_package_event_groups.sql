alter table public.quote_catalog
  add column if not exists event_group text not null default 'Bodas grandes';
