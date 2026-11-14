-- =============================================================================
-- Migration: 001_init.sql
-- Execute Application Database Schema & Storage Setup
-- Designed for re-runnable execution on Supabase Postgres
-- =============================================================================

-- Enable required extensions
create extension if not exists "pgcrypto";

-- -----------------------------------------------------------------------------
-- 1. Table: todos
-- -----------------------------------------------------------------------------
create table if not exists public.todos (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    title text not null,
    scheduled_date date not null,
    is_completed boolean not null default false,
    rollover_count integer not null default 0,
    created_at timestamptz not null default now()
);

alter table public.todos enable row level security;
drop policy if exists "todos_user_policy" on public.todos;
create policy "todos_user_policy" on public.todos
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_todos_user_scheduled on public.todos(user_id, scheduled_date);
create index if not exists idx_todos_user_id on public.todos(user_id);

-- -----------------------------------------------------------------------------
-- 2. Table: idle_prompts
-- -----------------------------------------------------------------------------
create table if not exists public.idle_prompts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    prompt_text text not null,
    created_at timestamptz not null default now()
);

alter table public.idle_prompts enable row level security;
drop policy if exists "idle_prompts_user_policy" on public.idle_prompts;
create policy "idle_prompts_user_policy" on public.idle_prompts
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_idle_prompts_user_id on public.idle_prompts(user_id);

-- -----------------------------------------------------------------------------
-- 3. Table: subjects
-- -----------------------------------------------------------------------------
create table if not exists public.subjects (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    name text not null,
    sort_order integer not null default 0
);

alter table public.subjects enable row level security;
drop policy if exists "subjects_user_policy" on public.subjects;
create policy "subjects_user_policy" on public.subjects
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_subjects_user_id on public.subjects(user_id);

-- -----------------------------------------------------------------------------
-- 4. Table: modules
-- -----------------------------------------------------------------------------
create table if not exists public.modules (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    subject_id uuid not null references public.subjects(id) on delete cascade,
    title text not null,
    sort_order integer not null default 0
);

alter table public.modules enable row level security;
drop policy if exists "modules_user_policy" on public.modules;
create policy "modules_user_policy" on public.modules
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_modules_subject_id on public.modules(subject_id);
create index if not exists idx_modules_user_id on public.modules(user_id);

-- -----------------------------------------------------------------------------
-- 5. Table: chapters
-- -----------------------------------------------------------------------------
create table if not exists public.chapters (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    module_id uuid not null references public.modules(id) on delete cascade,
    title text not null,
    sort_order integer not null default 0
);

alter table public.chapters enable row level security;
drop policy if exists "chapters_user_policy" on public.chapters;
create policy "chapters_user_policy" on public.chapters
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_chapters_module_id on public.chapters(module_id);
create index if not exists idx_chapters_user_id on public.chapters(user_id);

-- -----------------------------------------------------------------------------
-- 6. Table: chapter_files
-- -----------------------------------------------------------------------------
create table if not exists public.chapter_files (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    chapter_id uuid not null references public.chapters(id) on delete cascade,
    file_name text not null,
    file_type text not null,
    file_size bigint not null default 0,
    storage_path text not null,
    created_at timestamptz not null default now()
);

alter table public.chapter_files enable row level security;
drop policy if exists "chapter_files_user_policy" on public.chapter_files;
create policy "chapter_files_user_policy" on public.chapter_files
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_chapter_files_chapter_id on public.chapter_files(chapter_id);
create index if not exists idx_chapter_files_user_id on public.chapter_files(user_id);

-- -----------------------------------------------------------------------------
-- 7. Table: academic_items
-- -----------------------------------------------------------------------------
create table if not exists public.academic_items (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    subject_id uuid references public.subjects(id) on delete set null,
    title text not null,
    item_type text not null check (item_type in ('assignment', 'exam')),
    due_date date not null,
    is_completed boolean not null default false,
    created_at timestamptz not null default now()
);

alter table public.academic_items enable row level security;
drop policy if exists "academic_items_user_policy" on public.academic_items;
create policy "academic_items_user_policy" on public.academic_items
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_academic_items_user_due on public.academic_items(user_id, due_date);
create index if not exists idx_academic_items_subject_id on public.academic_items(subject_id);
create index if not exists idx_academic_items_user_id on public.academic_items(user_id);

-- -----------------------------------------------------------------------------
-- 8. Table: expense_settings
-- -----------------------------------------------------------------------------
create table if not exists public.expense_settings (
    user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
    monthly_allowance numeric not null default 0,
    total_savings numeric not null default 0,
    last_reset_month text not null
);

