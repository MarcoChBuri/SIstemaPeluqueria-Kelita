-- =========================================================
-- SCHEMA COMPLETO: Peluquería Raquel (Supabase / PostgreSQL)
-- Ejecuta este script en el SQL Editor de tu panel de Supabase
-- =========================================================

-- Limpiar tablas y tipos anteriores si existen (opcional)
DROP TABLE IF EXISTS citas CASCADE;
DROP TABLE IF EXISTS promociones CASCADE;
DROP TABLE IF EXISTS galeria_trabajos CASCADE;
DROP TABLE IF EXISTS cursos_hotmart CASCADE;
DROP TABLE IF EXISTS servicios CASCADE;
DROP TABLE IF EXISTS gastos CASCADE;
DROP TABLE IF EXISTS ventas_productos CASCADE;
DROP TABLE IF EXISTS ingresos_servicios CASCADE;
DROP TABLE IF EXISTS ingresos_cursos CASCADE;

DROP TYPE IF EXISTS categoria_gasto CASCADE;
DROP TYPE IF EXISTS estado_pago CASCADE;
DROP TYPE IF EXISTS estado_cita CASCADE;
DROP TYPE IF EXISTS categoria_servicio CASCADE;

-- 1. TIPOS ENUM PERSONALIZADOS
-- ---------------------------------------------------------

CREATE TYPE categoria_gasto AS ENUM (
  'arriendo',
  'servicios',
  'productos',
  'comida',
  'transporte',
  'otros'
);

CREATE TYPE estado_pago AS ENUM (
  'pagado',
  'pendiente'
);

CREATE TYPE estado_cita AS ENUM (
  'pendiente',
  'confirmada',
  'completada',
  'cancelada'
);

CREATE TYPE categoria_servicio AS ENUM (
  'corte',
  'colorimetria',
  'tratamiento',
  'peinado_maquillaje',
  'paquete_bodas',
  'paquete_quinceanera',
  'pestanas_cejas',
  'otro'
);


-- 2. TABLA DE SERVICIOS Y PAQUETES (Catálogo con Tiempos y Precios)
-- ---------------------------------------------------------

CREATE TABLE servicios (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  nombre           TEXT NOT NULL,
  categoria        categoria_servicio NOT NULL,
  descripcion      TEXT,
  duracion_minutos INTEGER NOT NULL CHECK (duracion_minutos > 0), -- Crucial para gestión de agenda
  precio_base      NUMERIC(10, 2) NOT NULL CHECK (precio_base >= 0),
  imagen_url       TEXT,
  activo           BOOLEAN NOT NULL DEFAULT true
);

COMMENT ON TABLE  servicios IS 'Catálogo de servicios individuales y paquetes para novias/eventos';
COMMENT ON COLUMN servicios.duracion_minutos IS 'Tiempo estimado en minutos para reservar el bloque en la agenda';


-- 3. TABLA DE PROMOCIONES Y DESCUENTOS DEL MES
-- ---------------------------------------------------------

CREATE TABLE promociones (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  titulo              TEXT NOT NULL,
  descripcion         TEXT,
  porcentaje_descuento INTEGER CHECK (porcentaje_descuento >= 0 AND porcentaje_descuento <= 100),
  monto_descuento     NUMERIC(10, 2) CHECK (monto_descuento >= 0),
  fecha_inicio        DATE NOT NULL DEFAULT CURRENT_DATE,
  fecha_fin           DATE NOT NULL,
  imagen_url          TEXT,
  activa              BOOLEAN NOT NULL DEFAULT true
);

COMMENT ON TABLE promociones IS 'Promociones y descuentos del mes para clientes que reserven online';


-- 4. TABLA DE CITAS / RESERVAS (Agenda de Clientes y Raquel)
-- ---------------------------------------------------------

