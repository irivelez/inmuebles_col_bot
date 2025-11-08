# 🏠 Bot de Inmuebles para WhatsApp/Telegram

## 📋 Descripción

Bot conversacional de IA para automatizar la recopilación de información de propiedades inmobiliarias en LATAM. Diseñado específicamente para propietarios no digitalizados que usan métodos tradicionales de venta (carteles físicos en ventanas).

El bot recopila información de manera conversacional a través de WhatsApp/Telegram usando OpenAI GPT-4, normaliza los datos automáticamente y los almacena en una base de datos PostgreSQL (Supabase).

## ✨ Características

- 🤖 **Conversación Natural**: Usa OpenAI GPT-4o-mini para interacciones fluidas
- 📸 **Manejo de Fotos**: Recopila y almacena fotos de propiedades (mínimo 3)
- 🔄 **Normalización Automática**: Convierte precios ("COP $500.000.000" → "500000000") y áreas ("200 m²" → 200)
- 💾 **Historial Contextual**: Mantiene el contexto de la conversación para no repetir preguntas
- 🗄️ **Base de Datos Estructurada**: Almacena datos normalizados en PostgreSQL
- 📱 **Multi-canal**: Funciona con Telegram (MVP) y diseñado para WhatsApp Business API

## 🏗️ Arquitectura

### Stack Tecnológico

- **Orquestación**: n8n (workflow automation)
- **IA Conversacional**: OpenAI API (GPT-4o-mini)
- **Base de Datos**: Supabase (PostgreSQL)
- **Mensajería**: Telegram Bot API (WhatsApp Business API compatible)

### Flujo de Datos

```
Usuario → Telegram/WhatsApp
  ↓
n8n Trigger (recibe mensaje)
  ↓
Extraer metadata (user_id, tipo mensaje, contenido)
  ↓
Consultar conversación existente en Supabase
  ↓
¿Primera vez? → Crear nueva conversación
  ↓
Preparar contexto con historial completo
  ↓
¿Es foto o texto?
  ├─ FOTO → Almacenar file_id, contador de fotos
  └─ TEXTO → Enviar a OpenAI con contexto
       ↓
    Procesar respuesta GPT
       ↓
    ¿Info completa?
       ├─ SÍ → Normalizar datos → Guardar en tabla propiedades
       └─ NO → Continuar conversación
       ↓
Actualizar conversación en Supabase
  ↓
Enviar respuesta al usuario
```

## 🗄️ Esquema de Base de Datos

### Tabla: `conversaciones`

```sql
CREATE TABLE conversaciones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  telegram_user_id BIGINT UNIQUE NOT NULL,
  estado TEXT DEFAULT 'inicio',
  contexto JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Tabla: `propiedades`

```sql
CREATE TABLE propiedades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  telegram_user_id BIGINT NOT NULL,
  tipo_inmueble TEXT,
  ciudad TEXT,
  barrio TEXT,
  direccion TEXT,
  precio TEXT,
  area_m2 DECIMAL,
  habitaciones INTEGER,
  banos INTEGER,
  estrato INTEGER,
  caracteristicas TEXT[],
  fotos_urls TEXT[],
  nombre_propietario TEXT,
  telefono_propietario TEXT,
  estado TEXT DEFAULT 'recopilando',
  created_at TIMESTAMP DEFAULT NOW()
);
```

## 🚀 Instalación

### Prerrequisitos

1. **Cuenta de n8n** (Cloud o self-hosted)
2. **Cuenta de Supabase** (o PostgreSQL)
3. **API Key de OpenAI**
4. **Bot de Telegram** (crear con @BotFather)

### Paso 1: Configurar Supabase

1. Crea un proyecto en [Supabase](https://supabase.com)
2. Ejecuta los scripts SQL de las tablas `conversaciones` y `propiedades` (ver arriba)
3. Guarda tu URL de Supabase y API Key (anon/public)

### Paso 2: Crear Bot de Telegram

1. Abre Telegram y busca [@BotFather](https://t.me/BotFather)
2. Envía `/newbot` y sigue las instrucciones
3. Guarda el **Token del Bot** que te proporciona

### Paso 3: Obtener API Key de OpenAI

1. Ve a [OpenAI Platform](https://platform.openai.com/api-keys)
2. Crea una nueva API Key
3. Guarda la clave de forma segura

### Paso 4: Importar Workflow en n8n

1. Descarga el archivo `workflow.json` de este repositorio
2. En n8n, ve a Workflows → Import from File
3. Selecciona el archivo `workflow.json`

### Paso 5: Configurar Credenciales en n8n

#### Telegram
- **Credential Type**: Telegram API
- **Access Token**: Tu token del bot de @BotFather

#### OpenAI
- **Credential Type**: OpenAI API
- **API Key**: Tu API key de OpenAI

#### Supabase
- **Credential Type**: Supabase API
- **Host**: Tu URL de Supabase (e.g., `https://xxxxx.supabase.co`)
- **Service Role Secret**: Tu API Key de Supabase

