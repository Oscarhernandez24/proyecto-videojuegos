"""API del Blog de Videojuegos (FastAPI).

Arranque:  uvicorn main:app --reload --host 0.0.0.0 --port 8000
Documentación interactiva: http://127.0.0.1:8000/docs
"""
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.exc import OperationalError, SQLAlchemyError

from routers import auth, catalog, comments, interacciones, posts, users
from utils import UPLOAD_DIR, log

app = FastAPI(
    title="API del Blog de Videojuegos",
    version="2.0.0",
    description=(
        "Autenticación con JWT, contraseñas con Argon2, control de acceso por rol "
        "(Administrador, Autor, Lector) y publicaciones, comentarios, reacciones y "
        "valoraciones sobre videojuegos."
    ),
)

# Las imágenes subidas se sirven como archivos estáticos.
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# La autenticación usa el encabezado Authorization (no cookies), por eso no se
# necesitan credenciales en CORS. En producción reemplaza "*" por tu dominio.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(catalog.router_generos)
app.include_router(catalog.router_categorias)
app.include_router(posts.router)
app.include_router(interacciones.router)
app.include_router(comments.router)


# ------------------------------------------------------- manejo de errores
@app.exception_handler(RequestValidationError)
async def error_validacion(request: Request, exc: RequestValidationError):
    errores = exc.errors()
    primero = errores[0] if errores else {}
    campo = ".".join(str(x) for x in primero.get("loc", []) if x not in ("body", "query", "path", "form"))
    mensaje = primero.get("msg", "dato inválido")
    mensaje = mensaje.replace("Value error, ", "")
    detalle = f"Datos inválidos ({campo}): {mensaje}" if campo else f"Datos inválidos: {mensaje}"
    return JSONResponse(status_code=422, content={"detail": detalle})


@app.exception_handler(OperationalError)
async def error_conexion_bd(request: Request, exc: OperationalError):
    log.error("Error de conexión con la base de datos: %s", exc)
    return JSONResponse(
        status_code=503,
        content={"detail": "No se pudo conectar con la base de datos. Intenta más tarde"},
    )


@app.exception_handler(SQLAlchemyError)
async def error_bd(request: Request, exc: SQLAlchemyError):
    log.error("Error de base de datos: %s", exc)
    return JSONResponse(
        status_code=500,
        content={"detail": "Ocurrió un error al procesar la información"},
    )


@app.get("/", tags=["Estado"])
def estado():
    return {"servicio": "API del Blog de Videojuegos", "estado": "en línea", "docs": "/docs"}
