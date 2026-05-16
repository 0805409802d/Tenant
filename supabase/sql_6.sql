-- ─────────────────────────────────────────────────────────────────────────────
-- FUNCIÓN RPC: obtener preguntas de seguridad por email (sin exponer respuestas)
-- SECURITY DEFINER omite RLS para este caso específico y controlado.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.get_security_questions_by_email(user_email text)
returns table(question_1 text, question_2 text, question_3 text)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
    select sq.question_1, sq.question_2, sq.question_3
    from public.security_questions sq
    join public.profiles p on p.id = sq.profile_id
    where lower(p.email) = lower(user_email)
    limit 1;
end;
$$;