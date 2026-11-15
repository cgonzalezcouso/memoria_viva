-- Nuevos tipos de actividad y configuración de envío de informes por email

alter table public.cognitive_sessions
  drop constraint if exists cognitive_sessions_activity_type_check;

alter table public.cognitive_sessions
  add constraint cognitive_sessions_activity_type_check
  check (
    activity_type in (
      'memoria', 'atencion', 'orientacion', 'categorias', 'secuencias', 'calculo',
      'emociones', 'intruso', 'recuerdo'
    )
  );

create table public.report_email_settings (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  recipient_email text not null,
  auto_send_weekly boolean not null default false,
  last_sent_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (patient_id)
);

alter table public.report_email_settings enable row level security;

create policy "Paciente gestiona su configuración de informes"
  on public.report_email_settings for all
  using (auth.uid() = patient_id)
  with check (auth.uid() = patient_id);

create policy "Cuidador gestiona informes de personas vinculadas"
  on public.report_email_settings for all
  using (
    exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = report_email_settings.patient_id
        and l.caregiver_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = report_email_settings.patient_id
        and l.caregiver_id = auth.uid()
    )
  );
