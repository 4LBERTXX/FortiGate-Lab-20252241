-- crear_base_datos.sql
-- Script de creación de la base de datos 'shop' para el laboratorio FortiGate

CREATE DATABASE shop;
USE shop;

CREATE TABLE products (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);

INSERT INTO products VALUES
    (1, 'Laptop'),
    (2, 'Mouse'),
    (3, 'Teclado');

CREATE TABLE users (
    username VARCHAR(30),
    password VARCHAR(30)
);

INSERT INTO users VALUES ('admin', 'secreto123');

CREATE USER 'webuser'@'20.25.224.130' IDENTIFIED BY 'Web12345!';
GRANT SELECT ON shop.* TO 'webuser'@'20.25.224.130';
FLUSH PRIVILEGES;
