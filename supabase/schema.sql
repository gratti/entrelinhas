-- Entrelinhas: livros, sessões e meta diária por usuário
create table public.reading_books (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  book text not null check (char_length(trim(book)) > 0),
  status text not null default 'reading' check (status in ('reading', 'finished')),
  current_page integer not null default 0 check (current_page >= 0),
  finished_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index reading_books_user_book_unique
  on public.reading_books (user_id, lower(trim(book)));

create table public.reading_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  reading_book_id uuid references public.reading_books(id) on delete set null,
  book text not null default 'Momento de leitura',
  minutes integer not null check (minutes between 1 and 600),
  pages integer not null default 0 check (pages >= 0),
  stopped_at_page integer check (stopped_at_page is null or stopped_at_page >= 0),
  note text check (note is null or char_length(note) <= 300),
  read_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.reading_preferences (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  daily_goal_minutes integer not null default 20 check (daily_goal_minutes between 1 and 600),
  updated_at timestamptz not null default now()
);

alter table public.reading_books enable row level security;
alter table public.reading_sessions enable row level security;
alter table public.reading_preferences enable row level security;

revoke all on public.reading_books from anon, authenticated;
revoke all on public.reading_sessions from anon, authenticated;
revoke all on public.reading_preferences from anon, authenticated;
grant select, insert, update, delete on public.reading_books to authenticated;
grant select, insert, update, delete on public.reading_sessions to authenticated;
grant select, insert, update, delete on public.reading_preferences to authenticated;

create policy "Cada pessoa vê seus livros"
  on public.reading_books for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Cada pessoa cria seus livros"
  on public.reading_books for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Cada pessoa altera seus livros"
  on public.reading_books for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Cada pessoa apaga seus livros"
  on public.reading_books for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "Cada pessoa vê suas leituras"
  on public.reading_sessions for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Cada pessoa registra suas leituras"
  on public.reading_sessions for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and (
      reading_book_id is null
      or exists (
        select 1 from public.reading_books b
        where b.id = reading_book_id
          and b.user_id = (select auth.uid())
      )
    )
  );
create policy "Cada pessoa altera suas leituras"
  on public.reading_sessions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and (
      reading_book_id is null
      or exists (
        select 1 from public.reading_books b
        where b.id = reading_book_id
          and b.user_id = (select auth.uid())
      )
    )
  );
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

