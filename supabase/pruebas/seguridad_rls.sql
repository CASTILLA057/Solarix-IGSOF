-- Pruebas de las políticas RLS y de los límites (Etapa 12, cierre).
--
-- Se corren contra el proyecto vinculado y NO dejan rastro: todo pasa dentro
-- de un bloque que al final siempre lanza un error con el resumen, y ese
-- error deshace todo lo que se creó (usuarios de prueba, perfiles, cálculos
-- y simulaciones):
--
--   npx supabase db query --linked -f supabase/pruebas/seguridad_rls.sql
--
-- El resultado esperado es un error que empieza con
-- "PRUEBAS DE SEGURIDAD: N de N bien". Cualquier "MAL" es una falla. Si sale
-- otro error, la prueba se detuvo a mitad de camino (también sin dejar nada).

do $$
declare
  admin text := current_user;
  a uuid := gen_random_uuid();
  b uuid := gen_random_uuid();
  calc_a uuid;
  calc_b uuid;
  sim_a uuid;
  n integer;
  r text[] := '{}';
  bien integer;

  entradas constant jsonb := '{"hsp": 5}';
  resultados constant jsonb := '{"paneles": 1}';
  parametros constant jsonb := '{"anios": 10}';
begin
  -- -------------------------------------------------------------------------
  -- Preparación (como administrador): dos usuarios y un cálculo de B.
  -- -------------------------------------------------------------------------
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  )
  select u, '00000000-0000-0000-0000-000000000000', 'authenticated',
    'authenticated', 'prueba-rls-' || u || '@solarix.invalid', '', now(),
    '{}', '{}', now(), now()
  from unnest(array[a, b]) as u;

  insert into public.calculos_consumo (usuario_id, tipo_sistema, entradas, resultados)
  values (b, 'hibrido', entradas, resultados)
  returning id into calc_b;

  -- -------------------------------------------------------------------------
  -- Como el usuario A (rol authenticated, auth.uid() = A).
  -- -------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', a, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from public.perfiles;
  r := r || format('%s solo ve su perfil (%s)', case when n = 1 then 'BIEN' else 'MAL' end, n);

  select count(*) into n from public.calculos_consumo;
  r := r || format('%s no ve cálculos ajenos (%s)', case when n = 0 then 'BIEN' else 'MAL' end, n);

  update public.perfiles set nombre = 'intruso' where id = b;
  get diagnostics n = row_count;
  r := r || format('%s no cambia perfiles ajenos (%s)', case when n = 0 then 'BIEN' else 'MAL' end, n);

  update public.calculos_consumo set nombre = 'intruso' where id = calc_b;
  get diagnostics n = row_count;
  r := r || format('%s no cambia cálculos ajenos (%s)', case when n = 0 then 'BIEN' else 'MAL' end, n);

  delete from public.calculos_consumo where id = calc_b;
  get diagnostics n = row_count;
  r := r || format('%s no borra cálculos ajenos (%s)', case when n = 0 then 'BIEN' else 'MAL' end, n);

  begin
    insert into public.calculos_consumo (usuario_id, tipo_sistema, entradas, resultados)
    values (b, 'hibrido', entradas, resultados);
    r := r || 'MAL crea cálculos a nombre de otro'::text;
  exception when others then
    r := r || format('%s no crea cálculos a nombre de otro (%s)',
      case when sqlstate = '42501' then 'BIEN' else 'MAL' end, sqlstate);
  end;

  insert into public.calculos_consumo (tipo_sistema, entradas, resultados)
  values ('hibrido', entradas, resultados)
  returning id into calc_a;
  r := r || 'BIEN crea su propio cálculo'::text;

  begin
    insert into public.simulaciones_degradacion (calculo_id, politica, parametros, resultados)
    values (calc_b, 'consciente', parametros, resultados);
    r := r || 'MAL enlaza una simulación a un cálculo ajeno'::text;
  exception when others then
    r := r || format('%s no enlaza una simulación a un cálculo ajeno (%s)',
      case when sqlstate = '42501' then 'BIEN' else 'MAL' end, sqlstate);
  end;

  insert into public.simulaciones_degradacion (calculo_id, politica, parametros, resultados)
  values (calc_a, 'consciente', parametros, resultados)
  returning id into sim_a;
  insert into public.simulaciones_degradacion (politica, parametros, resultados)
  values ('convencional', parametros, resultados);
  r := r || 'BIEN guarda simulaciones con su cálculo y sin cálculo'::text;

  begin
    update public.simulaciones_degradacion set calculo_id = calc_b where id = sim_a;
    r := r || 'MAL cambia el enlace a un cálculo ajeno'::text;
  exception when others then
    r := r || format('%s no cambia el enlace a un cálculo ajeno (%s)',
      case when sqlstate = '42501' then 'BIEN' else 'MAL' end, sqlstate);
  end;

  begin
    insert into public.calculos_consumo (tipo_sistema, entradas, resultados)
    values ('hibrido', jsonb_build_object('relleno', repeat('x', 70000)), resultados);
    r := r || 'MAL guarda entradas de 70 KB'::text;
  exception when others then
    r := r || format('%s rechaza entradas de 70 KB (%s)',
      case when sqlstate = '23514' then 'BIEN' else 'MAL' end, sqlstate);
  end;

  begin
    insert into public.simulaciones_degradacion (politica, parametros, resultados, serie)
    values ('convencional', parametros, resultados,
      jsonb_build_array(repeat('x', 270000)));
    r := r || 'MAL guarda una serie de 270 KB'::text;
  exception when others then
    r := r || format('%s rechaza una serie de 270 KB (%s)',
      case when sqlstate = '23514' then 'BIEN' else 'MAL' end, sqlstate);
  end;

  -- Tope de 200 cálculos: llena hasta 200 y la siguiente se rechaza.
  select count(*) into n from public.calculos_consumo;
  insert into public.calculos_consumo (tipo_sistema, entradas, resultados)
  select 'hibrido', entradas, resultados from generate_series(1, 200 - n);
  select count(*) into n from public.calculos_consumo;
  begin
    insert into public.calculos_consumo (tipo_sistema, entradas, resultados)
    values ('hibrido', entradas, resultados);
    r := r || format('MAL guarda el cálculo número %s', n + 1);
  exception when others then
    r := r || format('%s rechaza el cálculo número %s (%s)',
      case when n = 200 and sqlerrm like 'limite_filas%' then 'BIEN' else 'MAL' end,
      n + 1, sqlerrm);
  end;

  -- Tope de 200 simulaciones.
  select count(*) into n from public.simulaciones_degradacion;
  insert into public.simulaciones_degradacion (politica, parametros, resultados)
  select 'convencional', parametros, resultados from generate_series(1, 200 - n);
  select count(*) into n from public.simulaciones_degradacion;
  begin
    insert into public.simulaciones_degradacion (politica, parametros, resultados)
    values ('convencional', parametros, resultados);
    r := r || format('MAL guarda la simulación número %s', n + 1);
  exception when others then
    r := r || format('%s rechaza la simulación número %s (%s)',
      case when n = 200 and sqlerrm like 'limite_filas%' then 'BIEN' else 'MAL' end,
      n + 1, sqlerrm);
  end;

  -- -------------------------------------------------------------------------
  -- Sin sesión (rol anon).
  -- -------------------------------------------------------------------------
  perform set_config('request.jwt.claims', '{"role": "anon"}', true);
  perform set_config('role', 'anon', true);

  begin
    select count(*) into n from public.calculos_consumo;
    r := r || format('%s sin sesión no ve cálculos (%s)', case when n = 0 then 'BIEN' else 'MAL' end, n);
  exception when others then
    r := r || format('%s sin sesión no ve cálculos (%s)',
      case when sqlstate = '42501' then 'BIEN' else 'MAL' end, sqlstate);
  end;

  begin
    perform public.eliminar_mi_cuenta();
    r := r || 'MAL sin sesión llama a eliminar_mi_cuenta'::text;
  exception when others then
    r := r || format('%s sin sesión no llama a eliminar_mi_cuenta (%s)',
      case when sqlstate = '42501' then 'BIEN' else 'MAL' end, sqlstate);
  end;

  -- -------------------------------------------------------------------------
  -- A elimina su cuenta: se borran sus datos y los de B quedan.
  -- -------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', a, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  perform public.eliminar_mi_cuenta();

  perform set_config('role', admin, true);
  select (select count(*) from auth.users where id = a)
       + (select count(*) from public.perfiles where id = a)
       + (select count(*) from public.calculos_consumo where usuario_id = a)
       + (select count(*) from public.simulaciones_degradacion where usuario_id = a)
    into n;
  r := r || format('%s eliminar_mi_cuenta borra todo lo de A (%s filas quedan)',
    case when n = 0 then 'BIEN' else 'MAL' end, n);
  select count(*) into n from public.calculos_consumo where usuario_id = b;
  r := r || format('%s y no toca lo de B (%s)', case when n = 1 then 'BIEN' else 'MAL' end, n);

  -- -------------------------------------------------------------------------
  -- Resumen. El error deshace todo lo anterior.
  -- -------------------------------------------------------------------------
  select count(*) into bien from unnest(r) as x where x like 'BIEN%';
  raise exception E'PRUEBAS DE SEGURIDAD: % de % bien (todo se deshizo)\n%',
    bien, cardinality(r), array_to_string(r, E'\n');
end;
$$;
