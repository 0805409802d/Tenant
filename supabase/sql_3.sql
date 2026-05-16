alter table public.profiles 
  add column if not exists first_name text,
  add column if not exists last_name text,
  add column if not exists phone text,
  add column if not exists avatar_url text,
  add column if not exists business_name text,
  add column if not exists owner_name text,
  add column if not exists country text,
  add column if not exists city text,
  add column if not exists address text,
  add column if not exists interface_color text default '#000000',
  add column if not exists logo_url text;

create table public.security_questions (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id) on delete cascade,
  question_1 text not null,
  answer_1 text not null,
  question_2 text not null,
  answer_2 text not null,
  question_3 text not null,
  answer_3 text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  unique(profile_id)
);

alter table public.security_questions enable row level security;

create policy "Users manage own questions"
  on public.security_questions for all
  using (auth.uid() = profile_id);

