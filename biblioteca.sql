-- =====================================================================
-- Laboratorio DB-MYSQL 1&2: Sistema de biblioteca municipal
-- Motor: MySQL 8.0+ (InnoDB)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS biblioteca
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE biblioteca;

-- Permite volver a ejecutar el script completo sin errores
-- (se borran en orden inverso a la dependencia)
DROP TABLE IF EXISTS prestamo;
DROP TABLE IF EXISTS libro_autor;
DROP TABLE IF EXISTS carnet;
DROP TABLE IF EXISTS socio;
DROP TABLE IF EXISTS autor;
DROP TABLE IF EXISTS libro;

-- =====================================================================
-- PARTE 2: CREATE TABLE (orden de dependencia)
-- =====================================================================

-- 1) Tablas sin claves foráneas ----------------------------------------

CREATE TABLE libro (
    id                INT          PRIMARY KEY AUTO_INCREMENT,
    titulo            VARCHAR(100) NOT NULL,
    anio_publicacion  INT          NOT NULL,
    isbn              VARCHAR(20)  NOT NULL UNIQUE,
    genero            VARCHAR(50)  NOT NULL
) ENGINE=InnoDB;

CREATE TABLE autor (
    id                INT          PRIMARY KEY AUTO_INCREMENT,
    nombre            VARCHAR(100) NOT NULL,
    nacionalidad      VARCHAR(50),
    fecha_nacimiento  DATE
) ENGINE=InnoDB;

CREATE TABLE socio (
    id              INT          PRIMARY KEY AUTO_INCREMENT,
    numero_socio    VARCHAR(20)  NOT NULL UNIQUE,
    nombre          VARCHAR(100) NOT NULL,
    email           VARCHAR(100),
    telefono        VARCHAR(20),
    fecha_registro  DATE         NOT NULL
) ENGINE=InnoDB;

-- 2) Tablas que dependen de las anteriores -----------------------------

-- Relación 1:1 con socio: la FK lleva UNIQUE
CREATE TABLE carnet (
    id                INT         PRIMARY KEY AUTO_INCREMENT,
    numero_carnet     VARCHAR(20) NOT NULL UNIQUE,
    fecha_emision     DATE        NOT NULL,
    fecha_vencimiento DATE        NOT NULL,
    socio_id          INT         NOT NULL UNIQUE,
    CONSTRAINT fk_carnet_socio
        FOREIGN KEY (socio_id) REFERENCES socio (id),
    CONSTRAINT ck_carnet_fechas
        CHECK (fecha_vencimiento > fecha_emision)
) ENGINE=InnoDB;

-- Tabla intermedia N:M libro <-> autor, con PK compuesta
CREATE TABLE libro_autor (
    libro_id INT NOT NULL,
    autor_id INT NOT NULL,
    PRIMARY KEY (libro_id, autor_id),
    CONSTRAINT fk_la_libro
        FOREIGN KEY (libro_id) REFERENCES libro (id),
    CONSTRAINT fk_la_autor
        FOREIGN KEY (autor_id) REFERENCES autor (id)
) ENGINE=InnoDB;

-- 3) Al final, la que depende de socio y libro --------------------------

-- Relaciones 1:N: socio -> prestamo y libro -> prestamo.
-- fecha_devolucion es NULL mientras el libro no se haya devuelto.
--
-- Regla "un libro no puede estar prestado a dos socios al mismo tiempo":
-- la columna generada libro_activo vale libro_id solo mientras el préstamo
-- está abierto (sin devolución) y NULL cuando ya se devolvió. Al tener un
-- índice UNIQUE sobre ella, MySQL rechaza un segundo préstamo abierto del
-- mismo libro (los NULL no cuentan como duplicados).
CREATE TABLE prestamo (
    id                INT  PRIMARY KEY AUTO_INCREMENT,
    socio_id          INT  NOT NULL,
    libro_id          INT  NOT NULL,
    fecha_prestamo    DATE NOT NULL,
    fecha_devolucion  DATE NULL,
    libro_activo      INT GENERATED ALWAYS AS
                          (CASE WHEN fecha_devolucion IS NULL
                                THEN libro_id END) VIRTUAL,
    CONSTRAINT fk_prestamo_socio
        FOREIGN KEY (socio_id) REFERENCES socio (id),
    CONSTRAINT fk_prestamo_libro
        FOREIGN KEY (libro_id) REFERENCES libro (id),
    CONSTRAINT ck_prestamo_fechas
        CHECK (fecha_devolucion IS NULL
               OR fecha_devolucion >= fecha_prestamo),
    CONSTRAINT uq_prestamo_libro_activo UNIQUE (libro_activo)
) ENGINE=InnoDB;

-- =====================================================================
-- PARTE 3: INSERT (mismo orden de dependencia)
-- Los id son AUTO_INCREMENT: se generan 1, 2, 3... en orden de inserción.
-- =====================================================================

