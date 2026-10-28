alter table public.quote_catalog
  add column if not exists pricing_mode text not null default 'sum',
  add column if not exists hourly_prices jsonb not null default '{}'::jsonb;
alter table public.quote_catalog
  add constraint quote_catalog_pricing_mode_check check (pricing_mode in ('sum','fixed')),
  add constraint quote_catalog_hourly_prices_object_check check (jsonb_typeof(hourly_prices) = 'object');
