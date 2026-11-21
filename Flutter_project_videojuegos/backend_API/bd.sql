-- =====================================================================
--  Blog de Videojuegos - Script de creación de base de datos (MySQL)
--  Uso:  mysql -u root -p < bd.sql     y después:  python seed.py
--  El script es re-ejecutable: no borra datos existentes.
-- =====================================================================
CREATE DATABASE IF NOT EXISTS bd_blog_videojuegos
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE bd_blog_videojuegos;

-- Roles (tip_usu): 1 = Administrador, 2 = Creador / Autor, 3 = Lector
-- estatus: 1 = activo, 0 = baja lógica
CREATE TABLE IF NOT EXISTS usuario (
    id_usr         INT AUTO_INCREMENT PRIMARY KEY,
    nom_usr        VARCHAR(100) NOT NULL,
    mail           VARCHAR(150) NOT NULL UNIQUE,
    pass           VARCHAR(255) NOT NULL,          -- hash Argon2, nunca texto plano
    dir_usr        VARCHAR(200),
    tip_usu        INT NOT NULL DEFAULT 3,
    estatus        INT NOT NULL DEFAULT 1,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Géneros de videojuegos (Acción, RPG, Shooter...)
CREATE TABLE IF NOT EXISTS genero (
    id_genero INT AUTO_INCREMENT PRIMARY KEY,
    nombre    VARCHAR(60) NOT NULL UNIQUE,
    estatus   INT NOT NULL DEFAULT 1
);

-- Categorías editoriales (Reseñas, Noticias, Guías...)
CREATE TABLE IF NOT EXISTS categoria (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre       VARCHAR(60) NOT NULL UNIQUE,
    estatus      INT NOT NULL DEFAULT 1
);

-- Géneros favoritos del usuario (se eligen al registrarse)
CREATE TABLE IF NOT EXISTS usuario_genero (
    id_usr    INT NOT NULL,
    id_genero INT NOT NULL,
    PRIMARY KEY (id_usr, id_genero),
    FOREIGN KEY (id_usr)    REFERENCES usuario(id_usr)  ON DELETE CASCADE,
    FOREIGN KEY (id_genero) REFERENCES genero(id_genero) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS blog (
    id_blog      INT AUTO_INCREMENT PRIMARY KEY,
    titulo       VARCHAR(150) NOT NULL,
    `desc`       TEXT,
    img          VARCHAR(500),
    tags         VARCHAR(255),
    autor_id     INT NOT NULL,
    categoria_id INT NULL,
    fecha        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_blog_autor     FOREIGN KEY (autor_id)     REFERENCES usuario(id_usr),
    CONSTRAINT fk_blog_categoria FOREIGN KEY (categoria_id) REFERENCES categoria(id_categoria)
);

-- Un post puede tener uno o varios géneros
CREATE TABLE IF NOT EXISTS blog_genero (
    id_blog   INT NOT NULL,
    id_genero INT NOT NULL,
    PRIMARY KEY (id_blog, id_genero),
    FOREIGN KEY (id_blog)   REFERENCES blog(id_blog)     ON DELETE CASCADE,
    FOREIGN KEY (id_genero) REFERENCES genero(id_genero) ON DELETE CASCADE
);

-- parent_id permite responder a otro comentario
CREATE TABLE IF NOT EXISTS comentarios (
    id_com     INT AUTO_INCREMENT PRIMARY KEY,
    comentario TEXT NOT NULL,
    fecha      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estatus    INT NOT NULL DEFAULT 1,
    usr_id     INT NOT NULL,
    blog_id    INT NOT NULL,
    parent_id  INT NULL,
    CONSTRAINT fk_comentario_usuario FOREIGN KEY (usr_id)    REFERENCES usuario(id_usr),
    CONSTRAINT fk_comentario_blog    FOREIGN KEY (blog_id)   REFERENCES blog(id_blog)        ON DELETE CASCADE,
    CONSTRAINT fk_comentario_padre   FOREIGN KEY (parent_id) REFERENCES comentarios(id_com)  ON DELETE CASCADE
);

-- Like (1) / dislike (-1) a comentarios: un voto por usuario
CREATE TABLE IF NOT EXISTS comentario_voto (
    com_id INT NOT NULL,
    usr_id INT NOT NULL,
    valor  SMALLINT NOT NULL,
    PRIMARY KEY (com_id, usr_id),
    FOREIGN KEY (com_id) REFERENCES comentarios(id_com) ON DELETE CASCADE,
    FOREIGN KEY (usr_id) REFERENCES usuario(id_usr)     ON DELETE CASCADE
);

-- Reacción con emoji a una publicación: una por usuario
CREATE TABLE IF NOT EXISTS reaccion (
    blog_id INT NOT NULL,
    usr_id  INT NOT NULL,
    emoji   VARCHAR(16) NOT NULL,
    PRIMARY KEY (blog_id, usr_id),
    FOREIGN KEY (blog_id) REFERENCES blog(id_blog)  ON DELETE CASCADE,
    FOREIGN KEY (usr_id)  REFERENCES usuario(id_usr) ON DELETE CASCADE
);

-- Valoración de 1 a 5 estrellas: una por usuario
CREATE TABLE IF NOT EXISTS valoracion (
    blog_id   INT NOT NULL,
    usr_id    INT NOT NULL,
    estrellas INT NOT NULL,
    PRIMARY KEY (blog_id, usr_id),
    FOREIGN KEY (blog_id) REFERENCES blog(id_blog)  ON DELETE CASCADE,
    FOREIGN KEY (usr_id)  REFERENCES usuario(id_usr) ON DELETE CASCADE
);

-- Códigos temporales para recuperar contraseña (se guarda solo el hash)
CREATE TABLE IF NOT EXISTS recuperacion_password (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    usr_id      INT NOT NULL,
    codigo_hash VARCHAR(255) NOT NULL,
    expira      DATETIME NOT NULL,
    usado       INT NOT NULL DEFAULT 0,
    FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
--  Datos iniciales
-- ---------------------------------------------------------------------
INSERT IGNORE INTO genero (id_genero, nombre) VALUES
    (1, 'Acción'), (2, 'Aventura'), (3, 'RPG'), (4, 'Shooter'),
    (5, 'Estrategia'), (6, 'Deportes'), (7, 'Indie'), (8, 'Terror'),
    (9, 'Simulación'), (10, 'Carreras');

INSERT IGNORE INTO categoria (id_categoria, nombre) VALUES
    (1, 'Reseñas de juegos'), (2, 'Noticias de lanzamientos'),
    (3, 'Guías y trucos'), (4, 'Entrevistas'), (5, 'Recomendaciones');

-- IMPORTANTE: 'HASH_DE_PRUEBA' no es un hash válido. Después de importar este
-- archivo ejecuta `python seed.py` para asignar contraseñas reales.
INSERT IGNORE INTO usuario (id_usr, nom_usr, mail, pass, dir_usr, tip_usu) VALUES
    (1, 'Adriana Contreras', 'adriana@ejemplo.com', 'HASH_DE_PRUEBA', 'Querétaro', 1),
    (2, 'Carlos Pérez',      'carlos@ejemplo.com',  'HASH_DE_PRUEBA', 'Querétaro', 2),
    (3, 'Lucía Torres',      'lucia@ejemplo.com',   'HASH_DE_PRUEBA', 'Querétaro', 3);

INSERT IGNORE INTO usuario_genero (id_usr, id_genero) VALUES
    (2, 1), (2, 3), (3, 2), (3, 7);

INSERT IGNORE INTO blog (id_blog, titulo, `desc`, img, tags, autor_id, categoria_id) VALUES
    (1, 'Reseña: aventuras de mundo abierto que sí valen la pena',
        'Un recorrido por los mundos abiertos más memorables de los últimos años: exploración libre, buenas historias y mucho que descubrir fuera del camino principal.',
        'https://picsum.photos/800/400?random=1', 'mundo abierto,aventura', 2, 1),
    (2, 'Los lanzamientos más esperados del año',
        'Resumen de los juegos que más expectativa generan: fechas, plataformas y lo que sabemos hasta ahora de cada uno.',
        'https://picsum.photos/800/400?random=2', 'lanzamientos,2026', 2, 2),
    (3, 'Guía para empezar en un RPG sin perderte',
        'Consejos básicos de builds, recursos y misiones secundarias para que tus primeras horas en un RPG sean más fáciles.',
        'https://picsum.photos/800/400?random=3', 'guía,rpg', 1, 3);

INSERT IGNORE INTO blog_genero (id_blog, id_genero) VALUES
    (1, 2), (1, 1), (2, 1), (2, 4), (3, 3);

INSERT IGNORE INTO comentarios (id_com, comentario, usr_id, blog_id, parent_id) VALUES
    (1, 'Muy útil la selección, ya anoté un par de juegos.', 3, 1, NULL),
    (2, '¡Gracias! Me alegra que te sirviera.', 2, 1, 1),
    (3, 'Ojalá hubiera más información de fechas.', 3, 2, NULL);

INSERT IGNORE INTO comentario_voto (com_id, usr_id, valor) VALUES
    (1, 2, 1), (1, 1, 1), (3, 2, -1);

INSERT IGNORE INTO reaccion (blog_id, usr_id, emoji) VALUES
    (1, 3, '🔥'), (1, 1, '🎮'), (2, 3, '😮');

INSERT IGNORE INTO valoracion (blog_id, usr_id, estrellas) VALUES
    (1, 3, 5), (1, 1, 4), (2, 3, 4);
