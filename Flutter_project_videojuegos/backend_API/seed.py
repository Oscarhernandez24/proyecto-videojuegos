"""Asigna contraseñas reales (hasheadas con Argon2) a los usuarios de prueba.

Ejecutar UNA vez después de importar bd.sql:

    python seed.py

Credenciales resultantes:
    adriana@ejemplo.com  ->  Admin12345    (Administrador)
    carlos@ejemplo.com   ->  Autor12345    (Creador / Autor)
    lucia@ejemplo.com    ->  Lector12345   (Lector)
"""
from sqlalchemy import select

from database import SessionLocal
from models import Usuario
from security import hashear

CREDENCIALES = {
    "adriana@ejemplo.com": "Admin12345",
    "carlos@ejemplo.com": "Autor12345",
    "lucia@ejemplo.com": "Lector12345",
}

with SessionLocal() as db:
    for correo, clave in CREDENCIALES.items():
        usuario = db.scalar(select(Usuario).where(Usuario.mail == correo))
        if usuario is None:
            print(f"[omitido] {correo} no existe en la base de datos")
            continue
        usuario.pass_hash = hashear(clave)
        print(f"[ok] {correo} -> {clave}")
    db.commit()
