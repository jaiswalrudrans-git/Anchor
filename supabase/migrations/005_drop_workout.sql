-- Removes the Workout feature. This permanently deletes all workout data.
drop table if exists public.workout_exercises cascade;
drop table if exists public.workout_days cascade;
