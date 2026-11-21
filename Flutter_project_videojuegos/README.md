# Blog de Videojuegos
Aplicación móvil **Flutter** + API **FastAPI** + base de datos **MySQL**.
Evaluación Unidad 3 – Caso práctico: Diseño de blog.

Permite a los amantes de los videojuegos explorar, publicar, leer, comentar y valorar reseñas, noticias de lanzamientos, guías, entrevistas y recomendaciones.

```
Flutter_project_videojuegos/
├── backend_API/            API FastAPI (+ bd.sql, seed.py, requirements.txt)
│   ├── main.py             Arranque, CORS, manejo global de errores
│   ├── models.py           Modelos SQLAlchemy (tablas)
│   ├── schemas.py          Validación de entrada/salida (Pydantic)
│   ├── security.py         Argon2, JWT y control de acceso por rol
│   ├── utils.py            Imágenes, correo (SMTP) y utilidades
│   └── routers/            auth, users, catalog (géneros/categorías), posts, comments, interacciones
├── flutter_application_3/  App móvil
│   └── lib/
│       ├── core/           ApiClient (HTTP + errores), Session (token seguro), utilidades de UI
│       ├── models/ services/ screens/ widgets/
└── docker-compose.yml      Despliegue opcional (MySQL + API)
```

## 1. Base de datos y API (Windows PowerShell)
Requisitos: Python 3.10+ y MySQL en ejecución (XAMPP, MySQL Workbench, etc.).

```powershell
cd backend_API
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env            # edita DB_PASSWORD si tu MySQL tiene contraseña
cmd /c "mysql -u root -p < bd.sql"   # crea la base bd_blog_videojuegos, tablas y datos de ejemplo
python seed.py                    # asigna contraseñas reales (Argon2) a los usuarios de prueba
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
En Linux/Mac: `source .venv/bin/activate`, `cp .env.example .env` y `mysql -u root -p < bd.sql`.
Si `mysql` no se reconoce, importa `bd.sql` desde phpMyAdmin o MySQL Workbench (*Import / Run SQL script*).

Documentación interactiva (Swagger): http://127.0.0.1:8000/docs

**Con Docker (opcional):** `docker compose up --build` levanta MySQL (importa `bd.sql`) y la API en `http://localhost:8000`.

### Usuarios de prueba (tras `python seed.py`)
| Correo | Contraseña | Rol |
|---|---|---|
| adriana@ejemplo.com | Admin12345 | Administrador |
| carlos@ejemplo.com | Autor12345 | Autor |
| lucia@ejemplo.com | Lector12345 | Lector |

## 2. App Flutter
```powershell
cd flutter_application_3
flutter pub get
flutter run -d chrome                                  # navegador
flutter run                                            # emulador Android (usa 10.0.2.2 automáticamente)
flutter run --dart-define=API_URL=http://TU_IP:8000    # celular físico (misma red Wi-Fi que la PC)
```
La URL de la API se configura en `lib/config/api_config.dart`.
Pruebas: `flutter test`.

## 3. Roles y permisos
| Acción | Invitado | Lector | Autor | Administrador |
|---|:-:|:-:|:-:|:-:|
| Ver feed, comentarios y filtros | ✔ | ✔ | ✔ | ✔ |
| Comentar, responder, like/dislike, reaccionar, valorar | | ✔ | ✔ | ✔ |
| Crear publicaciones | | | ✔ | ✔ |
| Editar / eliminar publicaciones | | | las propias | cualquiera |
| Editar comentarios | | los propios | los propios | no |
| Eliminar comentarios | | los propios | los propios | cualquiera |
| CRUD de géneros y categorías | | | | ✔ |
| Gestionar usuarios (alta, rol, baja lógica) | | | | ✔ |

El registro desde la app crea siempre un **Lector**; el administrador puede cambiar el rol.

