-- Ejercicios temáticos y recuerdos familiares personalizables

alter table public.cognitive_sessions
  drop constraint if exists cognitive_sessions_activity_type_check;

alter table public.cognitive_sessions
  add constraint cognitive_sessions_activity_type_check
  check (
    activity_type in (
      'memoria', 'atencion', 'orientacion', 'categorias', 'secuencias', 'calculo',
      'emociones', 'intruso', 'recuerdo',
      'musica', 'familia', 'naturaleza', 'cocina'
    )
  );

create table public.family_memories (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  display_name text not null,
  relationship text not null,
  emoji text not null default '👤',
  photo_url text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.family_memories enable row level security;

create policy "Paciente gestiona sus recuerdos familiares"
  on public.family_memories for all
  using (auth.uid() = patient_id)
  with check (auth.uid() = patient_id);

create policy "Cuidador gestiona recuerdos de personas vinculadas"
  on public.family_memories for all
  using (
    exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = family_memories.patient_id
        and l.caregiver_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = family_memories.patient_id
        and l.caregiver_id = auth.uid()
    )
  );

-- Configuración para el cron (ver supabase/setup_cron.sql)
create table if not exists public.cron_config (
  key text primary key,
  value text not null
);

revoke all on public.cron_config from anon, authenticated;
grant all on public.cron_config to service_role;
