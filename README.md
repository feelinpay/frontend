# 📱 Feelin Pay - Frontend (App Móvil)

Este es el cliente móvil de **Feelin Pay**, desarrollado con Flutter. Está diseñado para ser el centro operativo de un negocio, capturando pagos automáticamente y ofreciendo herramientas de gestión intuitivas.

## ✨ Características Destacadas

### 🤖 Automatización Inteligente (Funcionalidad Core)
La app cuenta con un **Notification Listener Service** que:
- Escucha activamente notificaciones de billeteras digitales (**Yape**).
- Extrae datos críticos (Monto, Nombre, Fecha) de forma segura.
- Sincroniza la información con el servidor incluso si la app está cerrada.

### 🎨 Experiencia de Usuario Premium
- **Encabezados Estandarizados:** Uso consistente del widget `AppHeader` con degradados elegantes y tipografía de alta visibilidad.
- **Responsive Design:** Adaptado para diferentes tamaños de pantalla y densidades de píxeles.
- **Modo Inmersivo:** Integración total con la barra de estado del sistema (Iconos blancos en fondos oscuros/degradados).

### 📋 Módulos de Gestión
- **Perfil de Usuario:** Gestión de datos personales y roles.
- **Gestión de Empleados:** Registro, edición y control de acceso.
- **Reportes:** Generación de archivos de Excel/PDF directamente en el Google Drive del propietario.
- **Avisos de Membresía:** Notificaciones inteligentes sobre el estado de la suscripción.

## 🛠️ Stack Tecnológico
- **Framework:** Flutter / Dart
- **Arquitectura:** Clean Architecture con Provider para manejo de estado.
- **Diseño:** `DesignSystem` propio con tokens de color, sombras y espaciados consistentes.

## ⚙️ Configuración Crítica para Android
Para que el lector de notificaciones funcione correctamente, el usuario debe habilitar estos permisos en la app:
1. **Acceso a Notificaciones:** Necesario para leer los globos de Yape.
2. **Ignorar Optimización de Batería:** Evita que Android detenga el servicio en segundo plano.

---

## 🚀 Cómo Empezar
1. Clona el repositorio.
2. Ejecuta `flutter pub get`.
3. Configura el `AppConfig` con la URL de tu backend.
4. Ejecuta `flutter run`.

---
*Parte del ecosistema Feelin Pay.*