## 4. Requerimientos funcionales implementados
| RF | Descripción | Dónde |
|---|---|---|
| RF001 | Registro con validación en cliente y servidor, géneros favoritos, correo duplicado (409), baja lógica y gestión por el administrador | `register_user_page`, `routers/auth.py`, `users_page` |
| RF002 | Login con JWT, mensajes de credenciales incorrectas / cuenta desactivada, recuperación de contraseña por código, cierre de sesión | `login_user_page`, `forgot_password_page`, `routers/auth.py` |
| RF003 | CRUD de posts (título, contenido, categoría, géneros, etiquetas, imagen), solo autor/administrador modifican, confirmación al eliminar | `post_form_page`, `routers/posts.py` |
| RF004 | Comentarios con autor y fecha, respuestas, like/dislike, reacciones con emoji y valoración de 1 a 5 estrellas | `comment_section`, `routers/comments.py`, `routers/interacciones.py` |
| RF005 | Categorías: consulta/filtro público y CRUD para el administrador | `blog_page`, `catalog_admin_page`, `routers/catalog.py` |
| RF006 | Géneros de videojuegos: CRUD, asignación a posts y perfiles, filtro y mensaje "Aún no hay publicaciones en el género X" | igual que RF005 |
| Pruebas | Mensaje "Sin conexión a internet. Por favor verifique su red." cuando no hay red o el servidor no responde | `core/api_client.dart` |

## 5. Seguridad (rúbrica técnica)
- **Encriptación de contraseñas:** Argon2 (`pwdlib`); nunca se guarda ni se devuelve texto plano. Política: 8+ caracteres con letras y números (cliente y servidor).
- **Sesiones:** token JWT firmado (HS256) con caducidad configurable (`TOKEN_EXPIRE_MINUTES`). En el dispositivo se guarda con `flutter_secure_storage` (Keychain / almacenamiento cifrado de Android). Al abrir la app se valida con `GET /auth/me`; si expiró se regresa al login. Cerrar sesión destruye el token almacenado.
- **Control de acceso:** dependencias `requiere_roles(...)` por endpoint, comprobación de propietario en posts y comentarios, cuentas desactivadas rechazadas en login y en cada petición.
- **Manejo de errores:** respuestas con códigos HTTP correctos (401, 403, 404, 409, 422, 429, 503), manejador global de errores de validación y de base de datos, mensajes claros en la app y vista de "Reintentar".
- **Otras medidas:** límite de 5 intentos fallidos por correo cada 5 minutos, respuesta uniforme en recuperación de contraseña (no revela qué correos existen), código de recuperación con hash y vigencia de 15 minutos, validación de imágenes por contenido y tamaño (5 MB), consultas parametrizadas con SQLAlchemy.
- **Configuración:** `SECRET_KEY`, credenciales de MySQL y SMTP viven en `.env` (ignorado por Git). Cambia `SECRET_KEY` y pon `DEV_MODE=false` al publicar.

## 6. Endpoints principales (`/api/v1`)
| Método | Ruta | Acceso |
|---|---|---|
| POST | `/auth/register`, `/auth/login`, `/auth/forgot-password`, `/auth/reset-password` | Público |
| GET | `/auth/me` | Sesión |
| GET | `/posts?genre_id=&category_id=&q=`, `/posts/{id}`, `/posts/{id}/comments`, `/genres`, `/categories` | Público |
| POST/PUT/DELETE | `/posts` y `/posts/{id}` | Autor / Administrador |
| POST | `/posts/{id}/comments` | Sesión |
| PUT/DELETE | `/comments/{id}` | Dueño (administrador solo elimina) |
| POST | `/comments/{id}/vote` | Sesión |
| PUT/DELETE | `/posts/{id}/reaction`, PUT `/posts/{id}/rating` | Sesión |
| GET/POST/PUT/DELETE | `/users`, `/genres`, `/categories` (escritura) | Administrador |
| PUT | `/users/me`, `/users/me/password` | Sesión |

## 7. Recursos y librerías
- Flutter: `http` (cliente HTTP), `image_picker` (galería/cámara para la portada), `flutter_secure_storage` (token).
- API: `fastapi`, `uvicorn`, `sqlalchemy`, `pymysql`, `pwdlib[argon2]`, `PyJWT`, `python-multipart`, `python-dotenv`.
- Sensores: la **cámara** (solo móvil) se usa para tomar la foto de portada de una publicación; en web/escritorio se usa la galería. No se usa GPS.
