"""Gestión de usuarios: perfil propio y panel del administrador (baja lógica)."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database import obtener_sesion
from models import Usuario
from schemas import (
    CambioPassword,
    PerfilActualizar,
    UsuarioActualizarAdmin,
    UsuarioCrearAdmin,
    UsuarioRespuesta,
)
from security import ROL_ADMIN, hashear, requiere_roles, usuario_actual, verificar
from utils import generos_validos

router = APIRouter(prefix="/api/v1/users", tags=["Usuarios"])

solo_admin = requiere_roles(ROL_ADMIN)


def _guardar(db: Session, usuario: Usuario) -> Usuario:
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El correo electrónico ya está registrado")
    db.refresh(usuario)
    return usuario


# ------------------------------------------------------------ perfil propio
@router.put("/me", response_model=UsuarioRespuesta)
def actualizar_perfil(
    datos: PerfilActualizar,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    usuario.nom_usr = datos.nom_usr.strip()
    usuario.mail = datos.mail.strip().lower()
    usuario.dir_usr = datos.dir_usr.strip() if datos.dir_usr else None
    usuario.generos = generos_validos(db, datos.generos)
    return _guardar(db, usuario)


@router.put("/me/password")
def cambiar_password(
    datos: CambioPassword,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    if not verificar(datos.actual, usuario.pass_hash):
        raise HTTPException(status_code=400, detail="La contraseña actual es incorrecta")
    usuario.pass_hash = hashear(datos.nueva)
    db.commit()
    return {"mensaje": "Contraseña actualizada correctamente"}


# ------------------------------------------------------- panel administrador
@router.get("", response_model=list[UsuarioRespuesta])
def listar_usuarios(
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(solo_admin),
):
    return db.scalars(select(Usuario).order_by(Usuario.id_usr)).all()


@router.post("", response_model=UsuarioRespuesta, status_code=201)
def crear_usuario(
    datos: UsuarioCrearAdmin,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(solo_admin),
):
    usuario = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=datos.mail.strip().lower(),
        pass_hash=hashear(datos.password),
        dir_usr=datos.dir_usr.strip() if datos.dir_usr else None,
        tip_usu=datos.tip_usu,
        estatus=1,
    )
    db.add(usuario)
    return _guardar(db, usuario)


@router.put("/{usuario_id}", response_model=UsuarioRespuesta)
def actualizar_usuario(
    usuario_id: int,
    datos: UsuarioActualizarAdmin,
    db: Session = Depends(obtener_sesion),
    admin: Usuario = Depends(solo_admin),
):
    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    if usuario.id_usr == admin.id_usr and (datos.tip_usu != ROL_ADMIN or datos.estatus != 1):
        raise HTTPException(
            status_code=400,
            detail="No puedes quitarte el rol de administrador ni desactivar tu propia cuenta",
        )

    usuario.nom_usr = datos.nom_usr.strip()
    usuario.mail = datos.mail.strip().lower()
    usuario.dir_usr = datos.dir_usr.strip() if datos.dir_usr else None
    usuario.tip_usu = datos.tip_usu
    usuario.estatus = datos.estatus
    return _guardar(db, usuario)


@router.delete("/{usuario_id}")
def dar_de_baja_usuario(
    usuario_id: int,
    db: Session = Depends(obtener_sesion),
    admin: Usuario = Depends(solo_admin),
):
    """Baja lógica: la cuenta queda desactivada pero conserva sus publicaciones."""
    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    if usuario.id_usr == admin.id_usr:
        raise HTTPException(status_code=400, detail="No puedes desactivar tu propia cuenta")
    usuario.estatus = 0
    db.commit()
    return {"mensaje": "Usuario desactivado correctamente"}
