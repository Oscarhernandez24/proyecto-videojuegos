"""Seguridad: hash de contraseñas (Argon2), tokens JWT y control de acceso por rol."""
import os
import secrets
from datetime import datetime, timedelta, timezone

import jwt
from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pwdlib import PasswordHash
from sqlalchemy.orm import Session

from database import obtener_sesion
from models import Usuario

load_dotenv()

ROL_ADMIN = 1
ROL_AUTOR = 2
ROL_LECTOR = 3

# Si no se define SECRET_KEY se genera una aleatoria (las sesiones se pierden al reiniciar).
SECRET_KEY = os.getenv("SECRET_KEY") or secrets.token_urlsafe(48)
ALGORITHM = "HS256"
EXPIRA_MIN = int(os.getenv("TOKEN_EXPIRE_MINUTES", "120"))

_hasher = PasswordHash.recommended()
_bearer = HTTPBearer(auto_error=False)


def hashear(password: str) -> str:
    return _hasher.hash(password)


def verificar(password: str, hash_guardado: str) -> bool:
    try:
        return _hasher.verify(password, hash_guardado)
    except Exception:
        # Hash con formato inválido (p. ej. datos de prueba sin hashear)
        return False


def crear_token(usuario: Usuario) -> str:
    expira = datetime.now(timezone.utc) + timedelta(minutes=EXPIRA_MIN)
    carga = {"sub": str(usuario.id_usr), "rol": usuario.tip_usu, "exp": expira}
    return jwt.encode(carga, SECRET_KEY, algorithm=ALGORITHM)


def _usuario_desde_token(
    credenciales: HTTPAuthorizationCredentials | None,
    db: Session,
    obligatorio: bool,
) -> Usuario | None:
    if credenciales is None:
        if obligatorio:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Debes iniciar sesión para realizar esta acción",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return None

    try:
        datos = jwt.decode(credenciales.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        usuario = db.get(Usuario, int(datos["sub"]))
    except (jwt.PyJWTError, KeyError, ValueError):
        if obligatorio:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Tu sesión expiró o no es válida. Inicia sesión de nuevo",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return None

    if usuario is None or usuario.estatus != 1:
        if obligatorio:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Tu cuenta no está disponible. Inicia sesión de nuevo",
            )
        return None
    return usuario


def usuario_actual(
    credenciales: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(obtener_sesion),
) -> Usuario:
    """Exige un token válido."""
    return _usuario_desde_token(credenciales, db, obligatorio=True)


def usuario_opcional(
    credenciales: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(obtener_sesion),
) -> Usuario | None:
    """Permite invitados: devuelve None si no hay token válido."""
    return _usuario_desde_token(credenciales, db, obligatorio=False)


def requiere_roles(*roles: int):
    """Dependencia que solo deja pasar a los roles indicados."""

    def verificar_rol(usuario: Usuario = Depends(usuario_actual)) -> Usuario:
        if usuario.tip_usu not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permisos para realizar esta acción",
            )
        return usuario

    return verificar_rol
