"""RF001 Registrar usuario y RF002 Iniciar sesión (JWT, recuperación de contraseña)."""
import os
import secrets
import time
from collections import defaultdict, deque

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from datetime import timedelta

from database import obtener_sesion
from models import RecuperacionPassword, Usuario
from schemas import (
    LoginRequest,
    RecuperarRequest,
    RestablecerRequest,
    TokenRespuesta,
    UsuarioRegistro,
    UsuarioRespuesta,
)
from security import (
    EXPIRA_MIN,
    ROL_LECTOR,
    crear_token,
    hashear,
    usuario_actual,
    verificar,
)
from utils import ahora, enviar_correo, generos_validos, log

router = APIRouter(prefix="/api/v1/auth", tags=["Autenticación"])

# Protección básica contra fuerza bruta: 5 intentos fallidos cada 5 minutos por correo.
MAX_INTENTOS = 5
VENTANA_SEG = 300
_intentos: dict[str, deque] = defaultdict(deque)


def _bloqueado(clave: str) -> bool:
    cola = _intentos[clave]
    ahora_t = time.monotonic()
    while cola and ahora_t - cola[0] > VENTANA_SEG:
        cola.popleft()
    return len(cola) >= MAX_INTENTOS


def _verificar_bloqueo(clave: str) -> None:
    if _bloqueado(clave):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Demasiados intentos fallidos. Intenta de nuevo en unos minutos",
        )


@router.post("/register", response_model=UsuarioRespuesta, status_code=201)
def registrar(datos: UsuarioRegistro, db: Session = Depends(obtener_sesion)):
    generos = generos_validos(db, datos.generos)

    usuario = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=datos.mail.strip().lower(),
        pass_hash=hashear(datos.password),  # la contraseña nunca se guarda en texto plano
        dir_usr=datos.dir_usr.strip() if datos.dir_usr else None,
        tip_usu=ROL_LECTOR,  # rol por defecto: Lector
        estatus=1,
        generos=generos,
    )
    db.add(usuario)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El correo electrónico ya está registrado")
    db.refresh(usuario)
    return usuario


@router.post("/login", response_model=TokenRespuesta)
def iniciar_sesion(datos: LoginRequest, db: Session = Depends(obtener_sesion)):
    correo = datos.mail.strip().lower()
    _verificar_bloqueo(correo)

    usuario = db.scalar(select(Usuario).where(Usuario.mail == correo))

    if usuario is None or not verificar(datos.password, usuario.pass_hash):
        _intentos[correo].append(time.monotonic())
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
        )

    if usuario.estatus != 1:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Su cuenta se encuentra desactivada, contacte al Administrador",
        )

    _intentos.pop(correo, None)
    return TokenRespuesta(
        access_token=crear_token(usuario),
        token_type="bearer",
        expires_in=EXPIRA_MIN * 60,
        usuario=UsuarioRespuesta.model_validate(usuario),
    )


@router.get("/me", response_model=UsuarioRespuesta)
def mi_sesion(usuario: Usuario = Depends(usuario_actual)):
    """Valida el token guardado en el dispositivo y devuelve los datos vigentes."""
    return usuario


@router.post("/forgot-password")
def recuperar_password(datos: RecuperarRequest, db: Session = Depends(obtener_sesion)):
    """Genera un código de 6 dígitos (válido 15 min). La respuesta es siempre la misma
    exista o no el correo, para no revelar qué cuentas están registradas."""
    correo = datos.mail.strip().lower()
    respuesta = {"mensaje": "Si el correo está registrado, recibirás un código de verificación"}

    usuario = db.scalar(select(Usuario).where(Usuario.mail == correo, Usuario.estatus == 1))
    if usuario is None:
        return respuesta

    codigo = f"{secrets.randbelow(10**6):06d}"
    db.execute(
        update(RecuperacionPassword)
        .where(RecuperacionPassword.usr_id == usuario.id_usr)
        .values(usado=1)
    )
    db.add(
        RecuperacionPassword(
            usr_id=usuario.id_usr,
            codigo_hash=hashear(codigo),
            expira=ahora() + timedelta(minutes=15),
            usado=0,
        )
    )
    db.commit()

    enviado = enviar_correo(
        usuario.mail,
        "Código para restablecer tu contraseña",
        f"Tu código de verificación es: {codigo}\nVence en 15 minutos.",
    )

    if os.getenv("DEV_MODE", "false").lower() == "true":
        log.info("[DEV_MODE] Código de recuperación para %s: %s", correo, codigo)
        respuesta["codigo_dev"] = codigo
    elif not enviado:
        log.warning("No hay SMTP configurado: no se envió el código de %s", correo)

    return respuesta


@router.post("/reset-password")
def restablecer_password(datos: RestablecerRequest, db: Session = Depends(obtener_sesion)):
    correo = datos.mail.strip().lower()
    clave = f"reset:{correo}"
    _verificar_bloqueo(clave)

    error = HTTPException(status_code=400, detail="El código es inválido o ya expiró")

    usuario = db.scalar(select(Usuario).where(Usuario.mail == correo, Usuario.estatus == 1))
    if usuario is None:
        _intentos[clave].append(time.monotonic())
        raise error

    registro = db.scalar(
        select(RecuperacionPassword)
        .where(
            RecuperacionPassword.usr_id == usuario.id_usr,
            RecuperacionPassword.usado == 0,
            RecuperacionPassword.expira > ahora(),
        )
        .order_by(RecuperacionPassword.id.desc())
    )
    if registro is None or not verificar(datos.codigo.strip(), registro.codigo_hash):
        _intentos[clave].append(time.monotonic())
        raise error

    usuario.pass_hash = hashear(datos.nueva_password)
    registro.usado = 1
    db.commit()
    _intentos.pop(clave, None)
    return {"mensaje": "Contraseña actualizada. Ya puedes iniciar sesión"}
