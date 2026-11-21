"""RF005 Categorías y RF006 Géneros: CRUD para el administrador, consulta pública."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database import obtener_sesion
from models import Blog, Categoria, Genero, Usuario, blog_genero, usuario_genero
from schemas import CatalogoActualizar, CatalogoCrear, CatalogoRespuesta
from security import ROL_ADMIN, requiere_roles, usuario_opcional

solo_admin = requiere_roles(ROL_ADMIN)


def _crear_router(ruta: str, etiqueta: str, Modelo, en_uso) -> APIRouter:
    """Genera los endpoints CRUD de un catálogo (mismo comportamiento para géneros y categorías)."""
    router = APIRouter(prefix=f"/api/v1/{ruta}", tags=[etiqueta])

    @router.get("", response_model=list[CatalogoRespuesta])
    def listar(
        incluir_inactivos: bool = False,
        db: Session = Depends(obtener_sesion),
        usuario: Usuario | None = Depends(usuario_opcional),
    ):
        consulta = select(Modelo).order_by(Modelo.nombre)
        # Solo el administrador puede ver los elementos desactivados.
        if not (incluir_inactivos and usuario is not None and usuario.tip_usu == ROL_ADMIN):
            consulta = consulta.where(Modelo.estatus == 1)
        return db.scalars(consulta).all()

    @router.post("", response_model=CatalogoRespuesta, status_code=201)
    def crear(
        datos: CatalogoCrear,
        db: Session = Depends(obtener_sesion),
        _admin: Usuario = Depends(solo_admin),
    ):
        item = Modelo(nombre=datos.nombre.strip(), estatus=1)
        db.add(item)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=409, detail="Ya existe un registro con ese nombre")
        db.refresh(item)
        return item

    @router.put("/{item_id}", response_model=CatalogoRespuesta)
    def actualizar(
        item_id: int,
        datos: CatalogoActualizar,
        db: Session = Depends(obtener_sesion),
        _admin: Usuario = Depends(solo_admin),
    ):
        item = db.get(Modelo, item_id)
        if item is None:
            raise HTTPException(status_code=404, detail="Registro no encontrado")
        item.nombre = datos.nombre.strip()
        item.estatus = datos.estatus
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=409, detail="Ya existe un registro con ese nombre")
        db.refresh(item)
        return item

    @router.delete("/{item_id}")
    def eliminar(
        item_id: int,
        db: Session = Depends(obtener_sesion),
        _admin: Usuario = Depends(solo_admin),
    ):
        item = db.get(Modelo, item_id)
        if item is None:
            raise HTTPException(status_code=404, detail="Registro no encontrado")
        if en_uso(db, item_id):
            raise HTTPException(
                status_code=409,
                detail="Tiene publicaciones o usuarios asociados. Desactívalo en lugar de eliminarlo",
            )
        db.delete(item)
        db.commit()
        return {"mensaje": "Eliminado correctamente"}

    return router


def _genero_en_uso(db: Session, genero_id: int) -> bool:
    en_posts = db.scalar(
        select(func.count()).select_from(blog_genero).where(blog_genero.c.id_genero == genero_id)
    )
    en_usuarios = db.scalar(
        select(func.count()).select_from(usuario_genero).where(usuario_genero.c.id_genero == genero_id)
    )
    return bool(en_posts or en_usuarios)


def _categoria_en_uso(db: Session, categoria_id: int) -> bool:
    total = db.scalar(
        select(func.count()).select_from(Blog).where(Blog.categoria_id == categoria_id)
    )
    return bool(total)


router_generos = _crear_router("genres", "Géneros", Genero, _genero_en_uso)
router_categorias = _crear_router("categories", "Categorías", Categoria, _categoria_en_uso)
