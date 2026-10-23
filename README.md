# Playart — Fotografía y video

Agenda y control de pagos para estudios de fotografía, sesiones familiares, bebés y eventos.

## Funciones
- Reservas con cliente, tipo de sesión, fecha, hora, lugar, precio y anticipo.
- Registro de pagos adicionales y saldos pendientes.
- Inicio de sesión y creación de cuenta con Supabase Auth.
- Sincronización de reservas entre la web y la app Android usando la misma cuenta.
- Políticas RLS: cada cuenta solo puede consultar y modificar sus propias reservas.
- Interfaz adaptable a teléfono, tablet y computadora; instalable como PWA.

## Supabase
El proyecto Supabase que actualmente se llama `Lumen-Estudio` usa su propia base de datos y está separado de CEMSTAN. El cliente usa únicamente la URL del proyecto y una clave publishable; nunca se incluye la clave `service_role`. Las tablas quedan protegidas por Row Level Security.

En Supabase, configura **Authentication → URL Configuration** para que `Site URL` sea `https://damoc1519-lang.github.io/Lumen-Estudio/` y agrega esa misma dirección a **Redirect URLs**. Para desarrollo local agrega `http://localhost:5173/**`. Esto permite que la confirmación por correo regrese a la aplicación.

## Desarrollo
Requiere Node.js 20.19+ o 22.12+.

```bash
npm ci
npm run dev
```

## Comprobaciones y compilación

```bash
npm run typecheck
npm run build
```

GitHub Actions publica la web en GitHub Pages. Android abre la misma web; al iniciar sesión con la misma cuenta, ambos clientes consultan el mismo proyecto Supabase. El workflow `Build Android APK` genera el APK desde `android/**`.
