-- Solarix — esquema inicial (Etapa 1)
-- Ejecutar en Supabase: SQL Editor → pegar y correr, o `supabase db push`.
-- Las columnas jsonb (entradas, resultados, parametros, serie) se detallan
-- en las Etapas 3 y 5, cuando las fórmulas estén definidas.

-- ---------------------------------------------------------------------------
-- perfiles: un registro por usuario de Auth
-- ---------------------------------------------------------------------------
create table public.perfiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  nombre            text,
  ciudad            text,
  zona_irradiancia  text check (zona_irradiancia in ('baja', 'media', 'alta')),
  creado_en         timestamptz not null default now(),
  actualizado_en    timestamptz not null default now()
);

-- Crea el perfil automáticamente al registrarse un usuario.
create function public.crear_perfil_nuevo_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.perfiles (id, nombre)
  values (new.id, new.raw_user_meta_data ->> 'nombre');
  return new;
end;
$$;

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil_nuevo_usuario();

-- ---------------------------------------------------------------------------
-- calculos_consumo: resultados de la calculadora solar (Etapa 3)
-- ---------------------------------------------------------------------------
create table public.calculos_consumo (
  id            uuid primary key default gen_random_uuid(),
  usuario_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  nombre        text,
  tipo_sistema  text not null check (tipo_sistema in ('on_grid', 'off_grid', 'hibrido')),
  entradas      jsonb not null,
  resultados    jsonb not null,
  creado_en     timestamptz not null default now()
);

create index calculos_consumo_usuario_fecha_idx
  on public.calculos_consumo (usuario_id, creado_en desc);

-- ---------------------------------------------------------------------------
-- simulaciones_degradacion: corridas de SimDeg-FV (Etapa 5)
-- calculo_id enlaza con el dimensionamiento que la originó (Etapa 6).
-- ---------------------------------------------------------------------------
create table public.simulaciones_degradacion (
  id            uuid primary key default gen_random_uuid(),
  usuario_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  calculo_id    uuid references public.calculos_consumo (id) on delete set null,
  politica      text not null check (politica in ('convencional', 'consciente')),
  parametros    jsonb not null,
  resultados    jsonb not null,
  serie         jsonb,          -- serie reducida (diaria/mensual), nunca horaria
  creado_en     timestamptz not null default now()
);

create index simulaciones_usuario_fecha_idx
  on public.simulaciones_degradacion (usuario_id, creado_en desc);
create index simulaciones_calculo_idx
  on public.simulaciones_degradacion (calculo_id);

-- ---------------------------------------------------------------------------
-- Row Level Security: cada usuario solo ve y modifica sus propias filas
-- ---------------------------------------------------------------------------
alter table public.perfiles                 enable row level security;
alter table public.calculos_consumo         enable row level security;
alter table public.simulaciones_degradacion enable row level security;

create policy "perfil propio: leer"
  on public.perfiles for select to authenticated
  using ((select auth.uid()) = id);
create policy "perfil propio: actualizar"
  on public.perfiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "calculos propios: leer"
  on public.calculos_consumo for select to authenticated
  using ((select auth.uid()) = usuario_id);
create policy "calculos propios: crear"
  on public.calculos_consumo for insert to authenticated
  with check ((select auth.uid()) = usuario_id);
create policy "calculos propios: actualizar"
  on public.calculos_consumo for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);
create policy "calculos propios: eliminar"
  on public.calculos_consumo for delete to authenticated
  using ((select auth.uid()) = usuario_id);

create policy "simulaciones propias: leer"
  on public.simulaciones_degradacion for select to authenticated
  using ((select auth.uid()) = usuario_id);
create policy "simulaciones propias: crear"
  on public.simulaciones_degradacion for insert to authenticated
  with check ((select auth.uid()) = usuario_id);
create policy "simulaciones propias: actualizar"
  on public.simulaciones_degradacion for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);
create policy "simulaciones propias: eliminar"
  on public.simulaciones_degradacion for delete to authenticated
  using ((select auth.uid()) = usuario_id);
