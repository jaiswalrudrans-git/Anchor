-- -----------------------------------------------------------------------------
-- Migration 002: Ensure unique idle prompts per user to prevent duplicate seeds
-- -----------------------------------------------------------------------------
do $$
begin
    if not exists (
        select 1 from pg_constraint where conname = 'idle_prompts_user_id_prompt_text_key'
    ) then
        alter table public.idle_prompts
            add constraint idle_prompts_user_id_prompt_text_key unique (user_id, prompt_text);
    end if;
end $$;
