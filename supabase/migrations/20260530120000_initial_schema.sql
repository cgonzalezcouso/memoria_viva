-- Esquema inicial para Memoria Viva
-- Aplicar en el SQL Editor de Supabase o con supabase db push

create type public.user_role as enum ('persona', 'cuidador');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  role public.user_role not null default 'persona',
  created_at timestamptz not null default now()
);

create table public.patient_caregiver_links (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  caregiver_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (patient_id, caregiver_id)
);

create table public.cognitive_sessions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  activity_type text not null check (
    activity_type in ('memoria', 'atencion', 'orientacion')
  ),
  score integer not null check (score >= 0 and score <= 100),
  duration_seconds integer not null default 0,
  completed_at timestamptz not null default now()
);

create table public.routine_tasks (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  scheduled_time text not null,
  notes text,
  is_completed boolean not null default false,
  task_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table public.medications (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  scheduled_time text not null,
  instructions text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.patient_caregiver_links enable row level security;
alter table public.cognitive_sessions enable row level security;
alter table public.routine_tasks enable row level security;
alter table public.medications enable row level security;

create policy "Usuarios gestionan su perfil"
  on public.profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Pacientes y cuidadores ven vínculos propios"
  on public.patient_caregiver_links for select
  using (auth.uid() = patient_id or auth.uid() = caregiver_id);

create policy "Sesiones visibles para paciente y cuidadores vinculados"
  on public.cognitive_sessions for select
  using (
    auth.uid() = patient_id
    or exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = cognitive_sessions.patient_id
        and l.caregiver_id = auth.uid()
    )
  );

create policy "Paciente registra sus sesiones"
  on public.cognitive_sessions for insert
  with check (auth.uid() = patient_id);

create policy "Rutinas visibles para paciente y cuidadores"
  on public.routine_tasks for select
  using (
    auth.uid() = patient_id
    or exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = routine_tasks.patient_id
        and l.caregiver_id = auth.uid()
    )
  );

create policy "Paciente actualiza sus rutinas"
  on public.routine_tasks for update
  using (auth.uid() = patient_id)
  with check (auth.uid() = patient_id);

create policy "Medicación visible para paciente y cuidadores"
  on public.medications for select
  using (
    auth.uid() = patient_id
    or exists (
      select 1 from public.patient_caregiver_links l
      where l.patient_id = medications.patient_id
        and l.caregiver_id = auth.uid()
    )
  );
