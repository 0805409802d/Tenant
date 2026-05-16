-- Reemplaza 'PEGA-AQUI-EL-UUID' con el UUID copiado
insert into public.profiles (id, email, role)
values (
  'cc6b7a85-f154-48e2-b3e1-ab8d44bd86a9',
  '0805409802d@tenant.com',
  'admin'
);

insert into public.admin_access (profile_id, secret_path)
values (
  'cc6b7a85-f154-48e2-b3e1-ab8d44bd86a9',
  'd8t1-admin-panel'
);