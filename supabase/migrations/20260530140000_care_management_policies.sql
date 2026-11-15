-- Políticas para personalización de rutinas y medicación por cuidadores

create policy "Paciente inserta rutinas propias"
  on public.routine_tasks for insert
  with check (auth.uid() = patient_id);

create policy "Cuidador gestiona rutinas vinculadas"
  on public.routine_tasks for insert
  with check (
    exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = routine_tasks.patient_id
        and l.caregiver_id = auth.uid()
    )
  );

create policy "Cuidador actualiza rutinas vinculadas"
  on public.routine_tasks for update
  using (
    exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = routine_tasks.patient_id
        and l.caregiver_id = auth.uid()
    )
  );

create policy "Cuidador elimina rutinas vinculadas"
  on public.routine_tasks for delete
  using (
    exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = routine_tasks.patient_id
        and l.caregiver_id = auth.uid()
    )
  );

create policy "Cuidador gestiona medicación vinculada"
  on public.medications for insert
  with check (
    exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = medications.patient_id
        and l.caregiver_id = auth.uid()
    )
  );

create policy "Cuidador actualiza medicación vinculada"
  on public.medications for update
  using (
    exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = medications.patient_id
        and l.caregiver_id = auth.uid()
    )
  );

create policy "Paciente gestiona su medicación"
  on public.medications for all
  using (auth.uid() = patient_id)
  with check (auth.uid() = patient_id);
