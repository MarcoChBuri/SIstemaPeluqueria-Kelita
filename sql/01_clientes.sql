-- =========================================================
-- TABLA DE CLIENTES Y SINCRONIZACIÓN AUTOMÁTICA
-- Ejecuta este script en el SQL Editor de tu panel de Supabase
-- =========================================================

CREATE TABLE IF NOT EXISTS clientes (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  nombre               TEXT NOT NULL,
  telefono             TEXT NOT NULL,
  telefono_normalizado TEXT,
  email                TEXT,
  notas                TEXT,
  total_citas          INTEGER NOT NULL DEFAULT 0,
  total_gastado        NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  ultima_visita        DATE,
  activo               BOOLEAN NOT NULL DEFAULT true
);

-- Índices para búsqueda rápida y deduplicación por teléfono
CREATE UNIQUE INDEX IF NOT EXISTS idx_clientes_telefono_normalizado 
  ON clientes (telefono_normalizado) 
  WHERE activo = true AND telefono_normalizado IS NOT NULL AND telefono_normalizado != '';

CREATE INDEX IF NOT EXISTS idx_clientes_nombre ON clientes (nombre);
CREATE INDEX IF NOT EXISTS idx_clientes_email ON clientes (email);

-- Comentarios explicativos
COMMENT ON TABLE clientes IS 'Directorio sincronizado de clientas (web y app móvil) con historial de visitas';
COMMENT ON COLUMN clientes.telefono_normalizado IS 'Número de teléfono limpio (solo dígitos) para evitar duplicados';

-- Poblar la tabla de clientes con citas históricas existentes (sin duplicar)
INSERT INTO clientes (nombre, telefono, telefono_normalizado, email, notas, total_citas, total_gastado, ultima_visita)
SELECT
  c.cliente_nombre,
  c.cliente_telefono,
  regexp_replace(c.cliente_telefono, '[^0-9]', '', 'g') AS tel_norm,
  MAX(c.cliente_email) AS email,
  MAX(c.notas) AS notas,
  COUNT(*)::INTEGER AS total_citas,
  COALESCE(SUM(CASE WHEN c.estado_pago = 'pagado' OR c.estado = 'completada' THEN c.precio_final ELSE 0 END), 0)::NUMERIC(10,2) AS total_gastado,
  MAX(c.fecha_cita) AS ultima_visita
FROM citas c
WHERE c.cliente_telefono IS NOT NULL AND TRIM(c.cliente_telefono) != ''
GROUP BY c.cliente_nombre, regexp_replace(c.cliente_telefono, '[^0-9]', '', 'g')
ON CONFLICT (telefono_normalizado) DO UPDATE SET
  total_citas = EXCLUDED.total_citas,
  total_gastado = EXCLUDED.total_gastado,
  ultima_visita = EXCLUDED.ultima_visita;
