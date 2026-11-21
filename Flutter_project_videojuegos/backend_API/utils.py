"""Utilidades compartidas: imágenes, correo, géneros válidos y constantes."""
import logging
import os
import smtplib
import uuid
from datetime import datetime, timezone
from email.message import EmailMessage
from pathlib import Path

from fastapi import HTTPException, UploadFile
from sqlalchemy import select
from sqlalchemy.orm import Session

from models import Genero

log = logging.getLogger("uvicorn.error")

UPLOAD_DIR = Path(__file__).parent / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)

EXTENSIONES_PERMITIDAS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_IMAGEN_BYTES = 5 * 1024 * 1024
REACCIONES_PERMITIDAS = ["🔥", "❤️", "😂", "😮", "👏", "🎮"]


def ahora() -> datetime:
    """Fecha/hora UTC sin zona horaria (compatible con columnas DATETIME)."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


# ---------------------------------------------------------------- imágenes
def _es_imagen_valida(contenido: bytes) -> bool:
    return (
        contenido.startswith(b"\xff\xd8\xff")  # JPEG
        or contenido.startswith(b"\x89PNG\r\n\x1a\n")  # PNG
        or (contenido[:4] == b"RIFF" and contenido[8:12] == b"WEBP")  # WEBP
    )


def guardar_imagen(imagen: UploadFile | None) -> str | None:
    """Valida y guarda la imagen. Devuelve la ruta relativa (/uploads/xxx.jpg)."""
    if imagen is None or not imagen.filename:
        return None

    extension = Path(imagen.filename).suffix.lower()
    if extension not in EXTENSIONES_PERMITIDAS:
        raise HTTPException(status_code=400, detail="Formato de imagen no permitido (usa JPG, PNG o WEBP)")

    contenido = imagen.file.read(MAX_IMAGEN_BYTES + 1)
    if len(contenido) > MAX_IMAGEN_BYTES:
        raise HTTPException(status_code=413, detail="La imagen no debe superar los 5 MB")
    if not _es_imagen_valida(contenido):
        raise HTTPException(status_code=400, detail="El archivo no es una imagen válida")

    nombre = f"{uuid.uuid4().hex}{extension}"
    (UPLOAD_DIR / nombre).write_bytes(contenido)
    return f"/uploads/{nombre}"


def borrar_imagen(ruta: str | None) -> None:
    if ruta and ruta.startswith("/uploads/"):
        (UPLOAD_DIR / Path(ruta).name).unlink(missing_ok=True)


def url_imagen(img: str | None, base_url: str) -> str | None:
    """Devuelve una URL completa y alcanzable desde el cliente."""
    if not img:
        return None
    if img.startswith("/"):
        return f"{base_url}{img}"
    if "/uploads/" in img and any(h in img for h in ("127.0.0.1", "localhost", "10.0.2.2")):
        return f"{base_url}/uploads/{img.split('/uploads/')[-1]}"
    return img


# ----------------------------------------------------------------- géneros
def generos_validos(db: Session, ids: list[int], obligatorio: bool = False) -> list[Genero]:
    ids = list(dict.fromkeys(ids))
    if not ids:
        if obligatorio:
            raise HTTPException(status_code=422, detail="Selecciona al menos un género")
        return []
    encontrados = db.scalars(
        select(Genero).where(Genero.id_genero.in_(ids), Genero.estatus == 1)
    ).all()
    if len(encontrados) != len(ids):
        raise HTTPException(
            status_code=422,
            detail="Alguno de los géneros seleccionados no existe o está inactivo",
        )
    return list(encontrados)


# ------------------------------------------------------------------ correo
def enviar_correo(destino: str, asunto: str, texto: str) -> bool:
    """Envía un correo por SMTP si está configurado. Devuelve True si se envió."""
    host = os.getenv("SMTP_HOST", "").strip()
    if not host:
        return False
    try:
        mensaje = EmailMessage()
        mensaje["Subject"] = asunto
        mensaje["From"] = os.getenv("SMTP_FROM") or os.getenv("SMTP_USER", "")
        mensaje["To"] = destino
        mensaje.set_content(texto)
        with smtplib.SMTP(host, int(os.getenv("SMTP_PORT", "587")), timeout=10) as smtp:
            smtp.starttls()
            usuario = os.getenv("SMTP_USER", "")
            if usuario:
                smtp.login(usuario, os.getenv("SMTP_PASSWORD", ""))
            smtp.send_message(mensaje)
        return True
    except Exception as error:  # noqa: BLE001
        log.warning("No se pudo enviar el correo: %s", error)
        return False
