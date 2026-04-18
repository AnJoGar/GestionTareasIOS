
# TaskManagerApp 

Aplicación móvil iOS para gestión de tareas, desarrollada en **Swift con SwiftUI** y persistencia local mediante **SQLite nativo** (sin dependencias externas).

---

## Características

-  Agregar tareas con título, descripción y prioridad
-  Editar tareas existentes
-  Eliminar tareas (con confirmación)
-  Marcar tareas como completadas / pendientes
-  Filtrar por estado: Todas, Pendientes, Completadas
-  Búsqueda en tiempo real por título o descripción
-  Estadísticas rápidas (total, pendientes, completadas)
-  Persistencia completa con SQLite nativo del sistema iOS

---

## Requisitos

| Herramienta | Versión mínima |
|---|---|
| Xcode | 15.0 o superior |
| iOS Deployment Target | 16.0 |
| Swift | 5.9 |
| macOS (para compilar) | Ventura 13.0 o superior |

> **No se requieren dependencias externas ni CocoaPods ni SPM.** El proyecto usa `libsqlite3.tbd` que viene incluida en el SDK de iOS.

---

## Cómo compilar y ejecutar

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU_USUARIO/TaskManagerApp.git
cd TaskManagerApp
```

### 2. Abrir en Xcode

```bash
open TaskManagerApp.xcodeproj
```

O desde Xcode: **File → Open** y seleccionar la carpeta del proyecto.

### 3. Seleccionar el simulador

En la barra superior de Xcode, selecciona un simulador iPhone (por ejemplo **iPhone 15**) desde el menú desplegable de dispositivos.

### 4. Ejecutar la app

Presiona **⌘ + R** o el botón ▶ en Xcode.

La app se compilará e iniciará en el simulador automáticamente.

---

### Principios de código limpio aplicados

- **Responsabilidad única**: cada clase tiene una sola razón para cambiar.
- **Inversión de dependencias**: `TaskListViewModel` depende de `TaskRepositoryProtocol`, no de la implementación concreta. Esto permite inyectar un `MockTaskRepository` en los tests.
- **Nombres expresivos**: variables, funciones y tipos con nombres claros y en inglés.
- **Sin magia**: no hay números mágicos; los estados y prioridades son enums con nombres descriptivos.
- **Manejo de errores explícito**: uso de `throws` + `do/catch` en toda la capa de datos, con mensajes propagados a la UI.

---

## Base de datos SQLite

La app usa `libsqlite3` del SDK de iOS directamente, **sin ninguna librería de terceros**.

La base de datos se crea automáticamente en el directorio `Documents` del app sandbox:

```
Documents/TaskManager.sqlite
```

### Esquema de la tabla

```sql
CREATE TABLE IF NOT EXISTS tasks (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    title       TEXT    NOT NULL,
    description TEXT    DEFAULT '',
    is_completed INTEGER DEFAULT 0,
    priority    INTEGER DEFAULT 1,   -- 0=Low, 1=Medium, 2=High
    created_at  REAL    NOT NULL,    -- Unix timestamp
    updated_at  REAL    NOT NULL
);
```

### Operaciones implementadas

| Operación | Método en DatabaseManager |
|---|---|
| Listar todas | `fetchAllTasks()` |
| Insertar | `insertTask(_:)` |
| Actualizar | `updateTask(_:)` |
| Eliminar | `deleteTask(id:)` |
| Toggle completado | `toggleTaskCompletion(id:isCompleted:)` |

---

## Pantallas

| Pantalla | Descripción |
|---|---|
| **Lista principal** | Muestra todas las tareas con estadísticas, filtros por estado y barra de búsqueda |
| **Formulario** | Sheet deslizable para crear o editar una tarea con validación en tiempo real |
| **Menú de acciones** | Cada tarea tiene un menú contextual (···) con opciones Editar y Eliminar |