CREATE TABLE citas (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  cliente_nombre     TEXT NOT NULL,
  cliente_telefono   TEXT NOT NULL,
  cliente_email      TEXT,
  servicio_id        UUID NOT NULL REFERENCES servicios(id) ON DELETE RESTRICT,
  promocion_id       UUID REFERENCES promociones(id) ON DELETE SET NULL,
  fecha_cita         DATE NOT NULL,
  hora_inicio        TIME NOT NULL,
  hora_fin           TIME NOT NULL,
  estado             estado_cita NOT NULL DEFAULT 'pendiente',
  estado_pago        estado_pago NOT NULL DEFAULT 'pendiente',
  precio_original    NUMERIC(10, 2) NOT NULL CHECK (precio_original >= 0),
  descuento_aplicado NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (descuento_aplicado >= 0),
  precio_final       NUMERIC(10, 2) NOT NULL CHECK (precio_final >= 0),
  notas              TEXT
);

COMMENT ON TABLE citas IS 'Agenda de reservas online y presenciales con cálculo de tiempos';


-- 5. TABLA DE GALERÍA Y PORTAFOLIO DE TRABAJOS
-- ---------------------------------------------------------

CREATE TABLE galeria_trabajos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  titulo      TEXT NOT NULL,
  categoria   TEXT NOT NULL, -- ej: 'Colorimetría', 'Novias', 'Alisados'
  imagen_url  TEXT NOT NULL,
  descripcion TEXT,
  destacado   BOOLEAN NOT NULL DEFAULT false
);

COMMENT ON TABLE galeria_trabajos IS 'Fotos de trabajos realizados por Raquel para mostrar a los clientes';


-- 6. TABLA DE CURSOS ONLINE (Conexión directa a Hotmart)
-- ---------------------------------------------------------

CREATE TABLE cursos_hotmart (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  titulo            TEXT NOT NULL,
  descripcion       TEXT NOT NULL,
  precio_referencia NUMERIC(10, 2) NOT NULL CHECK (precio_referencia >= 0),
  imagen_url        TEXT,
  link_hotmart      TEXT NOT NULL, -- Enlace directo a la página de compra en Hotmart
  activo            BOOLEAN NOT NULL DEFAULT true
);

COMMENT ON TABLE cursos_hotmart IS 'Cursos con redirección a Hotmart para delegar pagos y aulas';


-- 7. TABLA DE GASTOS OPERATIVOS (Control Financiero)
-- ---------------------------------------------------------

CREATE TABLE gastos (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha     TIMESTAMPTZ NOT NULL DEFAULT now(),
  concepto  TEXT,
  monto     NUMERIC(10, 2) NOT NULL CHECK (monto > 0),
  categoria categoria_gasto NOT NULL
);

COMMENT ON TABLE gastos IS 'Gastos diarios del negocio (arriendo, insumos, comida, transporte)';


-- 8. TABLA DE VENTA DE PRODUCTOS
-- ---------------------------------------------------------

CREATE TABLE ventas_productos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha           TIMESTAMPTZ NOT NULL DEFAULT now(),
  nombre_producto TEXT NOT NULL,
  nombre_cliente  TEXT,
  precio_costo    NUMERIC(10, 2) NOT NULL CHECK (precio_costo >= 0),
  precio_venta    NUMERIC(10, 2) NOT NULL CHECK (precio_venta > 0),
  cantidad        INTEGER NOT NULL DEFAULT 1 CHECK (cantidad > 0),
  estado_pago     estado_pago NOT NULL DEFAULT 'pagado'
);


-- 9. ÍNDICES PARA CONSULTAS RÁPIDAS
-- ---------------------------------------------------------

CREATE INDEX idx_citas_fecha_hora ON citas (fecha_cita, hora_inicio);
CREATE INDEX idx_citas_estado ON citas (estado);
CREATE INDEX idx_citas_servicio ON citas (servicio_id);
CREATE INDEX idx_servicios_categoria ON servicios (categoria);
CREATE INDEX idx_servicios_activo ON servicios (activo);
CREATE INDEX idx_promociones_vigencia ON promociones (fecha_inicio, fecha_fin, activa);
CREATE INDEX idx_gastos_fecha ON gastos (fecha DESC);


-- 10. SEGURIDAD (Row Level Security)
-- ---------------------------------------------------------

ALTER TABLE servicios        ENABLE ROW LEVEL SECURITY;
ALTER TABLE promociones      ENABLE ROW LEVEL SECURITY;
ALTER TABLE citas            ENABLE ROW LEVEL SECURITY;
ALTER TABLE galeria_trabajos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cursos_hotmart   ENABLE ROW LEVEL SECURITY;
ALTER TABLE gastos           ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas_productos ENABLE ROW LEVEL SECURITY;

