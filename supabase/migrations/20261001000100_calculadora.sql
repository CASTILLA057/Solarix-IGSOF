-- Solarix — calculadora solar (Etapa 3)
-- Tablas de consulta para la calculadora: precios de referencia y ciudades
-- con su recurso solar. Cualquier usuario con sesión puede leerlas; solo se
-- editan desde el panel de Supabase o con una nueva migración.

-- ---------------------------------------------------------------------------
-- precios_referencia: precios en COP, editables en la app por cálculo
-- ---------------------------------------------------------------------------
create table public.precios_referencia (
  clave           text primary key,
  valor           numeric not null check (valor >= 0),
  unidad          text not null,
  descripcion     text not null,
  actualizado_en  timestamptz not null default now()
);

alter table public.precios_referencia enable row level security;

create policy "precios: leer con sesión"
  on public.precios_referencia for select to authenticated
  using (true);

-- Precios de tiendas colombianas, octubre de 2026 (fuentes en docs/BITACORA.md).
-- Calibrados para que un sistema residencial instalado quede entre 2 y 5,5
-- millones COP por kWp, el rango del mercado con RETIE y trámites.
-- Deben coincidir con Precios.referencia en lib/features/calculadora/domain/modelos.dart.
insert into public.precios_referencia (clave, valor, unidad, descripcion) values
  ('panel_por_wp',           1050,    'COP/Wp',  'Panel solar monocristalino de 550 W (~ $580.000)'),
  ('inversor_red_por_w',     900,     'COP/W',   'Inversor de conexión a red (5 kW ~ $4,7 M)'),
  ('inversor_aislado_por_w', 1000,    'COP/W',   'Inversor aislado o híbrido (5 kW: $2,4 M a $8 M)'),
  ('bateria_litio_por_kwh',  820000,  'COP/kWh', 'Batería LiFePO4 48 V 100 Ah, 5,12 kWh ($3,6 M a $4,7 M)'),
  ('bateria_plomo_por_kwh',  650000,  'COP/kWh', 'Batería de gel 12 V 200 Ah, 2,4 kWh (~ $1,6 M)'),
  ('controlador_por_a',      12000,   'COP/A',   'Controlador de carga MPPT (60 A ~ $700.000)'),
  ('estructura_por_panel',   300000,  'COP',     'Estructura, cableado y protecciones por panel'),
  ('instalacion_porcentaje', 0.30,    'fracción','Mano de obra, certificación RETIE y trámites con el operador'),
  ('instalacion_minima',     1500000, 'COP',     'Costo mínimo de instalación, RETIE y trámites');

-- ---------------------------------------------------------------------------
-- ciudades: horas solares pico (HSP) promedio anual, kWh/m²/día
-- ---------------------------------------------------------------------------
create table public.ciudades (
  id            smallint generated always as identity primary key,
  nombre        text not null,
  departamento  text not null,
  hsp           numeric(3, 1) not null check (hsp between 2 and 8),
  unique (nombre, departamento)
);

alter table public.ciudades enable row level security;

create policy "ciudades: leer con sesión"
  on public.ciudades for select to authenticated
  using (true);

-- HSP de NASA POWER (ALLSKY_SFC_SW_DWN, promedio anual) consultadas el
-- 2026-10-01 en las coordenadas de cada ciudad, redondeadas a un decimal.
-- Deben coincidir con ciudadesBase en
-- lib/features/calculadora/domain/catalogos.dart (respaldo sin internet).
insert into public.ciudades (nombre, departamento, hsp) values
  ('Arauca',        'Arauca',                   5.0),
  ('Armenia',       'Quindío',                  4.5),
  ('Barranquilla',  'Atlántico',                5.4),
  ('Bogotá',        'Bogotá D. C.',             4.6),
  ('Bucaramanga',   'Santander',                5.1),
  ('Cali',          'Valle del Cauca',          4.2),
  ('Cartagena',     'Bolívar',                  5.3),
  ('Cúcuta',        'Norte de Santander',       4.3),
  ('Florencia',     'Caquetá',                  4.4),
  ('Ibagué',        'Tolima',                   4.5),
  ('Leticia',       'Amazonas',                 4.6),
  ('Manizales',     'Caldas',                   4.8),
  ('Medellín',      'Antioquia',                4.9),
  ('Montería',      'Córdoba',                  5.0),
  ('Neiva',         'Huila',                    4.2),
  ('Ocaña',         'Norte de Santander',       5.0),
  ('Pasto',         'Nariño',                   4.0),
  ('Pereira',       'Risaralda',                4.5),
  ('Popayán',       'Cauca',                    4.1),
  ('Quibdó',        'Chocó',                    4.0),
  ('Riohacha',      'La Guajira',               5.5),
  ('San Andrés',    'San Andrés y Providencia', 5.3),
  ('Santa Marta',   'Magdalena',                5.7),
  ('Sincelejo',     'Sucre',                    5.1),
  ('Tunja',         'Boyacá',                   4.5),
  ('Valledupar',    'Cesar',                    5.3),
  ('Villavicencio', 'Meta',                     4.3),
  ('Yopal',         'Casanare',                 4.5);