alter table public.expense_settings enable row level security;
drop policy if exists "expense_settings_user_policy" on public.expense_settings;
create policy "expense_settings_user_policy" on public.expense_settings
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 9. Table: expense_transactions
-- -----------------------------------------------------------------------------
create table if not exists public.expense_transactions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    title text not null,
    category text not null,
    amount numeric not null check (amount > 0),
    tx_type text not null check (tx_type in ('spent', 'received', 'saved')),
    tx_date timestamptz not null default now()
);

alter table public.expense_transactions enable row level security;
drop policy if exists "expense_transactions_user_policy" on public.expense_transactions;
create policy "expense_transactions_user_policy" on public.expense_transactions
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_expense_transactions_user_tx_date on public.expense_transactions(user_id, tx_date);
create index if not exists idx_expense_transactions_user_id on public.expense_transactions(user_id);

-- -----------------------------------------------------------------------------
-- 10. Table: habits
-- -----------------------------------------------------------------------------
create table if not exists public.habits (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    title text not null,
    created_at timestamptz not null default now()
);

alter table public.habits enable row level security;
drop policy if exists "habits_user_policy" on public.habits;
create policy "habits_user_policy" on public.habits
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_habits_user_id on public.habits(user_id);

-- -----------------------------------------------------------------------------
-- 11. Table: habit_logs
-- -----------------------------------------------------------------------------
create table if not exists public.habit_logs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    habit_id uuid not null references public.habits(id) on delete cascade,
    log_date date not null,
    constraint habit_logs_habit_id_log_date_key unique (habit_id, log_date)
);

alter table public.habit_logs enable row level security;
drop policy if exists "habit_logs_user_policy" on public.habit_logs;
create policy "habit_logs_user_policy" on public.habit_logs
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_habit_logs_habit_date on public.habit_logs(habit_id, log_date);
create index if not exists idx_habit_logs_habit_id on public.habit_logs(habit_id);
create index if not exists idx_habit_logs_user_id on public.habit_logs(user_id);

-- -----------------------------------------------------------------------------
-- 12. Table: workout_days
-- -----------------------------------------------------------------------------
create table if not exists public.workout_days (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    weekday integer not null check (weekday between 1 and 7),
    split_title text not null,
    constraint workout_days_user_id_weekday_key unique (user_id, weekday)
);

alter table public.workout_days enable row level security;
drop policy if exists "workout_days_user_policy" on public.workout_days;
create policy "workout_days_user_policy" on public.workout_days
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_workout_days_user_id on public.workout_days(user_id);

-- -----------------------------------------------------------------------------
-- 13. Table: workout_exercises
-- -----------------------------------------------------------------------------
create table if not exists public.workout_exercises (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    workout_day_id uuid not null references public.workout_days(id) on delete cascade,
    exercise_name text not null,
    sets_reps text not null,
    last_completed_date date null
);

alter table public.workout_exercises enable row level security;
drop policy if exists "workout_exercises_user_policy" on public.workout_exercises;
create policy "workout_exercises_user_policy" on public.workout_exercises
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_workout_exercises_day_id on public.workout_exercises(workout_day_id);
create index if not exists idx_workout_exercises_user_id on public.workout_exercises(user_id);

-- -----------------------------------------------------------------------------
-- 14. Table: expense_month_summaries
-- -----------------------------------------------------------------------------
create table if not exists public.expense_month_summaries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    month text not null,
    allowance numeric not null default 0,
    received numeric not null default 0,
    spent numeric not null default 0,
    saved numeric not null default 0,
    remainder numeric not null default 0,
    carried_to_savings numeric not null default 0,
    closed_at timestamptz not null default now(),
    constraint expense_month_summaries_user_id_month_key unique (user_id, month)
);

alter table public.expense_month_summaries enable row level security;
drop policy if exists "expense_month_summaries_user_policy" on public.expense_month_summaries;
create policy "expense_month_summaries_user_policy" on public.expense_month_summaries
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_expense_month_summaries_user_id on public.expense_month_summaries(user_id);

-- =============================================================================
-- Storage Bucket & Security Policies
-- =============================================================================
insert into storage.buckets (id, name, public)
values ('academic_vault', 'academic_vault', false)
on conflict (id) do nothing;

drop policy if exists "academic_vault_select" on storage.objects;
create policy "academic_vault_select" on storage.objects
    for select using (
        bucket_id = 'academic_vault'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "academic_vault_insert" on storage.objects;
create policy "academic_vault_insert" on storage.objects
    for insert with check (
        bucket_id = 'academic_vault'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "academic_vault_update" on storage.objects;
create policy "academic_vault_update" on storage.objects
    for update using (
        bucket_id = 'academic_vault'
        and (storage.foldername(name))[1] = auth.uid()::text
    ) with check (
        bucket_id = 'academic_vault'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "academic_vault_delete" on storage.objects;
create policy "academic_vault_delete" on storage.objects
    for delete using (
        bucket_id = 'academic_vault'
        and (storage.foldername(name))[1] = auth.uid()::text
    );
