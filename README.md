# Lumen — Estudio creativo

Agenda moderna y control de pagos para estudios de fotografía, sesiones familiares, bebés y eventos.

## Características
- Panel de reservas, ingresos recibidos y saldos pendientes.
- Agenda de sesiones con cliente, tipo, fecha, hora, lugar, precio y anticipo.
- Búsqueda y filtros.
- Diseño adaptable para teléfono, tablet y computadora.
- Preparada como PWA instalable desde el navegador.
- La demo guarda datos localmente en el navegador (localStorage); no hay servidor en esta fase.

## Ejecutar
Requiere Node.js 20.19+ o 22.12+.

```bash
npm install
npm run dev
```

## Compilar para producción
```bash
npm run build
npm run preview
```
El directorio dist puede desplegarse en hosting estático. Los datos de localStorage no se comparten entre dispositivos. Para operación real multiusuario habrá que conectar almacenamiento compartido y autenticación, revisando los límites de sus planes gratuitos.

## Versión Android

El proyecto incluye una app Android ligera que abre la versión web publicada, para compartir la misma interfaz. GitHub Actions genera un APK de prueba automáticamente cuando se actualiza `android/**`. Descárgalo desde la ejecución **Build Android APK → Artifacts → lumen-android-apk**.

La APK y la web aún no comparten reservas porque el prototipo usa almacenamiento local. Para sincronización real se necesita conectar una base remota. La organización Supabase vinculada ya alcanzó su límite de dos proyectos gratuitos activos; no se modificaron ni pausaron los proyectos existentes. Se elegirá un backend gratuito independiente antes de guardar información real.
