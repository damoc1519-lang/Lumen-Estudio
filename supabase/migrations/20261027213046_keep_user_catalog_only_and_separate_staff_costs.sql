-- Remove zero-price example catalog rows so the quote builder only offers
-- packages and add-ons entered by the studio. Match exact seeded rows to keep
-- user-created catalog data intact.
delete from public.quote_catalog
where (name = 'Cobertura de 2 horas' and kind = 'package' and sort_order = 1 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Cobertura de 4 horas' and kind = 'package' and sort_order = 2 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Cobertura de 6 horas' and kind = 'package' and sort_order = 3 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Cobertura de 8 horas' and kind = 'package' and sort_order = 4 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Fotógrafo' and kind = 'staff' and sort_order = 5 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Asistente' and kind = 'staff' and sort_order = 6 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Editor de video' and kind = 'staff' and sort_order = 7 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Retoque fotográfico' and kind = 'extra' and sort_order = 8 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Edición de video' and kind = 'extra' and sort_order = 9 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Reel adicional' and kind = 'extra' and sort_order = 10 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Video completo' and kind = 'extra' and sort_order = 11 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Tráiler' and kind = 'extra' and sort_order = 12 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Álbum impreso' and kind = 'extra' and sort_order = 13 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Impresión adicional' and kind = 'extra' and sort_order = 14 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Sur de Quito' and kind = 'zone' and sort_order = 15 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Valles' and kind = 'zone' and sort_order = 16 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0)
   or (name = 'Fuera de Quito' and kind = 'zone' and sort_order = 17 and coalesce(price,0)=0 and coalesce(internal_cost,0)=0);

-- Keep the existing photographer amount as an editable internal event cost.
update public.quote_catalog
set kind = 'staff', internal_cost = price, price = 0, duration_hours = null,
    description = 'Pago base por evento; se ajusta según cada trabajo.'
where name = 'FOTOGRAFO' and kind = 'package'
  and coalesce(price,0) = 50 and coalesce(internal_cost,0) = 0;
