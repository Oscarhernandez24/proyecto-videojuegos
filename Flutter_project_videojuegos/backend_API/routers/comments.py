"""RF004 Comentarios: crear, consultar, responder, editar, eliminar y like/dislike."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from database import obtener_sesion
from models import Blog, Comentario, ComentarioVoto, Usuario
from schemas import (
    ComentarioActualizar,
    ComentarioCrear,
    ComentarioRespuesta,
    VotoRequest,
)
from security import ROL_ADMIN, usuario_actual, usuario_opcional

router = APIRouter(prefix="/api/v1", tags=["Comentarios"])


def _armar_respuestas(
    db: Session, comentarios: list[Comentario], usuario: Usuario | None
) -> list[ComentarioRespuesta]:
    ids = [c.id_com for c in comentarios]
    if not ids:
        return []

    likes: dict[int, int] = {}
    dislikes: dict[int, int] = {}
    for com_id, valor, total in db.execute(
        select(ComentarioVoto.com_id, ComentarioVoto.valor, func.count())
        .where(ComentarioVoto.com_id.in_(ids))
        .group_by(ComentarioVoto.com_id, ComentarioVoto.valor)
    ).all():
        (likes if valor > 0 else dislikes)[com_id] = int(total)

    mis_votos: dict[int, int] = {}
    if usuario is not None:
        mis_votos = {
            c: int(v)
            for c, v in db.execute(
                select(ComentarioVoto.com_id, ComentarioVoto.valor).where(
                    ComentarioVoto.com_id.in_(ids), ComentarioVoto.usr_id == usuario.id_usr
                )
            ).all()
        }

    return [
        ComentarioRespuesta(
            id_com=c.id_com,
            comentario=c.comentario,
            fecha=c.fecha,
            usr_id=c.usr_id,
            nom_usr=c.autor.nom_usr if c.autor else None,
            blog_id=c.blog_id,
            parent_id=c.parent_id,
            likes=likes.get(c.id_com, 0),
            dislikes=dislikes.get(c.id_com, 0),
            mi_voto=mis_votos.get(c.id_com, 0),
        )
        for c in comentarios
    ]


def _obtener_comentario(db: Session, com_id: int) -> Comentario:
    comentario = db.get(Comentario, com_id)
    if comentario is None or comentario.estatus != 1:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")
    return comentario


@router.get("/posts/{blog_id}/comments", response_model=list[ComentarioRespuesta])
def listar_comentarios(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario | None = Depends(usuario_opcional),
):
    if db.get(Blog, blog_id) is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")
    comentarios = db.scalars(
        select(Comentario)
        .where(Comentario.blog_id == blog_id, Comentario.estatus == 1)
        .order_by(Comentario.id_com)
    ).unique().all()
    return _armar_respuestas(db, list(comentarios), usuario)


@router.post("/posts/{blog_id}/comments", response_model=ComentarioRespuesta, status_code=201)
def crear_comentario(
    blog_id: int,
    datos: ComentarioCrear,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    texto = datos.comentario.strip()
    if not texto:
        raise HTTPException(status_code=422, detail="El comentario no puede estar vacío")
    if db.get(Blog, blog_id) is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")

    if datos.parent_id is not None:
        padre = db.get(Comentario, datos.parent_id)
        if padre is None or padre.blog_id != blog_id:
            raise HTTPException(status_code=404, detail="El comentario al que respondes no existe")

    nuevo = Comentario(
        comentario=texto,
        usr_id=usuario.id_usr,
        blog_id=blog_id,
        parent_id=datos.parent_id,
        estatus=1,
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return _armar_respuestas(db, [nuevo], usuario)[0]


@router.put("/comments/{com_id}", response_model=ComentarioRespuesta)
def editar_comentario(
    com_id: int,
    datos: ComentarioActualizar,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    comentario = _obtener_comentario(db, com_id)
    # Solo el autor edita su comentario (el administrador puede eliminar, pero no editar).
    if comentario.usr_id != usuario.id_usr:
        raise HTTPException(status_code=403, detail="Solo puedes editar tus propios comentarios")
    texto = datos.comentario.strip()
    if not texto:
        raise HTTPException(status_code=422, detail="El comentario no puede estar vacío")
    comentario.comentario = texto
    db.commit()
    db.refresh(comentario)
    return _armar_respuestas(db, [comentario], usuario)[0]


@router.delete("/comments/{com_id}")
def eliminar_comentario(
    com_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    comentario = _obtener_comentario(db, com_id)
    if comentario.usr_id != usuario.id_usr and usuario.tip_usu != ROL_ADMIN:
        raise HTTPException(status_code=403, detail="No tienes permiso para eliminar este comentario")
    db.delete(comentario)  # las respuestas y los votos se eliminan en cascada
    db.commit()
    return {"mensaje": "Comentario eliminado correctamente"}


@router.post("/comments/{com_id}/vote", response_model=ComentarioRespuesta)
def votar_comentario(
    com_id: int,
    datos: VotoRequest,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    """valor: 1 = like, -1 = dislike, 0 = quitar mi voto."""
    comentario = _obtener_comentario(db, com_id)
    voto = db.get(ComentarioVoto, (com_id, usuario.id_usr))

    if datos.valor == 0:
        if voto is not None:
            db.delete(voto)
    elif voto is None:
        db.add(ComentarioVoto(com_id=com_id, usr_id=usuario.id_usr, valor=datos.valor))
    else:
        voto.valor = datos.valor
    db.commit()

    db.refresh(comentario)
    return _armar_respuestas(db, [comentario], usuario)[0]
