-- Evita recursión infinita en RLS: las políticas no deben hacer SELECT
-- sobre public.profiles dentro de otras políticas de la misma tabla.
-- Usar funciones SECURITY DEFINER que leen profiles sin activar RLS.

create or replace function public.current_user_is_caregiver()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'cuidador'
  );
$$;

create or replace function public.profile_is_persona(profile_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = profile_id
      and role = 'persona'
  );
$$;

revoke all on function public.current_user_is_caregiver() from public;
revoke all on function public.profile_is_persona(uuid) from public;
grant execute on function public.current_user_is_caregiver() to authenticated;
grant execute on function public.profile_is_persona(uuid) to authenticated;

drop policy if exists "Buscar personas para vincular" on public.profiles;

create policy "Buscar personas para vincular"
  on public.profiles for select
  using (
    role = 'persona'
    and public.current_user_is_caregiver()
  );

drop policy if exists "Cuidador crea vínculos con personas" on public.patient_caregiver_links;

create policy "Cuidador crea vínculos con personas"
  on public.patient_caregiver_links for insert
  with check (
    auth.uid() = caregiver_id
    and public.profile_is_persona(patient_id)
  );
