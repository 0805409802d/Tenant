-- Reemplaza 'PEGA-AQUI-EL-UUID' con el UUID copiado
insert into public.profiles (id, email, role)
values (
  '07d71597-54c0-4bea-a4cd-d435fdcad385',
  '0805409802d@tenant.com',
  'admin'
);

insert into public.admin_access (profile_id, secret_path)
values (
  '07d71597-54c0-4bea-a4cd-d435fdcad385',
  'd8t1-admin-panel'
);