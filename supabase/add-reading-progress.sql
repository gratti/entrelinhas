-- Execute este arquivo uma vez no Supabase SQL Editor para guardar a página onde cada sessão terminou.
alter table public.reading_sessions
  add column if not exists stopped_at_page integer;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.reading_sessions'::regclass
      and conname = 'reading_sessions_stopped_at_page_check'
  ) then
    alter table public.reading_sessions
      add constraint reading_sessions_stopped_at_page_check
      check (stopped_at_page is null or stopped_at_page >= 0);
  end if;
end
$$;
