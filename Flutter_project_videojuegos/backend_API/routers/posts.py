"""RF003 Gestión y publicación de posts (CRUD con permisos por autor/administrador)."""
from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, UploadFile
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from database import obtener_sesion
from models import Blog, Categoria, Comentario, Genero, Reaccion, Usuario, Valoracion
from schemas import CatalogoRespuesta, PostRespuesta
from security import ROL_ADMIN, ROL_AUTOR, requiere_roles, usuario_opcional
from utils import borrar_imagen, generos_validos, guardar_imagen, url_imagen

router = APIRouter(prefix="/api/v1/posts", tags=["Publicaciones"])

puede_publicar = requiere_roles(ROL_ADMIN, ROL_AUTOR)


# ------------------------------------------------------------------ helpers
def _armar_respuestas(
    db: Session, posts: list[Blog], usuario: Usuario | None, base_url: str
) -> list[PostRespuesta]:
    """Agrega a cada post su promedio de estrellas, comentarios, reacciones y lo que
    el usuario actual ya votó."""
    ids = [p.id_blog for p in posts]
    if not ids:
        return []

    valoraciones = {
        b: (float(prom or 0), int(total))
        for b, prom, total in db.execute(
            select(Valoracion.blog_id, func.avg(Valoracion.estrellas), func.count())
            .where(Valoracion.blog_id.in_(ids))
            .group_by(Valoracion.blog_id)
        ).all()
    }
    comentarios = {
        b: int(total)
        for b, total in db.execute(
            select(Comentario.blog_id, func.count())
            .where(Comentario.blog_id.in_(ids), Comentario.estatus == 1)
            .group_by(Comentario.blog_id)
        ).all()
    }
    reacciones: dict[int, dict[str, int]] = {}
    for b, emoji, total in db.execute(
        select(Reaccion.blog_id, Reaccion.emoji, func.count())
        .where(Reaccion.blog_id.in_(ids))
        .group_by(Reaccion.blog_id, Reaccion.emoji)
    ).all():
        reacciones.setdefault(b, {})[emoji] = int(total)

    mis_reacciones: dict[int, str] = {}
    mis_valoraciones: dict[int, int] = {}
    if usuario is not None:
        mis_reacciones = {
            b: e
            for b, e in db.execute(
                select(Reaccion.blog_id, Reaccion.emoji).where(
                    Reaccion.blog_id.in_(ids), Reaccion.usr_id == usuario.id_usr
                )
            ).all()
        }
        mis_valoraciones = {
            b: v
            for b, v in db.execute(
                select(Valoracion.blog_id, Valoracion.estrellas).where(
                    Valoracion.blog_id.in_(ids), Valoracion.usr_id == usuario.id_usr
                )
            ).all()
        }

    resultado = []
    for p in posts:
        prom, total = valoraciones.get(p.id_blog, (0.0, 0))
        resultado.append(
            PostRespuesta(
                id_blog=p.id_blog,
                titulo=p.titulo,
                descripcion=p.descripcion,
                img=url_imagen(p.img, base_url),
                tags=p.tags,
                fecha=p.fecha,
                autor_id=p.autor_id,
                autor_nombre=p.autor.nom_usr if p.autor else None,
                categoria_id=p.categoria_id,
                categoria_nombre=p.categoria.nombre if p.categoria else None,
                generos=[CatalogoRespuesta.model_validate(g) for g in p.generos],
                promedio=round(prom, 1),
                total_valoraciones=total,
                total_comentarios=comentarios.get(p.id_blog, 0),
                reacciones=reacciones.get(p.id_blog, {}),
                mi_reaccion=mis_reacciones.get(p.id_blog),
                mi_valoracion=mis_valoraciones.get(p.id_blog),
            )
        )
    return resultado


def _base_url(request: Request) -> str:
    return str(request.base_url).rstrip("/")


def _validar_texto(titulo: str, descripcion: str) -> tuple[str, str]:
    titulo, descripcion = titulo.strip(), descripcion.strip()
    if len(titulo) < 2 or len(titulo) > 150:
        raise HTTPException(status_code=422, detail="El título debe tener entre 2 y 150 caracteres")
    if not descripcion:
        raise HTTPException(status_code=422, detail="El contenido no puede estar vacío")
    if len(descripcion) > 5000:
        raise HTTPException(status_code=422, detail="El contenido no puede superar 5000 caracteres")
    return titulo, descripcion


def _ids_de_texto(texto: str) -> list[int]:
    try:
        return [int(x) for x in texto.split(",") if x.strip()]
    except ValueError:
        raise HTTPException(status_code=422, detail="Lista de géneros inválida")


