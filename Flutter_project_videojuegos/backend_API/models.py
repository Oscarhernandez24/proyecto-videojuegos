"""Modelos SQLAlchemy: reflejan las tablas definidas en bd.sql."""
from sqlalchemy import (
    Column, Integer, SmallInteger, String, Text,
    DateTime, ForeignKey, Table, func,
)
from sqlalchemy.orm import relationship

from database import Base

# Tablas pivote (relaciones muchos a muchos)
usuario_genero = Table(
    "usuario_genero",
    Base.metadata,
    Column("id_usr", Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), primary_key=True),
    Column("id_genero", Integer, ForeignKey("genero.id_genero", ondelete="CASCADE"), primary_key=True),
)

blog_genero = Table(
    "blog_genero",
    Base.metadata,
    Column("id_blog", Integer, ForeignKey("blog.id_blog", ondelete="CASCADE"), primary_key=True),
    Column("id_genero", Integer, ForeignKey("genero.id_genero", ondelete="CASCADE"), primary_key=True),
)


class Genero(Base):
    __tablename__ = "genero"

    id_genero = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(60), unique=True, nullable=False)
    estatus = Column(Integer, nullable=False, default=1)

    @property
    def id(self) -> int:
        return self.id_genero


class Categoria(Base):
    __tablename__ = "categoria"

    id_categoria = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(60), unique=True, nullable=False)
    estatus = Column(Integer, nullable=False, default=1)

    @property
    def id(self) -> int:
        return self.id_categoria


class Usuario(Base):
    __tablename__ = "usuario"

    id_usr = Column(Integer, primary_key=True, index=True)
    nom_usr = Column(String(100), nullable=False)
    mail = Column(String(150), unique=True, nullable=False)
    pass_hash = Column("pass", String(255), nullable=False)
    dir_usr = Column(String(200), nullable=True)
    tip_usu = Column(Integer, nullable=False, default=3)
    estatus = Column(Integer, nullable=False, default=1)
    fecha_registro = Column(DateTime, nullable=False, server_default=func.current_timestamp())

    generos = relationship(
        "Genero", secondary=usuario_genero, lazy="selectin", order_by="Genero.nombre"
    )


class Blog(Base):
    __tablename__ = "blog"

    id_blog = Column(Integer, primary_key=True, index=True)
    titulo = Column(String(150), nullable=False)
    descripcion = Column("desc", Text, nullable=True)
    img = Column(String(500), nullable=True)
    tags = Column(String(255), nullable=True)
    autor_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    categoria_id = Column(Integer, ForeignKey("categoria.id_categoria"), nullable=True)
    fecha = Column(DateTime, nullable=False, server_default=func.current_timestamp())

    autor = relationship("Usuario", lazy="joined")
    categoria = relationship("Categoria", lazy="joined")
    generos = relationship(
        "Genero", secondary=blog_genero, lazy="selectin", order_by="Genero.nombre"
    )


class Comentario(Base):
    __tablename__ = "comentarios"

    id_com = Column(Integer, primary_key=True, index=True)
    comentario = Column(Text, nullable=False)
    fecha = Column(DateTime, nullable=False, server_default=func.current_timestamp())
    estatus = Column(Integer, nullable=False, default=1)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    blog_id = Column(Integer, ForeignKey("blog.id_blog", ondelete="CASCADE"), nullable=False)
    parent_id = Column(Integer, ForeignKey("comentarios.id_com", ondelete="CASCADE"), nullable=True)

    autor = relationship("Usuario", lazy="joined")


class ComentarioVoto(Base):
    __tablename__ = "comentario_voto"

    com_id = Column(Integer, ForeignKey("comentarios.id_com", ondelete="CASCADE"), primary_key=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), primary_key=True)
    valor = Column(SmallInteger, nullable=False)


class Reaccion(Base):
    __tablename__ = "reaccion"

    blog_id = Column(Integer, ForeignKey("blog.id_blog", ondelete="CASCADE"), primary_key=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), primary_key=True)
    emoji = Column(String(16), nullable=False)


class Valoracion(Base):
    __tablename__ = "valoracion"

    blog_id = Column(Integer, ForeignKey("blog.id_blog", ondelete="CASCADE"), primary_key=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), primary_key=True)
    estrellas = Column(Integer, nullable=False)


class RecuperacionPassword(Base):
    __tablename__ = "recuperacion_password"

    id = Column(Integer, primary_key=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False)
    codigo_hash = Column(String(255), nullable=False)
    expira = Column(DateTime, nullable=False)
    usado = Column(Integer, nullable=False, default=0)
