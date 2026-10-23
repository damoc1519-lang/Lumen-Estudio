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
