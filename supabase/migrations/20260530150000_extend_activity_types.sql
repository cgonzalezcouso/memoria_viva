-- Ampliar tipos de actividad cognitiva

alter table public.cognitive_sessions
  drop constraint if exists cognitive_sessions_activity_type_check;

alter table public.cognitive_sessions
  add constraint cognitive_sessions_activity_type_check
  check (
    activity_type in (
      'memoria',
      'atencion',
      'orientacion',
      'categorias',
      'secuencias',
      'calculo'
    )
  );
