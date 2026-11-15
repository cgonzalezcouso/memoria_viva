-- Configuración del cron semanal de informes (ejecutar en SQL Editor tras desplegar)
--
-- 1. Insertar URL y secretos:
--    INSERT INTO cron_config (key, value) VALUES
--      ('supabase_url', 'https://TU_PROYECTO.supabase.co'),
--      ('cron_secret', 'genera-un-secreto-aleatorio-largo');
--
-- 2. Configurar el mismo cron_secret en Edge Function secrets:
--    supabase secrets set CRON_SECRET=genera-un-secreto-aleatorio-largo
--
-- 3. Desplegar: supabase functions deploy cron-weekly-reports
--
-- 4. Programar (lunes 08:00 UTC):

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

select cron.unschedule('memoria_viva_weekly_reports')
where exists (
  select 1 from cron.job where jobname = 'memoria_viva_weekly_reports'
);

select cron.schedule(
  'memoria_viva_weekly_reports',
  '0 8 * * 1',
  $$
  select net.http_post(
    url := (select value from public.cron_config where key = 'supabase_url')
           || '/functions/v1/cron-weekly-reports',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('supabase.service_role_key', true),
      'x-cron-secret', (select value from public.cron_config where key = 'cron_secret')
    ),
    body := '{}'::jsonb
  ) as request_id;
  $$
);
