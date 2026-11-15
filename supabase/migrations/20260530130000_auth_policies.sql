-- Políticas adicionales para autenticación y vínculos familiares

create policy "Perfiles visibles para vínculos"
  on public.profiles for select
  using (
    auth.uid() = id
    or exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = profiles.id
        and l.caregiver_id = auth.uid()
    )
  );

create policy "Cuidador crea vínculos con personas"
  on public.patient_caregiver_links for insert
  with check (
    auth.uid() = caregiver_id
    and exists (
      select 1 from public.profiles p
      where p.id = patient_id
        and p.role = 'persona'
    )
  );

create policy "Cuidador elimina sus vínculos"
  on public.patient_caregiver_links for delete
  using (auth.uid() = caregiver_id);

-- Permite buscar perfiles de personas por ID al vincular (solo rol persona)
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