-- 1) Libros (8) -------------------------------------------------------
INSERT INTO libro (titulo, anio_publicacion, isbn, genero)
VALUES
('Cien años de soledad',            1967, '978-0307474728', 'Realismo mágico'),   -- id 1
('El amor en los tiempos del cólera', 1985, '978-0307389732', 'Novela romántica'), -- id 2
('La casa de los espíritus',        1982, '978-8401337208', 'Realismo mágico'),   -- id 3
('Rayuela',                         1963, '978-8437604572', 'Novela'),            -- id 4
('Ficciones',                       1944, '978-8420633121', 'Cuento'),            -- id 5
('El Aleph',                        1949, '978-8420674209', 'Cuento'),            -- id 6
('Buenos presagios',                1990, '978-0060853983', 'Fantasía'),          -- id 7
('Crónica de una muerte anunciada', 1981, '978-0307387349', 'Novela');            -- id 8

-- 2) Autores (6) ------------------------------------------------------
INSERT INTO autor (nombre, nacionalidad, fecha_nacimiento)
VALUES
('Gabriel García Márquez', 'Colombiana', '1927-03-06'),  -- id 1
('Isabel Allende',         'Chilena',    '1942-08-02'),  -- id 2
('Julio Cortázar',         'Argentina',  '1914-08-26'),  -- id 3
('Jorge Luis Borges',      'Argentina',  '1899-08-24'),  -- id 4
('Terry Pratchett',        'Británica',  '1948-04-28'),  -- id 5
('Neil Gaiman',            'Británica',  '1960-11-10');  -- id 6

-- 3) Socios (5) -------------------------------------------------------
INSERT INTO socio (numero_socio, nombre, email, telefono, fecha_registro)
VALUES
('SOC-001', 'Ana Pérez',      'ana@email.com',   '3001234567', '2024-01-15'),  -- id 1
('SOC-002', 'Luis Gómez',     'luis@email.com',  '3009876543', '2024-02-20'),  -- id 2
('SOC-003', 'Carla Ríos',     'carla@email.com', '3005551234', '2024-03-10'),  -- id 3
('SOC-004', 'Pedro Martínez', 'pedro@email.com', '3007778888', '2024-04-05'),  -- id 4
('SOC-005', 'Sofía Herrera',  'sofia@email.com', '3001112222', '2024-05-12');  -- id 5

-- 4) Carnets (5, uno por socio) ---------------------------------------
INSERT INTO carnet (numero_carnet, fecha_emision, fecha_vencimiento, socio_id)
VALUES
('CAR-1001', '2024-01-15', '2027-01-15', 1),
('CAR-1002', '2024-02-20', '2027-02-20', 2),
('CAR-1003', '2024-03-10', '2027-03-10', 3),
('CAR-1004', '2024-04-05', '2027-04-05', 4),
('CAR-1005', '2024-05-12', '2027-05-12', 5);

-- 5) Libro_autor (8): un autor con varios libros y un libro con varios autores
INSERT INTO libro_autor (libro_id, autor_id)
VALUES
(1, 1),  -- Cien años de soledad -> García Márquez
(2, 1),  -- El amor en los tiempos del cólera -> García Márquez
(8, 1),  -- Crónica de una muerte anunciada -> García Márquez
(3, 2),  -- La casa de los espíritus -> Allende
(4, 3),  -- Rayuela -> Cortázar
(5, 4),  -- Ficciones -> Borges
(6, 4),  -- El Aleph -> Borges
(7, 5),  -- Buenos presagios -> Pratchett
(7, 6);  -- Buenos presagios -> Gaiman (libro con dos autores)

-- 6) Préstamos (7) ----------------------------------------------------
-- El libro 1 se presta tres veces en fechas distintas, sin superponerse.
-- Los que tienen devolución NULL siguen prestados (cada libro, una sola vez).
INSERT INTO prestamo (socio_id, libro_id, fecha_prestamo, fecha_devolucion)
VALUES
(1, 1, '2026-09-01', '2026-09-15'),  -- Ana, Cien años (devuelto)
(2, 1, '2026-09-20', '2026-10-04'),  -- Luis, Cien años (devuelto)
(3, 2, '2026-10-02', '2026-10-16'),  -- Carla, El amor en los tiempos del cólera (devuelto)
(4, 3, '2026-10-10', NULL),          -- Pedro, La casa de los espíritus (pendiente)
(5, 5, '2026-10-15', NULL),          -- Sofía, Ficciones (pendiente)
(1, 4, '2026-10-20', NULL),          -- Ana, Rayuela (pendiente)
(3, 1, '2026-10-25', NULL);          -- Carla, Cien años (pendiente)

-- =====================================================================
-- VERIFICACIÓN: ejecuta cada SELECT y toma la captura de pantalla
-- =====================================================================
SHOW TABLES;

SELECT * FROM libro;
SELECT * FROM autor;
SELECT * FROM socio;
SELECT * FROM carnet;
SELECT * FROM libro_autor;
SELECT * FROM prestamo;

-- Consulta extra: préstamos con nombres legibles
SELECT p.id, s.nombre AS socio, l.titulo AS libro,
       p.fecha_prestamo, p.fecha_devolucion
FROM prestamo p
JOIN socio s ON s.id = p.socio_id
JOIN libro l ON l.id = p.libro_id
ORDER BY p.id;