-- Políticas de lectura pública (los clientes pueden ver servicios, promos, galería y cursos)
CREATE POLICY "Lectura pública de servicios activos"
  ON servicios FOR SELECT USING (activo = true);

CREATE POLICY "Lectura pública de promociones activas"
  ON promociones FOR SELECT USING (activa = true);

CREATE POLICY "Lectura pública de galería"
  ON galeria_trabajos FOR SELECT USING (true);

CREATE POLICY "Lectura pública de cursos"
  ON cursos_hotmart FOR SELECT USING (activo = true);

-- Políticas para el Backend (Acceso total vía service_role)
CREATE POLICY "Acceso total backend - servicios" ON servicios FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total backend - promociones" ON promociones FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total backend - citas" ON citas FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total backend - galeria" ON galeria_trabajos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total backend - cursos" ON cursos_hotmart FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total backend - gastos" ON gastos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total backend - ventas" ON ventas_productos FOR ALL USING (true) WITH CHECK (true);


-- =========================================================
-- DATOS SEMILLA INICIALES (Para que no esté vacía)
-- =========================================================

INSERT INTO servicios (nombre, categoria, descripcion, duracion_minutos, precio_base) VALUES
('Balayage & Colorimetría Premium', 'colorimetria', 'Diseño de color personalizado, decoloración y matiz con tratamiento hidratante', 180, 85.00),
('Corte de Cabello & Peinado Damas', 'corte', 'Lavado especial, asesoría de visagismo, corte y secado con ondas', 45, 15.00),
('Corte de Cabello Caballeros', 'corte', 'Degradado / clásico con lavado y perfilado', 30, 8.00),
('Alisado Orgánico Pro', 'tratamiento', 'Tratamiento sin formol que reestructura y alisa el cabello hasta por 4 meses', 150, 70.00),
('Paquete Novia Radiante (Boda)', 'paquete_bodas', 'Prueba de peinado + peinado día del evento + maquillaje blindado con fijación 24h + colocación de velo', 240, 150.00),
('Paquete Quinceañera Encantada', 'paquete_quinceanera', 'Maquillaje profesional HD + peinado con corona/tocado + pestañas punto a punto', 180, 95.00),
('Lifting de Pestañas & Perfilado Cejas', 'pestanas_cejas', 'Curvatura natural de pestañas con keratina y diseño de cejas con tinte henna', 60, 25.00);

INSERT INTO promociones (titulo, descripcion, porcentaje_descuento, fecha_inicio, fecha_fin, activa) VALUES
('Martes & Miércoles de Alisados', '20% de descuento en Alisado Orgánico reservando online de martes a miércoles', 20, CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', true),
('Pack Novia Anticipada', '$20 de descuento reservando tu paquete de boda con al menos 15 días de anticipación', NULL, CURRENT_DATE, CURRENT_DATE + INTERVAL '60 days', true);

INSERT INTO cursos_hotmart (titulo, descripcion, precio_referencia, link_hotmart, activo) VALUES
('Masterclass Online: Colorimetría desde Cero a Experta', 'Aprende las fórmulas secretas de decoloración, fondos de aclaración y matices perfectos sin maltratar el cabello.', 47.00, 'https://hotmart.com', true),
('Curso Digital: Técnicas de Peinados de Novia y Quinceañeras', 'Domina las ondas glam, semirecogidos y técnicas de fijación profesional paso a paso.', 35.00, 'https://hotmart.com', true);

INSERT INTO galeria_trabajos (titulo, categoria, imagen_url, descripcion, destacado) VALUES
('Transformación Balayage Rubio Vainilla', 'Colorimetría', 'https://images.unsplash.com/photo-1560869713-7d0a29430803?auto=format&fit=crop&w=800&q=80', 'Aclaración nivel 9 con matiz cenizo y baño de brillo.', true),
('Novia Estilo Romántico', 'Novias', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=800&q=80', 'Semirecogido con ondas suaves y tocado floral.', true),
('Alisado Espejo Brillo Extremo', 'Tratamientos', 'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?auto=format&fit=crop&w=800&q=80', 'Cabello liso, sedoso y sin frizz.', true);

Create table resenas (
  id  UUID PRIMARY KEY 
);