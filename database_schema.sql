-- ====================================================================
-- ESQUEMA DE BASE DE DATOS PARA BOT DE INMUEBLES
-- Base de datos: PostgreSQL (Supabase)
-- ====================================================================

-- Habilitar extensión para UUID (si no está habilitada)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ====================================================================
-- TABLA: conversaciones
-- Almacena el estado y contexto de cada conversación con un usuario
-- ====================================================================

CREATE TABLE IF NOT EXISTS conversaciones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  telegram_user_id BIGINT UNIQUE NOT NULL,
  estado TEXT DEFAULT 'inicio',
  contexto JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índice para búsquedas rápidas por telegram_user_id
CREATE INDEX IF NOT EXISTS idx_conversaciones_telegram_user_id 
ON conversaciones(telegram_user_id);

-- Comentarios para documentación
COMMENT ON TABLE conversaciones IS 'Almacena el estado de conversaciones activas con usuarios';
COMMENT ON COLUMN conversaciones.telegram_user_id IS 'ID único del usuario en Telegram';
COMMENT ON COLUMN conversaciones.estado IS 'Estado actual: inicio, recopilando, completo';
COMMENT ON COLUMN conversaciones.contexto IS 'Historial de conversación y datos recopilados (JSON)';

-- ====================================================================
-- TABLA: propiedades
-- Almacena la información completa de las propiedades registradas
-- ====================================================================

CREATE TABLE IF NOT EXISTS propiedades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  telegram_user_id BIGINT NOT NULL,
  
  -- Información de la propiedad
  tipo_inmueble TEXT,
  ciudad TEXT,
  barrio TEXT,
  direccion TEXT,
  
  -- Datos numéricos (normalizados)
  precio TEXT,  -- Almacenado como texto para evitar problemas de precisión
  area_m2 DECIMAL(10, 2),
  habitaciones INTEGER,
  banos INTEGER,
  estrato INTEGER CHECK (estrato >= 1 AND estrato <= 6),
  
  -- Características y fotos
  caracteristicas TEXT[],
  fotos_urls TEXT[],
  
  -- Información del propietario
  nombre_propietario TEXT,
  telefono_propietario TEXT,
  
  -- Metadata
  estado TEXT DEFAULT 'recopilando',
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- Relación con conversaciones
  FOREIGN KEY (telegram_user_id) REFERENCES conversaciones(telegram_user_id)
    ON DELETE CASCADE
);

-- Índices para búsquedas
CREATE INDEX IF NOT EXISTS idx_propiedades_telegram_user_id 
ON propiedades(telegram_user_id);

CREATE INDEX IF NOT EXISTS idx_propiedades_ciudad 
ON propiedades(ciudad);

CREATE INDEX IF NOT EXISTS idx_propiedades_tipo_inmueble 
ON propiedades(tipo_inmueble);

CREATE INDEX IF NOT EXISTS idx_propiedades_created_at 
ON propiedades(created_at DESC);

-- Comentarios para documentación
COMMENT ON TABLE propiedades IS 'Información completa de propiedades registradas';
COMMENT ON COLUMN propiedades.precio IS 'Precio normalizado (sin símbolos ni separadores)';
COMMENT ON COLUMN propiedades.area_m2 IS 'Área en metros cuadrados (normalizada)';
COMMENT ON COLUMN propiedades.fotos_urls IS 'Array de file_ids de Telegram para las fotos';
COMMENT ON COLUMN propiedades.estado IS 'Estado: recopilando, completo, publicado';

-- ====================================================================
-- DATOS DE EJEMPLO (OPCIONAL)
-- ====================================================================

-- Ejemplo de conversación
INSERT INTO conversaciones (telegram_user_id, estado, contexto) 
VALUES (
  123456789,
  'recopilando',
  '{
    "historial": [
      {"role": "user", "content": "Hola"},
      {"role": "assistant", "content": "\u00a1Hola! Te ayudaré a registrar tu propiedad."}
    ],
    "tipo_inmueble": "apartamento",
    "ciudad": "Bogotá"
  }'
) ON CONFLICT (telegram_user_id) DO NOTHING;

-- Ejemplo de propiedad completa
INSERT INTO propiedades (
  telegram_user_id,
  tipo_inmueble,
  ciudad,
  barrio,
  precio,
  area_m2,
  habitaciones,
  banos,
  estrato,
  caracteristicas,
  fotos_urls,
  nombre_propietario,
  telefono_propietario,
  estado
) VALUES (
  123456789,
  'apartamento',
  'Bogotá',
  'Chapinero',
  '500000000',
  120.50,
  3,
  2,
  4,
  ARRAY['parqueadero', 'balcón', 'gimnasio'],
  ARRAY['file_id_1', 'file_id_2', 'file_id_3'],
  'Juan Pérez',
  '3001234567',
  'completo'
) ON CONFLICT DO NOTHING;

-- ====================================================================
-- CONSULTAS ÚTILES
-- ====================================================================

-- Ver todas las conversaciones activas
-- SELECT * FROM conversaciones WHERE estado != 'completo' ORDER BY updated_at DESC;

-- Ver todas las propiedades completadas
-- SELECT * FROM propiedades WHERE estado = 'completo' ORDER BY created_at DESC;

-- Ver propiedades por ciudad
-- SELECT tipo_inmueble, barrio, precio, area_m2, habitaciones, banos 
-- FROM propiedades 
-- WHERE ciudad = 'Bogotá' AND estado = 'completo'
-- ORDER BY created_at DESC;

-- Obtener contexto de conversación específica
-- SELECT contexto FROM conversaciones WHERE telegram_user_id = 123456789;

-- Contar propiedades por tipo
-- SELECT tipo_inmueble, COUNT(*) as total 
-- FROM propiedades 
-- WHERE estado = 'completo'
-- GROUP BY tipo_inmueble
-- ORDER BY total DESC;

-- ====================================================================
-- TRIGGERS (OPCIONAL - PARA ACTUALIZAR TIMESTAMPS)
-- ====================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_conversaciones_updated_at 
    BEFORE UPDATE ON conversaciones
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ====================================================================
-- NOTA IMPORTANTE
-- ====================================================================
-- Recuerda ejecutar estos comandos en tu base de datos Supabase:
-- 1. Ve a SQL Editor en tu dashboard de Supabase
-- 2. Copia y pega este script completo
-- 3. Ejecuta el script
-- 4. Verifica que las tablas se hayan creado correctamente
-- ====================================================================
