-- Migration: 003_chapter_studied.sql
-- Adds is_studied column to chapters table for syllabus studied progress tracking

alter table public.chapters
  add column if not exists is_studied boolean not null default false;
