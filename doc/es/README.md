# fnOS-cust-kernel

[简体中文](../../README.md) | [English](../en/README.md) | **Español**

Un kernel que sigue recibiendo correcciones de seguridad del upstream para los sistemas que permanecen en fnOS 1.2.1000: Linux 6.18 LTS oficial más los parches privados de fnOS restaurados por ingeniería inversa.

[![License](https://img.shields.io/badge/License-GPL--2.0--only-orange)](../../LICENSE)
[![Release](https://img.shields.io/github/v/release/CharlesGool/fnOS-cust-kernel?logo=github)](https://github.com/CharlesGool/fnOS-cust-kernel/releases/latest)

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Estado del proyecto: [LOG](LOG.md)
- Registros históricos: [HISTORY](HISTORY.md)
- Historial de cambios: [CHANGELOG](CHANGELOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Introducción

fnOS 1.2.1000 incluye el kernel `6.18.18.c1186-trim`, con muchos cambios privados cuyo código fuente fnOS no publica. Este proyecto restaura esos cambios por ingeniería inversa como parches de código fuente en C, los porta al 6.18 LTS oficial (mantenido hasta 2028-12), y compila y aplica los parches de seguridad por su cuenta. Este proyecto no tiene relación con fnOS.

- Paquete del kernel `linux-image-6.18.65.c1186-trim`, que puede sustituir al kernel original de fnOS 1.2.1000; la cadena de versión conserva el sufijo `.c1186-trim` de fnOS.
- Funciones de fnOS restauradas: permisos trimacl (VFS, ext4, btrfs, fuse, nfsd, ZFS), 11 llamadas al sistema trim, papelera de reciclaje, sistema de archivos trimafs2, notificación de eventos de sysdiag, cambios de DFR y llbitmap en md, llamada al sistema recvfile, velocidad mixta en bonding, cambios en controladores de red y libata. btrfs es un port completo de la versión 7.0.9 del upstream que hizo fnOS.
- 4 correcciones de seguridad de NFS (que la versión original de fnOS no tiene); véase [CHANGELOG](CHANGELOG.md).
- El paquete incluye OpenZFS 2.4.1 y los mismos controladores externos que fnOS (controladores de red del fabricante Realtek, controladores NVIDIA de código abierto y propietarios, tarjetas inalámbricas, etc.), con la misma disposición de directorios que fnOS.
- Los problemas conocidos están en [Errores de LOG](LOG.md#errores); los objetivos pendientes, en [Objetivos de diseño de DESIGN](DESIGN.md#objetivos-de-diseño).

## Requisitos

Ejecución:

- fnOS 1.2.1000, x86_64.

Compilación:

- Host Linux x86_64 con Docker y `curl`, con acceso a las direcciones de la tabla siguiente. El directorio de dependencias (`CK_DEPS_DIR`) necesita unos 30 GB de espacio libre y no puede estar en un volumen de almacenamiento de fnOS.
- El contenedor de compilación lo crea `ck.sh container`: `debian:12` con las dependencias de compilación; el compilador es `gcc (Debian 12.2.0-14+deb12u1) 12.2.0` (el mismo que el original de fnOS) y `pahole` es la v1.31 compilada desde el código fuente.

La compilación descarga lo siguiente, todo en el directorio de dependencias o en el contenedor de compilación, y lo verifica con los sha256 de `config/versions.conf` o con la firma de kernel.org:

| Contenido | Origen | Tamaño | Comando |
| --- | --- | --- | --- |
| Imagen de Docker `debian:12` y unos 110 paquetes de Debian | Docker Hub, `deb.debian.org` | unos 180 MB | `ck.sh container` |
| Código fuente de pahole v1.31 con el submódulo libbpf | `git.kernel.org`, GitHub | unos 10 MB | `ck.sh container` |
| `linux-6.18.65.tar.xz` y su firma | `cdn.kernel.org` | 155 MB | `ck.sh fetch` |
| `zfs-2.4.1.tar.gz` y su firma | GitHub Release de OpenZFS | 35 MB | `ck.sh fetch` |
| Paquete de código fuente de los módulos externos `fnos-cust-kernel-6.18.65-3-extmod-src.tar.xz` | GitHub Release de este proyecto | 180 MB | `ck.sh fetch` |
| Opcional: controlador propietario de NVIDIA `NVIDIA-Linux-x86_64-580.142.run` | `download.nvidia.com` | 380 MB | `ck.sh fetch-nvidia` |

El controlador propietario de NVIDIA se distribuye bajo la licencia de software de NVIDIA. Este proyecto ya no distribuye su código fuente; cada usuario lo descarga tras leer la [licencia](../../third_party/nvidia-linux-driver/LICENSE). Sin él, la compilación omite `nvidia-gpu-proprietary`, el paquete solo contiene el controlador abierto de NVIDIA y `alternatives/nvidia-gpu` apunta a la versión abierta; el resto coincide con la versión publicada.

- Pruebas: host con soporte de KVM, con `qemu-system-x86_64`, OVMF y `sshpass`.

## Instalación

### Instalación rápida

En fnOS 1.2.1000, como root:

```bash
V=6.18.65-3
curl -fLO https://github.com/CharlesGool/fnOS-cust-kernel/releases/download/v$V/linux-image-6.18.65.c1186-trim_${V}_amd64.deb
curl -fLO https://github.com/CharlesGool/fnOS-cust-kernel/releases/download/v$V/SHA256SUMS
sha256sum -c --ignore-missing SHA256SUMS
dpkg -i linux-image-6.18.65.c1186-trim_${V}_amd64.deb
reboot
```

Tras el arranque, `uname -r` debe mostrar `6.18.65.c1186-trim`. El kernel original 6.18.18 se conserva en las opciones avanzadas del menú de arranque.

### Instalación normal

Compile desde el código fuente y luego instale con `dpkg -i` como en la instalación rápida. La compilación tarda alrededor de 1 hora (20 hilos):

```bash
git clone https://github.com/CharlesGool/fnOS-cust-kernel.git
cd fnOS-cust-kernel
cp .env.example .env        # rellene al menos CK_DEPS_DIR, véase la guía
scripts/ck.sh container     # crea el contenedor de compilación: debian:12, dependencias, pahole v1.31
scripts/ck.sh fetch         # descarga y verifica el código fuente del kernel, de ZFS y de los módulos externos
scripts/ck.sh bootstrap     # paquete de código fuente + patches/ -> ck/linux y ck/zfs en el directorio de dependencias
scripts/ck.sh build         # kernel, ZFS, módulos externos y empaquetado; la salida queda en ck/out/ del directorio de dependencias
```

Para incluir el controlador propietario de NVIDIA, lea la [licencia de NVIDIA](../../third_party/nvidia-linux-driver/LICENSE) antes de `bootstrap` y, si la acepta, ejecute:

```bash
scripts/ck.sh fetch-nvidia --accept-nvidia-license
```

Solo extrae el directorio `kernel/` del controlador con `--extract-only`, no instala el controlador en el host y comprueba que el contenido extraído coincida con el usado en la versión publicada.

Comparación con la versión publicada (las claves de firma de módulos difieren entre compilaciones, por lo que se eliminan las firmas antes de comparar):

```bash
scripts/cmpdeb.sh linux-image-6.18.65.c1186-trim_6.18.65-3_amd64.deb <directorio de dependencias>/ck/out/linux-image-6.18.65.c1186-trim_6.18.65-3_amd64.deb
```

## Uso

### Configuración

`.env` (cópielo de `.env.example`):

| Parámetro | Significado |
| --- | --- |
| `CK_DEPS_DIR` | Directorio de dependencias: paquetes de código fuente del upstream, código fuente de módulos externos y el área de trabajo `ck/`. Obligatorio |
| `CK_CONTAINER_DIR` | Ruta del directorio de dependencias dentro del contenedor de compilación, por defecto `/k` |
| `CK_BUILD_CONTAINER` | Nombre del contenedor de compilación, por defecto `kwork` |
| `CK_DOCKER` | Comando para invocar docker, por defecto `docker`; si se necesita `sudo` o el contenedor está en otro entorno, puede indicarse un script contenedor |
| `KJOBS` | Número de trabajos de compilación en paralelo, por defecto el número de CPU del contenedor |
| `CK_GNUPGHOME` | Directorio de GnuPG para verificar la firma de kernel.org, por defecto `$CK_DEPS_DIR/gnupg` |
| `CK_KVM_DIR` | Directorio de la máquina de pruebas (disco, variables de OVMF, `qmp.sock`); obligatorio para las pruebas |
| `VM_PASS` | Contraseña de la cuenta `admintest` de la máquina de pruebas; obligatoria para las pruebas |
| `U1_PASS` | Contraseña de la cuenta `u1` de la máquina de pruebas; obligatoria para `smbtest.sh` |

El número de versión está en `config/VERSION`, con el formato `<versión del upstream>-<revisión>`; `config/versions.conf` contiene el sufijo de la cadena de versión, las versiones de ZFS, del controlador propietario de NVIDIA y de pahole, los sha256 de las descargas y la versión del paquete de código fuente de los módulos externos.

### Comandos de compilación

| Comando | Función |
| --- | --- |
| `ck.sh container` | Crea el contenedor de compilación; se detiene si ya existe uno con el mismo nombre |
| `ck.sh fetch [versión]` | Descarga y verifica el paquete de código fuente del kernel; sin versión, también descarga el de ZFS y extrae en `extsrc/` el código fuente de los módulos externos que falte en el directorio de dependencias |
| `ck.sh fetch-nvidia --accept-nvidia-license` | Descarga el controlador propietario de NVIDIA y extrae `extsrc/nvidia-prop-work` |
| `ck.sh kernel` / `zfs` / `pkg` | Compilación por pasos. `kernel` copia la configuración de `config/` al árbol y ejecuta `olddefconfig`; se detiene si hay opciones que cambian |
| `ck.sh extmod [nombre...]` | Compila los módulos externos, por defecto todos; antes de compilar comprueba que el commit del código fuente coincida con `MANIFEST.tsv` (los directorios extraídos del paquete de código fuente lo registran en `.ck-rev`) |
| `ck.sh saveconfig` | Guarda en `config/` el `.config` del árbol |
| `ck.sh export` | Exporta a `patches/` los commits locales del árbol del kernel, del árbol de ZFS y del código fuente de los módulos externos |
| `ck.sh newbase <versión>` | Crea una nueva base upstream en el árbol del kernel y rebasa los parches sobre ella |
| `ck.sh release` | Copia la salida a `releases/<versión>/` y escribe `SHA256SUMS` y `BUILDINFO` |
| `ck.sh srcpkg` | Reúne en `releases/<versión>/` el código fuente para la publicación: paquete de código fuente de los módulos externos (sin el controlador propietario de NVIDIA), paquetes de código fuente del upstream del kernel y de ZFS con sus firmas, y la licencia de NVIDIA |
| `cmpdeb.sh <antiguo> <nuevo>` | Compara dos paquetes del kernel: lista de archivos y contenido tras quitar la firma y el build-id |

Los registros están en `ck/logs/` del directorio de dependencias; los de los módulos externos, en `ck/extbuild/<nombre>.log`.

### Modificar los parches

Haga commit en `ck/linux` (rama `r<versión del upstream>`), `ck/zfs` o `extsrc/<directorio>` del directorio de dependencias, luego ejecute `ck.sh export` y haga commit en este repositorio de los cambios de `patches/`. Los directorios de módulos externos extraídos del paquete de código fuente no son repositorios de Git; antes de modificar uno, ejecute `git init` en él, elimine `.ck-rev` y haga commit del contenido tal cual.

### Pruebas

La máquina de pruebas es una máquina virtual KVM con fnOS 1.2.1000 original, 4 discos de datos, un espacio de almacenamiento Btrfs RAID1 y las cuentas `admintest` y `u1`. `boot.sh` redirige Web, SSH y SMB a las direcciones de bucle local 25666, 25622 y 25445 del host.

```bash
test/kvm/boot.sh
sshpass -p "$VM_PASS" scp -P 25622 <deb> admintest@127.0.0.1:/tmp/k.deb
echo 'dpkg -i /tmp/k.deb && reboot' | test/kvm/vm.sh
test/kvm/vm.sh < test/kvm/probe.sh
```

| Script | Qué prueba |
| --- | --- |
| `probe.sh` | Versión del kernel, servicios con fallos, errores de dmesg, mdstat |
| `ptest.sh`, `ptest2.sh` | Permisos trimacl: administrador, usuario normal, recurso compartido de solo lectura |
| `smbtest.sh` | Lectura, escritura y permisos de SMB; anteponga al script las asignaciones `VM_PASS=...; U1_PASS=...` antes de pasarlo a `vm.sh` |
| `nfstest.sh` | Funcionalidad y permisos de NFS, incluidas las 4 correcciones de seguridad |
| `mdtest.sh`, `acttest.sh` | Degradación de md, DFR, `sync_action` |
| `dfrtest.sh` | Se ejecuta en el host: desconecta en caliente un disco de datos y verifica la recuperación de DFR sin reconstrucción |
| `stortest.sh`, `stortest2.sh` | RAID5, instantáneas de btrfs, qgroup, scrub, balance, ext4 |
| `modtest.sh` | Carga y descarga cada módulo externo y comprueba si hay Oops |

La salida de `vm.sh` no tiene marcas de tiempo, por lo que se puede comparar directamente con `diff` con la salida de la versión anterior. La funcionalidad real de los controladores de red, el bonding, la red inalámbrica y NVIDIA solo se puede probar en hardware real.

### Publicar una versión nueva

Número de versión: al cambiar parches, configuración o módulos sobre la misma versión del upstream, la revisión aumenta en 1; al cambiar de versión del upstream, la revisión vuelve a empezar en 1. Las versiones ya publicadas no se sobrescriben.

Solo se añaden parches (por ejemplo, una corrección de seguridad):

1. Haga commit de la corrección en `ck/linux` y ejecute `ck.sh export`.
2. Modifique `config/VERSION` y ejecute `ck.sh build`.
3. Ejecute las pruebas en la máquina de pruebas y compare con la salida de la versión anterior.
4. Ejecute `ck.sh release` y `ck.sh srcpkg`; si cambiaron los módulos externos, actualice `EXTSRC_VER` y `EXTSRC_SHA256` en `config/versions.conf` según indique `srcpkg`. Actualice [CHANGELOG](CHANGELOG.md), cree la etiqueta `v<versión>` y publique, subiendo todos los archivos de `releases/<versión>/`.

Seguir el upstream 6.18.y:

```bash
scripts/ck.sh fetch 6.18.66
scripts/ck.sh newbase 6.18.66      # si hay conflictos, resuélvalos en ck/linux y ejecute git rebase --continue
echo 6.18.66-1 > config/VERSION
scripts/ck.sh export
scripts/ck.sh build                # si cambia la configuración, ejecute saveconfig según se indique
scripts/cmpdeb.sh <deb de la versión anterior> <deb nuevo>
```

Después, ejecute los pasos 3 y 4 anteriores. btrfs es un port completo de la 7.0.9: las correcciones de btrfs de 6.18.y no surten efecto automáticamente y deben portarse a mano desde 7.0.x y la rama principal. ZFS sigue a OpenZFS 2.4.x; al cambiar de versión, modifique `config/versions.conf` y vuelva a aplicar `patches/zfs` sobre el nuevo paquete de código fuente. Los avisos de CVE de 6.18.y están en [linux-cve-announce](https://lore.kernel.org/linux-cve-announce/).

## Actualización

- Nueva revisión de la misma versión del upstream (por ejemplo, de `6.18.65-3` a `6.18.65-4`): tras `dpkg -i` del paquete nuevo y reiniciar, el paquete se actualiza en su sitio.
- Nueva versión del upstream (por ejemplo, de `6.18.65-3` a `6.18.66-1`): el nombre del paquete es distinto, por lo que tras `dpkg -i` el paquete nuevo coexiste con el kernel antiguo y el kernel nuevo arranca por defecto. Tras reiniciar, confirme `uname -r` y luego elimine el kernel antiguo con `dpkg -r linux-image-6.18.65.c1186-trim`.
- Solo se sustituyen el kernel y los módulos; los espacios de almacenamiento, la configuración y los datos no se ven afectados. Tras actualizar, compruebe con `probe.sh`.

## Desinstalación

Desinstalación rápida (restaura el kernel original y conserva los datos y la configuración): en las opciones avanzadas del menú de arranque, arranque con el kernel original `6.18.18.c1186-trim` y luego ejecute:

```bash
dpkg -r linux-image-6.18.65.c1186-trim
```

Desinstalación completa (además elimina los directorios de módulos y los registros de configuración residuales):

```bash
dpkg --purge linux-image-6.18.65.c1186-trim
update-grub
```

## Agradecimientos

- [Linux](https://www.kernel.org/), [OpenZFS](https://github.com/openzfs/zfs) y el upstream de cada controlador externo; la lista completa está en [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md).
- Algunos cambios de fnOS se portaron desde la rama principal del upstream y desde [ImmortalWrt](https://github.com/immortalwrt/immortalwrt); la descripción de los parches indica el origen.

## Licencia

Este repositorio se licencia bajo la GNU General Public License v2.0 only, identificador SPDX `GPL-2.0-only`; el texto completo está en [LICENSE](../../LICENSE). `patches/zfs/` se rige por la CDDL-1.0 de OpenZFS, los parches de cada controlador bajo `patches/extmod/` se rigen por la licencia del upstream de ese controlador, y los componentes de terceros del paquete publicado están en [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md).
