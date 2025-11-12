CREATE DATABASE IF NOT EXISTS denuncias_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_general_ci;

USE denuncias_db;

CREATE TABLE roles (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO roles (nombre, descripcion) VALUES
('ADMIN', 'Acceso total al sistema y configuración'),
('OPERADOR', 'Gestión de denuncias institucionales'),
('CIUDADANO', 'Usuario que puede registrar y consultar denuncias'),
('ANONIMO', 'Usuario no registrado que envía denuncias sin datos personales');

CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100),
    correo VARCHAR(120) UNIQUE,
    contrasena_hash VARCHAR(255),
    telefono VARCHAR(15),
    id_rol INT,
    activo BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
);

CREATE TABLE denuncias (
    id_denuncia INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(20) UNIQUE,
    id_usuario INT NULL,
    tipo_incidente VARCHAR(100) NOT NULL,
    descripcion TEXT NOT NULL,
    ubicacion_lat DECIMAL(10,8),
    ubicacion_lon DECIMAL(11,8),
    direccion TEXT,
    region VARCHAR(100),
    provincia VARCHAR(100),
    distrito VARCHAR(100),
    estado ENUM('REGISTRADA', 'EN_PROCESO', 'ATENDIDA', 'RECHAZADA') DEFAULT 'REGISTRADA',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

CREATE INDEX idx_denuncias_estado ON denuncias(estado);
CREATE INDEX idx_denuncias_region ON denuncias(region);


CREATE TABLE evidencias (
    id_evidencia INT AUTO_INCREMENT PRIMARY KEY,
    id_denuncia INT NOT NULL,
    url_archivo VARCHAR(255) NOT NULL,
    tipo_archivo ENUM('IMAGEN', 'VIDEO', 'DOCUMENTO') DEFAULT 'IMAGEN',
    hash_archivo VARCHAR(64),
    tamano_kb DECIMAL(10,2),
    fecha_subida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_denuncia) REFERENCES denuncias(id_denuncia)
);

CREATE INDEX idx_evidencia_denuncia ON evidencias(id_denuncia);

CREATE TABLE historial_estados (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_denuncia INT NOT NULL,
    estado_anterior ENUM('REGISTRADA','EN_PROCESO','ATENDIDA','RECHAZADA'),
    estado_nuevo ENUM('REGISTRADA','EN_PROCESO','ATENDIDA','RECHAZADA'),
    cambiado_por INT,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,
    FOREIGN KEY (id_denuncia) REFERENCES denuncias(id_denuncia),
    FOREIGN KEY (cambiado_por) REFERENCES usuarios(id_usuario)
);


CREATE TABLE notificaciones (
    id_notificacion INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    id_denuncia INT,
    mensaje TEXT NOT NULL,
    metodo ENUM('EMAIL','TELEGRAM','WHATSAPP','PUSH') DEFAULT 'EMAIL',
    enviado BOOLEAN DEFAULT FALSE,
    fecha_envio TIMESTAMP NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_denuncia) REFERENCES denuncias(id_denuncia)
);


CREATE TABLE auditoria (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    tabla_afectada VARCHAR(100),
    id_registro INT,
    accion ENUM('INSERT','UPDATE','DELETE'),
    usuario_responsable INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    detalle TEXT,
    FOREIGN KEY (usuario_responsable) REFERENCES usuarios(id_usuario)
);


INSERT INTO usuarios (nombres, apellidos, correo, contrasena_hash, telefono, id_rol)
VALUES 
('Administrador', 'General', 'admin@huancayosolidario.pe', 'hash_admin', '999999999', 1),
('Operador', 'Regional', 'operador@huancayosolidario.pe', 'hash_operador', '988888888', 2),
('Ciudadano', 'Ejemplo', 'ciudadano@correo.com', 'hash_ciudadano', '977777777', 3);

INSERT INTO denuncias (codigo, id_usuario, tipo_incidente, descripcion, ubicacion_lat, ubicacion_lon, direccion, region, provincia, distrito)
VALUES
('D-001', 3, 'Contaminación del río', 'Se observa vertido de residuos al río Mantaro.', -12.073456, -75.204874, 'Av. La Ribera, Huancayo', 'Junín', 'Huancayo', 'El Tambo');

INSERT INTO evidencias (id_denuncia, url_archivo, tipo_archivo, hash_archivo, tamano_kb)
VALUES
(1, 'https://s3.huancayosolidario.pe/evidencias/denuncia1_foto1.jpg', 'IMAGEN', 'abc123', 2048.50),
(1, 'https://s3.huancayosolidario.pe/evidencias/denuncia1_foto2.jpg', 'IMAGEN', 'def456', 1024.20);

INSERT INTO historial_estados (id_denuncia, estado_anterior, estado_nuevo, cambiado_por, observaciones)
VALUES
(1, 'REGISTRADA', 'EN_PROCESO', 2, 'Denuncia verificada, se procede con inspección.');


CREATE VIEW vista_denuncias_completa AS
SELECT 
    d.id_denuncia,
    d.codigo,
    u.nombres AS denunciante,
    d.tipo_incidente,
    d.descripcion,
    d.estado,
    d.region,
    d.provincia,
    d.distrito,
    COUNT(e.id_evidencia) AS total_evidencias,
    d.fecha_registro
FROM denuncias d
LEFT JOIN usuarios u ON d.id_usuario = u.id_usuario
LEFT JOIN evidencias e ON e.id_denuncia = d.id_denuncia
GROUP BY d.id_denuncia;

SELECT codigo, tipo_incidente, estado, total_evidencias
FROM vista_denuncias_completa
WHERE estado <> 'RECHAZADA';
