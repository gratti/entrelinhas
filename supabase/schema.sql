-- Entrelinhas: schema para sessões e meta diária por usuário
create table public.reading_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  book text not null default 'Momento de leitura',
  minutes integer not null check (minutes between 1 and 600),
  pages integer not null default 0 check (pages >= 0),
  read_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.reading_preferences (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  daily_goal_minutes integer not null default 20 check (daily_goal_minutes between 1 and 600),
  updated_at timestamptz not null default now()
);

alter table public.reading_sessions enable row level security;
alter table public.reading_preferences enable row level security;

revoke all on public.reading_sessions from anon, authenticated;
revoke all on public.reading_preferences from anon, authenticated;
grant select, insert, update, delete on public.reading_sessions to authenticated;
grant select, insert, update, delete on public.reading_preferences to authenticated;

create policy "Cada pessoa vê suas leituras"
  on public.reading_sessions for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Cada pessoa registra suas leituras"
  on public.reading_sessions for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Cada pessoa altera suas leituras"
  on public.reading_sessions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Cada pessoa apaga suas leituras"
  on public.reading_sessions for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "Cada pessoa lê sua meta"
  on public.reading_preferences for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Cada pessoa cria sua meta"
  on public.reading_preferences for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Cada pessoa altera sua meta"
  on public.reading_preferences for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Cada pessoa apaga sua meta"
  on public.reading_preferences for delete to authenticated
  using ((select auth.uid()) = user_id);

