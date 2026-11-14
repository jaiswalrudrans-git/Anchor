-- Migration: 004_habit_icon.sql
-- Adds icon column to habits table for custom habit icons

alter table public.habits
  add column if not exists icon text not null default 'check_circle';
