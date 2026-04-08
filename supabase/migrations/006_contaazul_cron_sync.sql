-- =====================================================
-- Conta Azul - Sync Automatico via pg_cron + pg_net
-- =====================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

GRANT USAGE ON SCHEMA cron TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO postgres;

-- Sync hourly: incremental at most hours, full at 3am/6am UTC
-- Edge Function decides full vs incremental based on current hour
SELECT cron.schedule(
    'contaazul-sync-hourly',
    '0 * * * *',
    $$
    SELECT net.http_get(
        url := 'https://wjoxsyyyqohaqknymqdg.supabase.co/functions/v1/contaazul-sync?action=scheduled&empresa_id=7343268a-4c8d-4f43-bf8f-4c02778b09b7',
        headers := jsonb_build_object(
            'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indqb3hzeXl5cW9oYXFrbnltcWRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMDM3NzUsImV4cCI6MjA5MDg3OTc3NX0.TVsuVcNNqqC74C70ILXt7GZ9ny_QZhW0DljoKUAtiNw',
            'apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indqb3hzeXl5cW9oYXFrbnltcWRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMDM3NzUsImV4cCI6MjA5MDg3OTc3NX0.TVsuVcNNqqC74C70ILXt7GZ9ny_QZhW0DljoKUAtiNw'
        )
    );
    $$
);

-- Token refresh every 45 minutes (access_token expires in 1h)
SELECT cron.schedule(
    'contaazul-token-refresh',
    '*/45 * * * *',
    $$
    SELECT net.http_get(
        url := 'https://wjoxsyyyqohaqknymqdg.supabase.co/functions/v1/contaazul-auth?action=refresh&empresa_id=7343268a-4c8d-4f43-bf8f-4c02778b09b7',
        headers := jsonb_build_object(
            'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indqb3hzeXl5cW9oYXFrbnltcWRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMDM3NzUsImV4cCI6MjA5MDg3OTc3NX0.TVsuVcNNqqC74C70ILXt7GZ9ny_QZhW0DljoKUAtiNw',
            'apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indqb3hzeXl5cW9oYXFrbnltcWRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMDM3NzUsImV4cCI6MjA5MDg3OTc3NX0.TVsuVcNNqqC74C70ILXt7GZ9ny_QZhW0DljoKUAtiNw'
        )
    );
    $$
);
