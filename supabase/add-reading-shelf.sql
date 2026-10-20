-- Execute este arquivo uma vez no Supabase SQL Editor para habilitar Minha estante.
-- Os livros existentes são criados a partir das sessões e os registros são vinculados a eles.

create table if not exists public.reading_books (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  book text not null check (char_length(trim(book)) > 0),
  status text not null default 'reading' check (status in ('reading', 'finished')),
  current_page integer not null default 0 check (current_page >= 0),
  finished_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists reading_books_user_book_unique
  on public.reading_books (user_id, lower(trim(book)));

alter table public.reading_books enable row level security;
revoke all on public.reading_books from anon, authenticated;
grant select, insert, update, delete on public.reading_books to authenticated;

drop policy if exists "Cada pessoa vê seus livros" on public.reading_books;
create policy "Cada pessoa vê seus livros"
  on public.reading_books for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Cada pessoa cria seus livros" on public.reading_books;
create policy "Cada pessoa cria seus livros"
  on public.reading_books for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Cada pessoa altera seus livros" on public.reading_books;
create policy "Cada pessoa altera seus livros"
  on public.reading_books for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Cada pessoa apaga seus livros" on public.reading_books;
create policy "Cada pessoa apaga seus livros"
  on public.reading_books for delete to authenticated
  using ((select auth.uid()) = user_id);

alter table public.reading_sessions
  add column if not exists reading_book_id uuid references public.reading_books(id) on delete set null;

-- Recria a estante de forma segura a partir das sessões já existentes.
insert into public.reading_books (user_id, book, status, current_page)
select distinct on (s.user_id, lower(trim(s.book)))
  s.user_id,
  trim(s.book),
  'reading',
  coalesce((
    select last_session.stopped_at_page
    from public.reading_sessions as last_session
    where last_session.user_id = s.user_id
      and lower(trim(last_session.book)) = lower(trim(s.book))
      and last_session.stopped_at_page is not null
    order by last_session.read_at desc, last_session.created_at desc
    limit 1
  ), 0)
from public.reading_sessions as s
where s.user_id is not null
  and s.book is not null
  and trim(s.book) <> ''
  and trim(s.book) <> 'Momento de leitura'
order by s.user_id, lower(trim(s.book)), s.read_at desc
on conflict do nothing;

update public.reading_sessions as s
set reading_book_id = b.id
from public.reading_books as b
where s.reading_book_id is null
  and s.user_id = b.user_id
  and lower(trim(s.book)) = lower(trim(b.book));

-- Garante que uma sessão só possa apontar para um livro da própria conta.
drop policy if exists "Cada pessoa registra suas leituras" on public.reading_sessions;
create policy "Cada pessoa registra suas leituras"
  on public.reading_sessions for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and (
      reading_book_id is null
      or exists (
        select 1 from public.reading_books as b
        where b.id = reading_book_id
          and b.user_id = (select auth.uid())
      )
    )
  );

drop policy if exists "Cada pessoa altera suas leituras" on public.reading_sessions;
create policy "Cada pessoa altera suas leituras"
  on public.reading_sessions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and (
      reading_book_id is null
      or exists (
        select 1 from public.reading_books as b
        where b.id = reading_book_id
          and b.user_id = (select auth.uid())
      )
    )
  );
