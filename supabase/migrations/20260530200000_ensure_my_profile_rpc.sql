-- Crea o devuelve el perfil del usuario autenticado (evita fallos de RLS en el cliente).
create or replace function public.ensure_my_profile()
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  profile_row public.profiles;
  meta jsonb;
  user_email text;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  select * into profile_row
  from public.profiles
  where id = auth.uid();

  if found then
    return profile_row;
  end if;

  select raw_user_meta_data, email
  into meta, user_email
  from auth.users
  where id = auth.uid();

  insert into public.profiles (id, full_name, role)
  values (
    auth.uid(),
    coalesce(
      nullif(trim(meta->>'full_name'), ''),
      split_part(coalesce(user_email, 'usuario'), '@', 1)
    ),
    case
      when meta->>'role' = 'cuidador' then 'cuidador'::public.user_role
      else 'persona'::public.user_role
    end
  )
  returning * into profile_row;

  return profile_row;
exception
  when unique_violation then
    select * into profile_row
    from public.profiles
    where id = auth.uid();
    return profile_row;
end;
$$;

revoke all on function public.ensure_my_profile() from public;
grant execute on function public.ensure_my_profile() to authenticated;