def _categoria_valida(db: Session, categoria_id: int) -> None:
    existe = db.scalar(
        select(Categoria).where(Categoria.id_categoria == categoria_id, Categoria.estatus == 1)
    )
    if existe is None:
        raise HTTPException(status_code=422, detail="La categoría seleccionada no existe o está inactiva")


def _obtener_post(db: Session, blog_id: int) -> Blog:
    post = db.get(Blog, blog_id)
    if post is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")
    return post


def _verificar_propietario(post: Blog, usuario: Usuario) -> None:
    """Solo el autor de la publicación o un administrador pueden modificarla."""
    if post.autor_id != usuario.id_usr and usuario.tip_usu != ROL_ADMIN:
        raise HTTPException(status_code=403, detail="Solo puedes modificar tus propias publicaciones")


# ---------------------------------------------------------------- endpoints
@router.get("", response_model=list[PostRespuesta])
def listar_posts(
    request: Request,
    genre_id: int | None = None,
    category_id: int | None = None,
    autor_id: int | None = None,
    q: str | None = None,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario | None = Depends(usuario_opcional),
):
    consulta = select(Blog).order_by(Blog.fecha.desc(), Blog.id_blog.desc())
    if genre_id is not None:
        consulta = consulta.where(Blog.generos.any(Genero.id_genero == genre_id))
    if category_id is not None:
        consulta = consulta.where(Blog.categoria_id == category_id)
    if autor_id is not None:
        consulta = consulta.where(Blog.autor_id == autor_id)
    if q and q.strip():
        patron = f"%{q.strip()}%"
        consulta = consulta.where(or_(Blog.titulo.like(patron), Blog.descripcion.like(patron)))

    posts = db.scalars(consulta).unique().all()
    return _armar_respuestas(db, list(posts), usuario, _base_url(request))


@router.get("/{blog_id}", response_model=PostRespuesta)
def obtener_post(
    blog_id: int,
    request: Request,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario | None = Depends(usuario_opcional),
):
    post = _obtener_post(db, blog_id)
    return _armar_respuestas(db, [post], usuario, _base_url(request))[0]


@router.post("", response_model=PostRespuesta, status_code=201)
def crear_post(
    request: Request,
    titulo: str = Form(...),
    descripcion: str = Form(...),
    categoria_id: int = Form(...),
    generos: str = Form(...),
    tags: str | None = Form(None),
    imagen: UploadFile | None = File(None),
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(puede_publicar),
):
    titulo, descripcion = _validar_texto(titulo, descripcion)
    _categoria_valida(db, categoria_id)
    lista_generos = generos_validos(db, _ids_de_texto(generos), obligatorio=True)
    ruta_imagen = guardar_imagen(imagen)

    post = Blog(
        titulo=titulo,
        descripcion=descripcion,
        img=ruta_imagen,
        tags=tags.strip() if tags and tags.strip() else None,
        autor_id=usuario.id_usr,
        categoria_id=categoria_id,
        generos=lista_generos,
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return _armar_respuestas(db, [post], usuario, _base_url(request))[0]


@router.put("/{blog_id}", response_model=PostRespuesta)
def editar_post(
    blog_id: int,
    request: Request,
    titulo: str = Form(...),
    descripcion: str = Form(...),
    categoria_id: int = Form(...),
    generos: str = Form(...),
    tags: str | None = Form(None),
    imagen: UploadFile | None = File(None),
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(puede_publicar),
):
    post = _obtener_post(db, blog_id)
    _verificar_propietario(post, usuario)

    titulo, descripcion = _validar_texto(titulo, descripcion)
    _categoria_valida(db, categoria_id)
    lista_generos = generos_validos(db, _ids_de_texto(generos), obligatorio=True)

    nueva_imagen = guardar_imagen(imagen)
    if nueva_imagen:
        borrar_imagen(post.img)
        post.img = nueva_imagen

    post.titulo = titulo
    post.descripcion = descripcion
    post.categoria_id = categoria_id
    post.tags = tags.strip() if tags and tags.strip() else None
    post.generos = lista_generos
    db.commit()
    db.refresh(post)
    return _armar_respuestas(db, [post], usuario, _base_url(request))[0]


@router.delete("/{blog_id}")
def eliminar_post(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(puede_publicar),
):
    post = _obtener_post(db, blog_id)
    _verificar_propietario(post, usuario)
    imagen = post.img
    db.delete(post)  # comentarios, reacciones y valoraciones se eliminan en cascada
    db.commit()
    borrar_imagen(imagen)
    return {"mensaje": "Publicación eliminada correctamente"}
