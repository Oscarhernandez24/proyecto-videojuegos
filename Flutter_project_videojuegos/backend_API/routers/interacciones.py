"""RF004 Reacciones con emojis y valoración por estrellas en las publicaciones."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import obtener_sesion
from models import Blog, Reaccion, Usuario, Valoracion
from schemas import ReaccionRequest, ValoracionRequest
from security import usuario_actual
from utils import REACCIONES_PERMITIDAS

router = APIRouter(prefix="/api/v1/posts", tags=["Interacciones"])


def _verificar_post(db: Session, blog_id: int) -> None:
    if db.get(Blog, blog_id) is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")


@router.get("/reactions/disponibles", response_model=list[str])
def reacciones_disponibles():
    return REACCIONES_PERMITIDAS


@router.put("/{blog_id}/reaction")
def reaccionar(
    blog_id: int,
    datos: ReaccionRequest,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    """Registra (o cambia) la reacción del usuario a la publicación."""
    if datos.emoji not in REACCIONES_PERMITIDAS:
        raise HTTPException(status_code=422, detail="Reacción no disponible")
    _verificar_post(db, blog_id)

    reaccion = db.get(Reaccion, (blog_id, usuario.id_usr))
    if reaccion is None:
        db.add(Reaccion(blog_id=blog_id, usr_id=usuario.id_usr, emoji=datos.emoji))
    else:
        reaccion.emoji = datos.emoji
    db.commit()
    return {"mensaje": "Reacción registrada"}


@router.delete("/{blog_id}/reaction")
def quitar_reaccion(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    reaccion = db.get(Reaccion, (blog_id, usuario.id_usr))
    if reaccion is not None:
        db.delete(reaccion)
        db.commit()
    return {"mensaje": "Reacción eliminada"}


@router.put("/{blog_id}/rating")
def valorar(
    blog_id: int,
    datos: ValoracionRequest,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    """Califica la publicación de 1 a 5 estrellas (una calificación por usuario)."""
    _verificar_post(db, blog_id)

    valoracion = db.get(Valoracion, (blog_id, usuario.id_usr))
    if valoracion is None:
        db.add(Valoracion(blog_id=blog_id, usr_id=usuario.id_usr, estrellas=datos.estrellas))
    else:
        valoracion.estrellas = datos.estrellas
    db.commit()
    return {"mensaje": "Valoración registrada"}
