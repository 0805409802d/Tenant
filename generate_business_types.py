import json

categories = {
    "Alimentos y Bebidas": [
        "Restaurante", "Cafetería", "Panadería", "Pizzería", "Heladería", "Bar", "Comida Rápida", "Food Truck", 
        "Marisquería", "Taquería", "Asadero", "Pastelería", "Carnicería", "Frutería y Verdulería", "Minimarket", 
        "Supermercado", "Licorería", "Cervecería Artesanal", "Comida Vegana", "Sushi Bar", "Chocolatería", 
        "Tienda de Suplementos", "Distribuidora de Alimentos", "Café de Especialidad", "Venta de Snacks"
    ],
    "Salud y Belleza": [
        "Barbería", "Peluquería", "Spa", "Centro de Estética", "Gimnasio", "Farmacia", "Clínica Dental", "Óptica", 
        "Nutricionista", "Psicología", "Masajes", "Estudio de Tatuajes", "Salón de Uñas", "Depilación", 
        "Clínica Médica", "Laboratorio Clínico", "Tienda de Cosméticos", "Yoga y Pilates", "Centro de Fisioterapia", 
        "Perfumería"
    ],
    "Moda y Accesorios": [
        "Tienda de Ropa", "Zapatería", "Boutique", "Ropa Deportiva", "Ropa de Bebé", "Lencería", "Joyería", 
        "Relojería", "Accesorios de Moda", "Tienda de Bolsos", "Ropa de Tallas Grandes", "Sastrería", "Alquiler de Trajes",
        "Ropa Vintage", "Uniformes Escolares y Médicos"
    ],
    "Hogar y Construcción": [
        "Ferretería", "Mueblería", "Decoración", "Vivero y Plantas", "Materiales de Construcción", "Electrodomésticos", 
        "Pinturas", "Iluminación", "Cerrajería", "Vidriería", "Plomería", "Carpintería", "Artículos de Limpieza", 
        "Tienda de Colchones", "Venta de Cortinas"
    ],
    "Tecnología y Electrónica": [
        "Tienda de Celulares", "Computación", "Reparación de Celulares", "Accesorios Tecnológicos", "Videojuegos", 
        "Seguridad y Cámaras", "Venta de Drones", "Reparación de Computadoras", "Impresoras y Suministros", "Venta de Audio"
    ],
    "Vehículos y Transporte": [
        "Taller Mecánico", "Lavadora de Autos", "Venta de Repuestos", "Concesionario", "Venta de Motocicletas", "Llantera", 
        "Accesorios para Autos", "Taller de Pintura Automotriz", "Alquiler de Autos", "Bicicletería"
    ],
    "Servicios Profesionales": [
        "Estudio de Abogados", "Contabilidad", "Agencia de Marketing", "Arquitectura", "Inmobiliaria", "Fotografía", 
        "Imprenta", "Desarrollo de Software", "Consultoría Empresarial", "Agencia de Empleos"
    ],
    "Mascotas": [
        "Veterinaria", "Tienda de Mascotas", "Peluquería Canina", "Adiestramiento Canino", "Hotel para Mascotas"
    ],
    "Turismo y Eventos": [
        "Hotel", "Agencia de Viajes", "Hostal", "Florería", "Organización de Eventos", "Salón de Eventos", 
        "Catering", "Alquiler de Equipos para Fiestas"
    ],
    "Educación": [
        "Academia de Idiomas", "Guardería", "Escuela de Conducción", "Tutorías", "Centro de Capacitación", "Librería"
    ]
}

# Generic base tags for categories
base_tags = {
    "Alimentos y Bebidas": ["comida", "delicioso", "fresco", "sabor", "calidad", "gastronomía", "local", "alimentos", "bebidas", "atención", "excelente", "recomendado"],
    "Salud y Belleza": ["salud", "belleza", "cuidado", "bienestar", "estética", "profesional", "atención", "relax", "resultados", "confianza", "servicio", "calidad"],
    "Moda y Accesorios": ["moda", "estilo", "tendencia", "ropa", "vestimenta", "accesorios", "calidad", "outfit", "look", "colección", "diseño", "elegancia"],
    "Hogar y Construcción": ["hogar", "casa", "construcción", "herramientas", "calidad", "decoración", "durabilidad", "materiales", "remodelación", "espacios", "confort", "diseño"],
    "Tecnología y Electrónica": ["tecnología", "innovación", "gadgets", "electrónica", "moderno", "digital", "equipos", "calidad", "garantía", "servicio", "novedad", "accesorios"],
    "Vehículos y Transporte": ["autos", "vehículos", "motor", "transporte", "repuestos", "mantenimiento", "seguridad", "confianza", "calidad", "servicio", "taller", "movilidad"],
    "Servicios Profesionales": ["profesional", "servicio", "asesoría", "consultoría", "soluciones", "experiencia", "calidad", "atención", "confianza", "resultados", "gestión", "estrategia"],
    "Mascotas": ["mascotas", "animales", "perros", "gatos", "cuidado", "amor", "veterinaria", "salud", "bienestar", "accesorios", "alimentación", "juguetes"],
    "Turismo y Eventos": ["viajes", "turismo", "eventos", "experiencias", "fiesta", "celebración", "inolvidable", "diversión", "hotel", "hospedaje", "vacaciones", "descanso"],
    "Educación": ["educación", "aprendizaje", "cursos", "clases", "conocimiento", "estudio", "formación", "desarrollo", "profesionales", "enseñanza", "futuro", "academia"]
}

sql_content = """-- ─────────────────────────────────────────────────────────────────────────────
-- TIPOS DE NEGOCIOS Y ETIQUETAS SEO PARA LA PLATAFORMA (100+ Opciones)
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.business_types (
  id serial primary key,
  name text not null,
  seo_tags text[] not null
);

-- Habilitar RLS para permitir la lectura pública en el formulario de registro
alter table public.business_types enable row level security;

-- Política de lectura pública
do $$ 
begin
  if not exists (select 1 from pg_policies where policyname = 'Business types are viewable by everyone' and tablename = 'business_types') then
    create policy "Business types are viewable by everyone" on public.business_types for select using (true);
  end if;
end $$;

-- Limpiar tabla para insertar los nuevos
truncate table public.business_types restart identity cascade;

insert into public.business_types (name, seo_tags) values
"""

values = []
for cat, items in categories.items():
    for item in items:
        # Generar 20 tags (mezcla del item en minusculas, palabras clave de la categoria)
        tags = [item.lower()] + [t.lower() for t in item.split()] + base_tags[cat]
        # remove duplicates, keep order
        unique_tags = list(dict.fromkeys(tags))
        # Ensure we have around 15-20 tags by repeating with variations if needed
        variations = [f"mejor {item.lower()}", f"{item.lower()} cerca", f"{item.lower()} online", "promociones", "descuentos", "ofertas"]
        unique_tags.extend(variations)
        unique_tags = list(dict.fromkeys(unique_tags))[:20] # Take exactly up to 20
        
        tags_str = "array[" + ",".join([f"'{t.replace(chr(39), chr(39)+chr(39))}'" for t in unique_tags]) + "]"
        values.append(f"('{item.replace(chr(39), chr(39)+chr(39))}', {tags_str})")

sql_content += ",\n".join(values) + ";\n"

with open("supabase/sql_4.sql", "w", encoding="utf-8") as f:
    f.write(sql_content)

print("sql_4.sql generated with 100+ items")
