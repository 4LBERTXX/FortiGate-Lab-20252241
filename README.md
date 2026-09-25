# 🔒 FortiGate — Firewall Perimetral con VLSM, DPI e IPS Anti-SQL Injection

**Matrícula 20252241**

![FortiGate](https://img.shields.io/badge/Fortinet-FortiGate%207.0.9-EE3124?style=for-the-badge&logo=fortinet&logoColor=white)
![GNS3](https://img.shields.io/badge/Emulador-GNS3-009639?style=for-the-badge)
![GUI](https://img.shields.io/badge/Configuraci%C3%B3n-100%25%20GUI-2E8B57?style=for-the-badge)

> Firewall perimetral FortiGate configurado íntegramente por GUI: segmentación de red en VLANs (Usuarios, WEB, DB) mediante VLSM, control de acceso HTTPS entre segmentos, aislamiento total de la base de datos frente a los usuarios, inspección profunda de tráfico (DPI) con un IPS personalizado que detecta y bloquea intentos de SQL Injection poniendo al atacante en cuarentena, filtrado de descargas ejecutables y una política anti-DoS.

---

## 📺 Video de Demostración

> **[Ver demostración en YouTube/OneDrive →](PON-AQUI-EL-LINK-DEL-VIDEO)**

*(Sustituye este enlace por el link real una vez subas el video. Recuerda: debe mostrar hora y fecha, tu cara, tu voz, y máximo 10 minutos.)*

---

## 📑 Tabla de Contenido

1. [Objetivo de la Red](#-objetivo-de-la-red)
2. [Cumplimiento de Requisitos](#-cumplimiento-de-requisitos)
3. [Parámetros Usados](#-parámetros-usados)
4. [Documentación de la Red](#️-documentación-de-la-red)
5. [Funcionamiento de la Configuración](#-funcionamiento-de-la-configuración)
6. [Configuración de FortiOS](#-configuración-de-fortios)
7. [Validación de la Implementación](#-validación-de-la-implementación)
8. [Capturas de Pantalla](#-capturas-de-pantalla)

---

## 🎯 Objetivo de la Red

Implementar una topología de red segmentada y protegida mediante un firewall **FortiGate**, capaz de controlar de forma granular el acceso entre tres segmentos de red: **Usuarios**, **WEB-Server** y **DB-Server**.

El objetivo es que los usuarios solo puedan comunicarse con el servidor web por HTTPS, que la base de datos quede completamente aislada de los usuarios, y que el propio servidor web solo pueda hablar con la base de datos por el puerto necesario (3306). Sobre ese tráfico permitido se aplica inspección profunda (DPI) para poder analizar el contenido cifrado y detectar ataques de **SQL Injection**, bloqueándolos y colocando al atacante en cuarentena automáticamente. Adicionalmente, se protege el servidor frente a descargas de archivos ejecutables y ataques de denegación de servicio (DoS) mediante rate limiting.

El direccionamiento de toda la topología se calculó mediante VLSM a partir de mi matrícula (20252241 → base de red `20.25.224.0/24`).

---

## ✅ Cumplimiento de Requisitos

| Requisito | Implementado con |
|---|---|
| Configuración por GUI | Todas las políticas, perfiles y objetos se configuraron desde la interfaz web de FortiOS |
| Ruta por defecto | `config router static` — ruta `0.0.0.0/0` vía `port1` (WAN) |
| NAT | `set nat enable` en la política de salida a Internet de los usuarios |
| Permitir Usuarios → WEB-Server (443) | Política **Users-to-Web**: `VLAN10 → VLAN20`, servicio `HTTPS`, acción `Accept` |
| Bloquear Usuarios → DB-Server (3306) | Política **Block-Users-DB**: `VLAN10 → VLAN30`, servicio `MYSQL`, sin acción explícita de permiso (cae en deny) |
| Activar DPI | `ssl-ssh-profile "deep-inspection"` en modo *Full SSL Inspection*, aplicado en la política Users-to-Web |
| Detección y bloqueo de SQL Injection + cuarentena | Firma IPS personalizada `SQLI.2241` (patrón `UNION SELECT`, contexto `uri`) dentro del sensor **SQL-INJECTION DETECTIONS**, con acción `block` + `quarantine attacker` |
| WEB-Server solo habla con DB-Server por 3306 | Política **Web-to-DB**: `VLAN20 → VLAN30`, único servicio permitido `MYSQL`; cualquier otro tráfico entre esos segmentos cae en el deny implícito |
| Bloqueo de descargas .exe | Perfil File Filter **Block-Executables**, bloqueando tipos `exe`, `msi`, `bat` en HTTP/HTTPS entrante |
| Rate limiting / anti-DoS | **DoS Policy** sobre `VLAN10`, con anomalías `tcp_syn_flood`, `tcp_port_scan`, `udp_flood` e `icmp_flood` en modo `block` |
| VLANs | VLAN10 (Usuarios), VLAN20 (WEB), VLAN30 (DB) configuradas como sub-interfaces 802.1Q sobre `port2` del FortiGate y como VLANs en el switch |
| Seguridad básica de red en el switch | Port-security (máx. MACs, sticky, violation restrict), Spanning-Tree PortFast + BPDU Guard, DHCP Snooping y ARP Inspection en la VLAN de usuarios |
| DHCP para Usuarios | Servidor DHCP del FortiGate en `VLAN10`, rango `20.25.224.2 – 20.25.224.126` |

---

## 🧩 Parámetros Usados

| Parámetro | Valor |
|---|---|
| Plataforma | FortiGate-VM64-KVM, FortiOS 7.0.9 |
| Emulador | GNS3 |
| Switch | Cisco IOSv |
| Base de red (VLSM, por matrícula) | `20.25.224.0/24` |
| VLAN10 — Usuarios | `20.25.224.0/25` — GW `.1`, DHCP `.2 – .126` |
| VLAN20 — WEB-Server | `20.25.224.128/28` — GW `.129`, servidor `.130` |
| VLAN30 — DB-Server | `20.25.224.144/28` — GW `.145`, servidor `.146` |
| Interfaz WAN (port1) | DHCP (hacia Internet/NAT1) |
| Interfaz trunk (port2) | 802.1Q, subinterfaces VLAN10/20/30 |
| Perfil SSL Inspection | `deep-inspection` — Full SSL Inspection |
| Firma IPS personalizada | `SQLI.2241` — attack_id `9916`, patrón `UNION SELECT`, contexto `uri` |
| Sensor IPS | `SQL-INJECTION DETECTIONS` — acción `block` + cuarentena 10 min |
| Perfil File Filter | `Block-Executables` — bloquea `.exe`, `.msi`, `.bat` |
| DoS Policy | Aplicada sobre `VLAN10`, anomalías SYN flood / port scan / UDP flood / ICMP flood |
| Servidor WEB | Ubuntu Server + Apache2 + PHP + OpenSSL (certificado autofirmado) |
| Servidor DB | Ubuntu Server + MariaDB |

---

## 🗺️ Documentación de la Red

### Topología

(images/01-topologia.png)

### Tabla de Direccionamiento

| Dispositivo | VLAN | IP | Rol |
|---|---|---|---|
| FortiGate — VLAN10 | 10 | 20.25.224.1/25 | Gateway de Usuarios |
| FortiGate — VLAN20 | 20 | 20.25.224.129/28 | Gateway de WEB-Server |
| FortiGate — VLAN30 | 30 | 20.25.224.145/28 | Gateway de DB-Server |
| Usuarios | 10 | 20.25.224.2 – .126 (DHCP) | Clientes de prueba |
| WEB-Server | 20 | 20.25.224.130 | Apache2 + PHP + HTTPS |
| DB-Server | 30 | 20.25.224.146 | MariaDB |

---

## 🔬 Funcionamiento de la Configuración

**Segmentación e IP:**
El switch entrega tres VLANs sobre un enlace trunk hacia el FortiGate, que las termina como subinterfaces 802.1Q sobre `port2`. Cada VLAN corresponde a un segmento distinto (Usuarios, WEB, DB), calculado con VLSM a partir de mi matrícula.

**Acceso controlado Usuarios → WEB-Server:**
La única política que conecta `VLAN10` con `VLAN20` es **Users-to-Web**, restringida al servicio `HTTPS`. Como FortiGate deniega todo por defecto, cualquier otro protocolo hacia el WEB-Server queda bloqueado sin necesidad de una regla explícita adicional.

**Aislamiento del DB-Server frente a Usuarios:**
La política **Block-Users-DB** cubre el tráfico `VLAN10 → VLAN30` sin otorgarle acción de aceptación, por lo que cualquier intento de los usuarios de llegar al puerto 3306 (o cualquier otro) del DB-Server se descarta.

**DPI e IPS anti-SQL Injection:**
La política Users-to-Web tiene asignado el perfil `deep-inspection` en modo *Full SSL Inspection*, lo que permite al FortiGate descifrar el tráfico HTTPS y analizarlo. Sobre ese tráfico descifrado actúa el sensor IPS **SQL-INJECTION DETECTIONS**, que contiene la firma personalizada `SQLI.2241` (busca el patrón `UNION SELECT` en la URI de la petición). Cuando la firma coincide, la acción configurada es `block` junto con `quarantine attacker`, lo que corta la conexión y coloca la IP del atacante en cuarentena por un tiempo definido.

**WEB-Server limitado a hablar solo con DB-Server por 3306:**
La política **Web-to-DB** es la única que conecta `VLAN20` con `VLAN30`, y su servicio está restringido a `MYSQL` (puerto 3306). Cualquier otro intento de comunicación entre esos dos segmentos —incluyendo salida del WEB-Server a Internet— queda bloqueado por el deny implícito una vez retirada cualquier política temporal de acceso a Internet usada solo durante la instalación de paquetes.

**Filtrado de descargas .exe:**
El perfil File Filter **Block-Executables** está asignado en la política Users-to-Web y bloquea archivos de tipo `.exe`, `.msi` y `.bat` en tráfico HTTP/HTTPS entrante, evitando que un usuario descargue ejecutables desde el WEB-Server.

**Rate limiting / anti-DoS:**
La DoS Policy aplicada sobre `VLAN10` define umbrales para anomalías como `tcp_syn_flood`, `tcp_port_scan`, `udp_flood` e `icmp_flood`. Al superarse el umbral de paquetes por segundo, FortiGate bloquea automáticamente la fuente y lo registra en los logs.

**Seguridad básica del switch:**
Los puertos de acceso tienen port-security (límite de MACs, aprendizaje sticky, violación en modo restrict), Spanning-Tree PortFast con BPDU Guard, y la VLAN de usuarios cuenta con DHCP Snooping y ARP Inspection para mitigar DHCP rogue y ARP spoofing.

---

## 🔧 Configuración de FortiOS

> Toda la configuración se realizó desde la GUI de FortiOS. Los bloques siguientes son el equivalente en CLI, incluidos como referencia y documentación técnica.

**Interfaces VLAN:**
```
config system interface
edit VLAN10
set vdom root
set interface port2
set vlanid 10
set ip 20.25.224.1 255.255.255.128
set allowaccess ping
set role lan
next
edit VLAN20
set vdom root
set interface port2
set vlanid 20
set ip 20.25.224.129 255.255.255.240
set allowaccess ping
set role lan
next
edit VLAN30
set vdom root
set interface port2
set vlanid 30
set ip 20.25.224.145 255.255.255.240
set allowaccess ping
set role lan
next
end
```

**DHCP para VLAN10:**
```
config system dhcp server
edit 1
set interface VLAN10
set default-gateway 20.25.224.1
set netmask 255.255.255.128
set dns-service specify
set dns-server1 8.8.8.8
config ip-range
edit 1
set start-ip 20.25.224.2
set end-ip 20.25.224.126
next
end
next
end
```

**Ruta por defecto:**
```
config router static
edit 1
set dst 0.0.0.0 0.0.0.0
set gateway <gateway real de port1>
set device port1
next
end
```

**Políticas de firewall:**
```
config firewall policy
edit 1
set name "Users-to-Web"
set srcintf VLAN10
set dstintf VLAN20
set srcaddr USERS
set dstaddr WEB-SERVER
set action accept
set schedule always
set service HTTPS
set logtraffic all
set utm-status enable
set ssl-ssh-profile "deep-inspection"
set ips-sensor "SQL-INJECTION DETECTIONS"
set file-filter-profile "Block-Executables"
next
edit 2
set name "Block-Users-DB"
set srcintf VLAN10
set dstintf VLAN30
set srcaddr USERS
set dstaddr DB-SERVER
set schedule always
set service MYSQL
set logtraffic all
next
edit 3
set name "Web-to-DB"
set srcintf VLAN20
set dstintf VLAN30
set action accept
set srcaddr WEB-SERVER
set dstaddr DB-SERVER
set schedule always
set service MYSQL
set logtraffic all
set utm-status enable
set ips-sensor "SQL-INJECTION DETECTIONS"
next
end
```

**Firma IPS personalizada (SQL Injection):**
```
config ips custom
edit "SQL-INJECTION"
set signature "F-SBID( --attack_id 9916; --name \"SQLI.2241\"; --severity high; --protocol tcp; --service HTTP; --flow from_client; --pattern \"UNION SELECT\"; --context uri; --no_case; )"
set severity high
next
end
```

**Sensor IPS con bloqueo y cuarentena:**
```
config ips sensor
edit "SQL-INJECTION DETECTIONS"
config entries
edit 1
set rule 9916
set status enable
set log-packet enable
set action block
set quarantine attacker
set quarantine-expiry 10m
set quarantine-log enable
next
end
next
end
```

**Filtro de archivos (.exe):**
```
config file-filter profile
edit "Block-Executables"
config rules
edit 1
set name "block-exe"
set protocol http https
set action block
set direction incoming
set file-type "exe" "msi" "bat"
next
end
next
end
```

**DoS Policy (rate limiting):**
```
config firewall DoS-policy
edit 1
set interface VLAN10
set srcaddr all
set dstaddr all
set service ALL
config anomaly
edit tcp_syn_flood
set status enable
set log enable
set action block
set threshold 200
next
edit tcp_port_scan
set status enable
set log enable
set action block
next
edit udp_flood
set status enable
set log enable
set action block
next
edit icmp_flood
set status enable
set log enable
set action block
next
end
next
end
```

---

## ✅ Validación de la Implementación

**Prueba 1 — Acceso permitido al WEB-Server (política 1):**
```bash
curl -k https://20.25.224.130/
```
El WEB-Server responde normalmente por HTTPS.

**Prueba 2 — Bloqueo del DB-Server desde Usuarios (política 2):**
```bash
nc -zv -w 3 20.25.224.146 3306
```
La conexión no se establece: el tráfico queda bloqueado por el deny implícito.

**Prueba 3 — Detección y bloqueo de SQL Injection con cuarentena:**
```bash
curl -k -G "https://20.25.224.130/" --data-urlencode "id=1 UNION SELECT username,password FROM users"
```
El sensor IPS detecta el patrón `UNION SELECT`, bloquea la sesión y coloca la IP de origen en cuarentena (verificable en **Log & Report > Intrusion Prevention** y en **Dashboard > Quarantine Monitor**).

**Prueba 4 — Bloqueo de descarga de ejecutables:**
```bash
curl -k -O https://20.25.224.130/prueba.exe
```
La descarga es bloqueada por el perfil File Filter.

**Prueba 5 — Restricción WEB-Server → DB-Server solo por 3306:**
Con la política temporal de salida a Internet desactivada, desde el WEB-Server:
```bash
curl -k https://8.8.8.8 --max-time 5     # debe fallar
nc -zv -w 3 20.25.224.146 3306            # debe responder
```
Confirma que el WEB-Server únicamente puede comunicarse con el DB-Server por el puerto de base de datos.

**Prueba 6 — Rate limiting / anti-DoS:**
```bash
sudo hping3 -S --flood -p 443 20.25.224.130
```
La DoS Policy detecta el patrón de flood y bloquea la fuente, registrándolo en los logs.

---

## 📸 Capturas de Pantalla

```
images/
├── 01_topologia.png
├── 02_interfaces.png
├── 03_Firewall Policy.png
├── 04_Politica Web-toD-B.png
├── 05_deep-inspection.png
├── 06_ips- certificado.png
├── 07_instrusion prevention-sql-injection.png
├── 08_File filter.png
├── 09_VLANS y port-security del Switch.png
├── 10_Prueba acceso permitido al WEB.png
├── 11_Prueba bloqueo al DB-Server.png
├── 12_ruta por defecto.png
```
> Pendientes por capturar: interfaces VLAN, DHCP, ruta por defecto, política Web-to-DB, configuración del switch, y las capturas de las pruebas de validación (4–19 según corresponda).
