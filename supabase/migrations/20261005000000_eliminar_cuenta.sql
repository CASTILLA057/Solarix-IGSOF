-- Etapa 12 (protección de datos, Ley 1581 de 2012): "Eliminar mi cuenta".
--
-- La app no puede borrar usuarios con la llave pública, así que esta función
-- lo hace en el servidor, solo para quien la llama (auth.uid()). Al borrar el
-- usuario de auth.users se borran en cascada su perfil, sus cálculos y sus
-- simulaciones (on delete cascade en perfiles, calculos_consumo y
-- simulaciones_degradacion).

create or replace function public.eliminar_mi_cuenta()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Sin sesión';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

comment on function public.eliminar_mi_cuenta() is
  'Borra la cuenta de quien la llama y, en cascada, todos sus datos.';

revoke all on function public.eliminar_mi_cuenta() from public, anon;
grant execute on function public.eliminar_mi_cuenta() to authenticated;
