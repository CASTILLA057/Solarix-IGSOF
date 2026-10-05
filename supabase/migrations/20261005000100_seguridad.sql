-- Etapa 12 (seguridad del backend): límites para que nadie llene la base del
-- plan gratuito, calculo_id solo hacia cálculos propios y limpieza de lo que
-- la app ya no usa.

-- ---------------------------------------------------------------------------
-- 1. Tamaño máximo de las columnas jsonb. Lo más grande que guarda la app
--    (50 equipos, horizonte de 30 años, simulación de 20 años) pesa ≈ 8 KB en
--    entradas y resultados del cálculo, 0,5 KB en parámetros, 2 KB en los
--    resultados de la simulación y 32 KB en la serie (prueba en
--    test/core/limites_backend_test.dart). Los topes dejan mucho margen.
-- ---------------------------------------------------------------------------
alter table public.calculos_consumo
  add constraint calculos_entradas_tamano
    check (pg_column_size(entradas) <= 65536),
  add constraint calculos_resultados_tamano
    check (pg_column_size(resultados) <= 65536);

alter table public.simulaciones_degradacion
  add constraint simulaciones_parametros_tamano
    check (pg_column_size(parametros) <= 16384),
  add constraint simulaciones_resultados_tamano
    check (pg_column_size(resultados) <= 65536),
  add constraint simulaciones_serie_tamano
    check (serie is null or pg_column_size(serie) <= 262144);

-- ---------------------------------------------------------------------------
-- 2. Máximo 200 cálculos y 200 simulaciones por usuario. El mensaje empieza
--    con "limite_filas" para que la app lo reconozca y lo explique.
-- ---------------------------------------------------------------------------
create function public.limitar_filas_por_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  maximo constant integer := 200;
  actuales integer;
begin
  if tg_table_name = 'calculos_consumo' then
    select count(*) into actuales
      from public.calculos_consumo where usuario_id = new.usuario_id;
  else
    select count(*) into actuales
      from public.simulaciones_degradacion where usuario_id = new.usuario_id;
  end if;
  if actuales >= maximo then
    raise exception 'limite_filas: %', tg_table_name
      using hint = format('Máximo %s por usuario.', maximo);
  end if;
  return new;
end;
$$;

revoke all on function public.limitar_filas_por_usuario() from public, anon, authenticated;

create trigger limitar_calculos
  before insert on public.calculos_consumo
  for each row execute function public.limitar_filas_por_usuario();

create trigger limitar_simulaciones
  before insert on public.simulaciones_degradacion
  for each row execute function public.limitar_filas_por_usuario();

-- ---------------------------------------------------------------------------
-- 3. Una simulación solo puede enlazarse a un cálculo del mismo usuario.
-- ---------------------------------------------------------------------------
drop policy "simulaciones propias: crear" on public.simulaciones_degradacion;
create policy "simulaciones propias: crear"
  on public.simulaciones_degradacion for insert to authenticated
  with check (
    (select auth.uid()) = usuario_id
    and (
      calculo_id is null
      or exists (
        select 1 from public.calculos_consumo c
        where c.id = calculo_id and c.usuario_id = (select auth.uid())
      )
    )
  );

drop policy "simulaciones propias: actualizar" on public.simulaciones_degradacion;
create policy "simulaciones propias: actualizar"
  on public.simulaciones_degradacion for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check (
    (select auth.uid()) = usuario_id
    and (
      calculo_id is null
      or exists (
        select 1 from public.calculos_consumo c
        where c.id = calculo_id and c.usuario_id = (select auth.uid())
      )
    )
  );

-- ---------------------------------------------------------------------------
-- 4. Lo que la app ya no usa: la zona del perfil (la ciudad del perfil se
--    elige ahora de la lista y de ella sale la zona) y las tablas de precios
--    y ciudades (desde la Etapa 12 la única fuente es Dart).
-- ---------------------------------------------------------------------------
alter table public.perfiles drop column zona_irradiancia;

drop table public.precios_referencia;
drop table public.ciudades;
