-- Schema per la raccolta delle segnalazioni crowdsourced.
-- Da eseguire una tantum nel SQL Editor del progetto Supabase.

create table if not exists reports (
    id           uuid primary key default gen_random_uuid(),
    phone_number text not null,
    category     text not null check (category in ('spam', 'scam', 'telemarketing', 'robocall', 'other')),
    device_hash  text not null,
    app_platform text not null check (app_platform in ('ios', 'android')),
    reported_at  timestamptz not null default now(),
    -- Colonna dedicata invece di un'espressione nell'indice: timestamptz::date
    -- dipende dal fuso orario di sessione (non IMMUTABLE), quindi non è
    -- utilizzabile direttamente in un indice.
    report_date  date not null default (now() at time zone 'utc')::date
);

-- Impedisce che un singolo device gonfi il conteggio segnalando
-- ripetutamente lo stesso numero nello stesso giorno.
create unique index if not exists reports_device_number_day_idx
    on reports (device_hash, phone_number, report_date);

create index if not exists reports_phone_number_idx on reports (phone_number);

alter table reports enable row level security;

-- L'app pubblica può solo inserire segnalazioni, mai leggerle/modificarle:
-- l'aggregazione avviene lato script con la service role key, che bypassa RLS.
create policy "public can insert reports"
    on reports for insert
    to anon
    with check (true);
