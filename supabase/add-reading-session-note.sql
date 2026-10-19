-- Execute este arquivo uma vez no Supabase SQL Editor para habilitar notas nas sessões existentes.
alter table public.reading_sessions
  add column if not exists note text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.reading_sessions'::regclass
      and conname = 'reading_sessions_note_length_check'
  ) then
    alter table public.reading_sessions
      add constraint reading_sessions_note_length_check
      check (note is null or char_length(note) <= 300);
  end if;
end
$$;