### Paso 6: Activar Workflow

1. Revisa que todos los nodos tengan credenciales configuradas
2. Haz clic en el toggle "Active" en la esquina superior derecha
3. ¡Listo! Envía un mensaje a tu bot de Telegram

## 📝 Uso

### Flujo de Conversación

1. Usuario envía `/start` o cualquier mensaje al bot
2. El bot saluda y pregunta qué tipo de propiedad desea registrar
3. El bot hace preguntas una por una:
   - Tipo de inmueble (casa, apartamento, lote, finca)
   - Ciudad
   - Barrio
   - Precio
   - Área en m²
   - Número de habitaciones
   - Número de baños
   - Estrato (1-6 para Colombia)
   - Características (parqueadero, balcón, etc.)
   - Fotos (mínimo 3)
   - Nombre del propietario
   - Teléfono del propietario
4. Una vez completo, el bot muestra un resumen y guarda en la base de datos

### Ejemplo de Conversación

```
Usuario: Hola
Bot: ¡Hola! 👋 Te ayudaré a registrar tu propiedad. ¿Qué tipo de inmueble deseas registrar? (casa, apartamento, lote, finca)

Usuario: Apartamento
Bot: ¡Perfecto! ¿En qué ciudad se encuentra el apartamento?

Usuario: Bogotá
Bot: ¿En qué barrio de Bogotá?

Usuario: Chapinero
Bot: ¿Cuál es el precio del apartamento?

Usuario: COP $500.000.000
Bot: ¿Cuál es el área del apartamento en metros cuadrados?

Usuario: 120 m²
Bot: ¿Cuántas habitaciones tiene?

...
```

## 🔧 Funciones de Normalización

El bot incluye funciones automáticas para normalizar datos:

### Normalización de Precios
```javascript
// "COP $500.000.000" → "500000000"
// "USD 150,000" → "150000"
// "$250.000" → "250000"
```

### Normalización de Áreas
```javascript
// "200 m²" → 200
// "150 metros cuadrados" → 150
// "85m2" → 85
```

### Normalización de Números
```javascript
// Maneja formato europeo: 1.000.000
// Maneja formato americano: 1,000,000
// Elimina símbolos: $, COP, USD, m², etc.
```

## 🛠️ Personalización

### Modificar Campos Requeridos

Edita el prompt del sistema en el nodo "Preparar Mensajes OpenAI":

```javascript
Campos requeridos:
- tipo_inmueble: casa, apartamento, lote, finca
- ciudad: Ciudad completa
- barrio: Nombre del barrio
// ... añade o elimina campos aquí
```

### Cambiar Validaciones

Edita el nodo "Extraer Datos" para añadir validaciones personalizadas.

### Adaptar para WhatsApp

1. Reemplaza el nodo "Telegram Trigger" por "WhatsApp Trigger"
2. Configura WhatsApp Business API credentials
3. Ajusta el manejo de file_id para fotos de WhatsApp

## 🐛 Troubleshooting

### Error: "chat not found"
- **Causa**: Credenciales incorrectas en el nodo "Enviar Respuesta"
- **Solución**: Verifica que uses las mismas credenciales de Telegram en todos los nodos

### Error: "invalid input syntax for type numeric"
- **Causa**: Datos no normalizados llegando a la base de datos
- **Solución**: Revisa las funciones de normalización en el nodo "Extraer Datos"

### Bot no responde
- **Causa**: Workflow inactivo o error en algún nodo
- **Solución**: 
  1. Verifica que el workflow esté "Active"
  2. Revisa los logs de ejecución en n8n
  3. Comprueba que todas las credenciales estén configuradas

### Fotos no se guardan
- **Causa**: El nodo "Procesar Foto" no está recibiendo el file_id
- **Solución**: Verifica que el Switch "Tipo de Mensaje" detecte correctamente fotos

## 📊 Roadmap

- [ ] Dashboard para sales managers
- [ ] Exportación a portales inmobiliarios
- [ ] Integración con WhatsApp Business API
- [ ] Notificaciones por email
- [ ] Detección de duplicados
- [ ] Carga de fotos a Supabase Storage
- [ ] Generación automática de listings
- [ ] Multi-idioma (inglés, portugués)

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Por favor:

1. Fork este repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 💡 Inspiración y Contexto

Este proyecto nació de la necesidad real de ayudar a propietarios de inmuebles en LATAM que no están familiarizados con plataformas digitales. Muchos propietarios siguen usando el método tradicional de colocar carteles en las ventanas de sus propiedades, perdiendo oportunidades de venta.

Este bot democratiza el acceso a tecnología de automatización e IA para este nicho específico, haciendo que el proceso de listar una propiedad sea tan simple como tener una conversación por WhatsApp.

## 📧 Contacto

Si tienes preguntas o sugerencias, por favor abre un Issue en este repositorio.

---

⭐ Si este proyecto te fue útil, ¡considera darle una estrella en GitHub!
