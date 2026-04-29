-- Tourism sustainability engine schema extension
-- Apply in Supabase/Postgres migration runner.

create table if not exists tourism_trip_logs (
  id bigserial primary key,
  business_id text not null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  transport_mode text not null,
  distance_km numeric(10,2) not null default 0,
  emissions_kg numeric(10,2) not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists tourism_daily_operations (
  id bigserial primary key,
  business_id text not null,
  op_date date not null default current_date,
  electricity_kwh numeric(10,2) not null default 0,
  lpg_kg numeric(10,2) not null default 0,
  organic_waste_kg numeric(10,2) not null default 0,
  oil_waste_kg numeric(10,2) not null default 0,
  total_emissions_kg numeric(10,2) not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists tourism_ai_recommendations (
  id bigserial primary key,
  business_id text not null,
  source_type text not null, -- trip|daily_summary
  payload jsonb not null,
  insight jsonb not null,
  eco_score numeric(10,2) not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists idx_tourism_trip_logs_business on tourism_trip_logs (business_id, created_at desc);
create index if not exists idx_tourism_daily_operations_business on tourism_daily_operations (business_id, op_date desc);
create index if not exists idx_tourism_ai_recommendations_business on tourism_ai_recommendations (business_id, created_at desc);
