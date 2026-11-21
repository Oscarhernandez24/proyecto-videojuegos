"""Esquemas Pydantic: validan lo que entra y define lo que sale de la API."""
import re
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

EMAIL_PATRON = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"


def validar_password(valor: str) -> str:
    """Mínimo 8 caracteres, con al menos una letra y un número."""
    if len(valor) < 8:
        raise ValueError("La contraseña debe tener al menos 8 caracteres")
    if not re.search(r"[A-Za-z]", valor) or not re.search(r"\d", valor):
        raise ValueError("La contraseña debe incluir letras y números")
    return valor


# ---------- Catálogos (géneros y categorías) ----------
class CatalogoRespuesta(BaseModel):
    id: int
    nombre: str
    estatus: int = 1

    model_config = ConfigDict(from_attributes=True)


class CatalogoCrear(BaseModel):
    nombre: str = Field(min_length=2, max_length=60)


class CatalogoActualizar(BaseModel):
    nombre: str = Field(min_length=2, max_length=60)
    estatus: int = Field(default=1, ge=0, le=1)


# ---------- Usuarios ----------
class UsuarioRegistro(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(max_length=150, pattern=EMAIL_PATRON)
    password: str = Field(max_length=128)
    dir_usr: str | None = Field(default=None, max_length=200)
    generos: list[int] = []

    @field_validator("password")
    @classmethod
    def chequear_password(cls, valor: str) -> str:
        return validar_password(valor)


class UsuarioCrearAdmin(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(max_length=150, pattern=EMAIL_PATRON)
    password: str = Field(max_length=128)
    dir_usr: str | None = Field(default=None, max_length=200)
    tip_usu: int = Field(default=3, ge=1, le=3)

    @field_validator("password")
    @classmethod
    def chequear_password(cls, valor: str) -> str:
        return validar_password(valor)


class UsuarioActualizarAdmin(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(max_length=150, pattern=EMAIL_PATRON)
    dir_usr: str | None = Field(default=None, max_length=200)
    tip_usu: int = Field(ge=1, le=3)
    estatus: int = Field(default=1, ge=0, le=1)


class PerfilActualizar(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(max_length=150, pattern=EMAIL_PATRON)
    dir_usr: str | None = Field(default=None, max_length=200)
    generos: list[int] = []


class CambioPassword(BaseModel):
    actual: str = Field(min_length=1, max_length=128)
    nueva: str = Field(max_length=128)

    @field_validator("nueva")
    @classmethod
    def validar_nueva(cls, valor: str) -> str:
        return validar_password(valor)


class UsuarioRespuesta(BaseModel):
    id_usr: int
    nom_usr: str
    mail: str
    dir_usr: str | None = None
    tip_usu: int
    estatus: int
    generos: list[CatalogoRespuesta] = []

    model_config = ConfigDict(from_attributes=True)


# ---------- Autenticación ----------
class LoginRequest(BaseModel):
    mail: str = Field(min_length=3, max_length=150)
    password: str = Field(min_length=1, max_length=128)


class TokenRespuesta(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    usuario: UsuarioRespuesta


class RecuperarRequest(BaseModel):
    mail: str = Field(min_length=3, max_length=150)


class RestablecerRequest(BaseModel):
    mail: str = Field(min_length=3, max_length=150)
    codigo: str = Field(min_length=4, max_length=10)
    nueva_password: str = Field(max_length=128)

    @field_validator("nueva_password")
    @classmethod
    def validar_nueva_password(cls, valor: str) -> str:
        return validar_password(valor)


# ---------- Publicaciones ----------
class PostRespuesta(BaseModel):
    id_blog: int
    titulo: str
    descripcion: str | None = None
    img: str | None = None
    tags: str | None = None
    fecha: datetime | None = None
    autor_id: int
    autor_nombre: str | None = None
    categoria_id: int | None = None
    categoria_nombre: str | None = None
    generos: list[CatalogoRespuesta] = []
    promedio: float = 0.0
    total_valoraciones: int = 0
    total_comentarios: int = 0
    reacciones: dict[str, int] = {}
    mi_reaccion: str | None = None
    mi_valoracion: int | None = None


# ---------- Comentarios e interacciones ----------
class ComentarioCrear(BaseModel):
    comentario: str = Field(min_length=1, max_length=2000)
    parent_id: int | None = None


class ComentarioActualizar(BaseModel):
    comentario: str = Field(min_length=1, max_length=2000)


class ComentarioRespuesta(BaseModel):
    id_com: int
    comentario: str
    fecha: datetime
    usr_id: int
    nom_usr: str | None = None
    blog_id: int
    parent_id: int | None = None
    likes: int = 0
    dislikes: int = 0
    mi_voto: int = 0


class VotoRequest(BaseModel):
    valor: int = Field(ge=-1, le=1)


class ReaccionRequest(BaseModel):
    emoji: str = Field(min_length=1, max_length=16)


class ValoracionRequest(BaseModel):
    estrellas: int = Field(ge=1, le=5)
