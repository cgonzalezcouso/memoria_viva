-- Corrige política RLS que usaba auth.jwt().user_metadata (editable por el usuario).
-- Sustituida en 20260530210000 por funciones security definer (evita recursión).

drop policy if exists "Buscar personas para vincular" on public.profiles;

create policy "Buscar personas para vincular"
  on public.profiles for select
  using (
    role = 'persona'
    and exists (
      select 1
      from public.profiles as caregiver
      where caregiver.id = auth.uid()
        and caregiver.role = 'cuidador'
    )
  );
-- Impide que un usuario eleve privilegios cambiando su propio rol en profiles.
create or replace function public.profiles_prevent_role_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.role is distinct from new.role then
    raise exception 'No se puede modificar el rol del perfil.';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_role_change on public.profiles;

create trigger profiles_prevent_role_change
  before update on public.profiles
  for each row
  execute function public.profiles_prevent_role_change();
