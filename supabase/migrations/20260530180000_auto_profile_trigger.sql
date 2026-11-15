-- Trigger para crear automáticamente el perfil en public.profiles al registrarse en auth.users
-- Esto evita problemas de permisos de inserción desde el cliente (anon/authenticated).

create or replace function public.handle_new_user()
returns trigger
security definer set search_path = public
language plpgsql
as $$
declare
  default_role public.user_role;
  meta_role text;
  meta_full_name text;
begin
  -- Extraer del metadato del usuario enviado en el registro
  meta_role := new.raw_user_meta_data->>'role';
  meta_full_name := new.raw_user_meta_data->>'full_name';
  
  if meta_role = 'cuidador' then
    default_role := 'cuidador'::public.user_role;
  else
    default_role := 'persona'::public.user_role;
  end if;

  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(meta_full_name, split_part(new.email, '@', 1)),
    default_role
  );
  return new;
end;
$$;

-- Crear el trigger
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
