--Tabla comarca
create table comarca (
	nombre varchar(150),
	codigo varchar(2) primary key,
	habitantes integer,
	superficie float,
	densidad float,
	capital varchar(255)
);

-- Tabla variable
create table variable (
	codigo integer primary key,
	variable varchar(255),
	unidad varchar(10),
	decimales integer
);

CREATE TABLE estacion_a
(
    codigo varchar(15) PRIMARY KEY,
    nombre varchar(255),
    tipo varchar(50),
    altitud float,
    latitud float,
    longitud float
);

CREATE TABLE estacion_m
(
    codigo character(2) primary key,
    nombre character(255),
    latitud float,
    longitud float,
    ubicacion character(255),
    altitud float
);

-- Datos calidad aire
CREATE TABLE datos_aire
(
    codigo_estacion character(15),
    fecha timestamp,
    contaminante character(10),
    unidades character(10),
    valor float
);

-- Datos meteo
create table datos_meteo(
	codigo_estacion varchar(15),
	codigo_variable integer,
	fecha_lectura timestamp,
	valor_lectura float
);

-- Claves externas
alter table datos_aire add foreign key (codigo_estacion) references estacion_a(codigo);
alter table datos_meteo add foreign key (codigo_estacion) references estacion_m(codigo);
alter table datos_meteo add foreign key (codigo_variable) references variable(codigo);