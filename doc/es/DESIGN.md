---
name: project-design-es
description: Arquitectura y restricciones de diseño del proyecto
metadata:
  version: "1.0.0"
  lang: "es"
---

# fnOS-cust-kernel — Diseño

## Multilingüe

[简体中文](../DESIGN.md) | [English](../en/DESIGN.md) | **Español**

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Estado del proyecto: [LOG](LOG.md)
- Registros históricos: [HISTORY](HISTORY.md)
- Historial de cambios: [CHANGELOG](CHANGELOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Objetivos de diseño

- [x] Sustituir el kernel original de fnOS 1.2.1000 por el 6.18 LTS oficial más parches, sin cambiar el comportamiento de las funciones de almacenamiento, permisos, papelera de reciclaje y recursos compartidos de fnOS.
- [x] Restaurar por ingeniería inversa los cambios privados de fnOS como código fuente en C, recompilarlos sobre el 6.18.18 oficial con la misma cadena de herramientas y portarlos solo después de confirmar, mediante comparación binaria función por función, que coinciden.
- [x] Reconstruir un paquete equivalente a partir de los paquetes de código fuente del upstream y `patches/`.
- [x] Mantener un solo kernel. El árbol restaurado de 6.18.18 solo sirve como referencia de comparación y no genera paquete.
- [ ] Restaurar 4 grupos de cambios presuntamente privados en i915 y xe.
- [ ] Completar el módulo externo `houmo-drv-xh2`, que fnOS tiene y este proyecto no (no hay código fuente).
- [ ] Verificar en hardware real los controladores de red, el bonding, la red inalámbrica y NVIDIA.
- No es objetivo: seguir las versiones nuevas ni los kernels nuevos oficiales de fnOS.

## Arquitectura

Flujo de compilación:

```text
linux-<upstream>.tar.xz + patches/kernel ─> árbol del kernel ─> bzImage, módulos del árbol ─┐
zfs-<versión>.tar.gz + patches/zfs ─────> árbol de ZFS ─> spl.ko, zfs.ko ───────────────────┼─> pkg ─> linux-image-<cadena de versión>_<versión>_amd64.deb
extsrc/<directorio> (= HEAD de MANIFEST.tsv) ──────> módulos externos ────────────────────┘
```

- `scripts/ck.sh` se ejecuta en el host: descarga y verifica los paquetes de código fuente del upstream, sincroniza el repositorio con el área de trabajo y luego ejecuta los pasos de `scripts/kwork/` en el contenedor de compilación.
- El área de trabajo está en `ck/` dentro del directorio de dependencias, no en el repositorio: `linux/`, `zfs/` (árboles de Git), `zfs-build/`, `extbuild/`, `extmod/`, `pkg/`, `out/`, `logs/`.

Directorios de primer nivel:

| Directorio | Función |
| --- | --- |
| `config/` | Configuración del kernel `config-<cadena de versión>`, número de versión `VERSION`, sufijo de la cadena de versión y versión de ZFS en `versions.conf` |
| `patches/` | Única fuente del código: `kernel/` (con `series`), `zfs/`, `extmod/<directorio>/` y `MANIFEST.tsv`, que registra la base upstream y el HEAD de cada módulo externo |
| `scripts/` | Punto de entrada en el host `ck.sh`, comparación de paquetes `cmpdeb.sh` y `kocmp.py`, pasos dentro del contenedor en `kwork/` |
| `test/` | Scripts de pruebas de regresión en KVM, en `kvm/` |
| `third_party/` | Textos originales de las licencias de los componentes de terceros del paquete publicado, un subdirectorio por origen |
| `doc/` | Documentación del proyecto |
| `releases/` | Salida de la compilación, ignorada por Git: paquetes de cada versión, paquetes de código fuente, `SHA256SUMS`, `BUILDINFO` |

Los parches del kernel (`patches/kernel/`) se dividen por origen:

| Parte | Contenido |
| --- | --- |
| event_report, libata | Notificación de eventos por netlink para sysdiag; energía ACPI de ATA y `manage_restart` (portado de 6.19) |
| trimacl | Campos nuevos en `inode`, 12 callbacks de `inode_operations`, 11 llamadas al sistema trim, papelera de reciclaje, adaptación de ext4/btrfs/fuse/nfsd |
| trimafs2 | Sistema de archivos puente de fnOS, escrito desde cero |
| md | DFR (recuperación sin reconstrucción tras degradación), resync hint, llbitmap |
| btrfs | Port completo de la versión 7.0.9 del upstream, más la corrección de 7.0.10 y los cambios privados de fnOS |
| Otros | Llamada al sistema recvfile, velocidad mixta en bonding, controladores de red r8169/motorcomm, cambios menores en x86, ACPI, PCI y DRM fbdev |
| Correcciones de seguridad | 4 correcciones de NFS añadidas por este proyecto |

## Restricciones de diseño

1. El sufijo de la cadena de versión del kernel queda fijado en `.c1186-trim` (`config/versions.conf`); el espacio de usuario de fnOS busca con él el directorio de módulos.
2. Las versiones del compilador y de pahole coinciden con las originales de fnOS: `gcc (Debian 12.2.0-14+deb12u1) 12.2.0`, pahole v1.31. Cambiar de versión haría perder la referencia de la comparación función por función.
3. La disposición dentro del paquete coincide con la de fnOS:
   - los módulos externos no se comprimen y se procesan con `strip --strip-debug`;
   - `updates/trim/<nombre>/*.ko` va en `/lib/modules/<cadena de versión>/` y `modules_trim/<nombre>/*.ko` en `/usr/lib/modules_trim/<cadena de versión>/`;
   - `updates/trim/alternatives` es un enlace absoluto a `/usr/lib/modules_trim/<cadena de versión>/alternatives`, y `alternatives/nvidia-gpu` apunta por defecto a la versión propietaria;
   - los módulos del árbol se comprimen con xz y se firman.
4. Los módulos externos se compilan bajo la ruta de compilación de fnOS `/var/jenkins_home/workspace/kernel-build/...`, para que las cadenas `__FILE__` coincidan con las de fnOS.
5. Cada compilación desde cero genera automáticamente una clave de firma de módulos aleatoria (`CONFIG_MODULE_SIG_ALL=y`, sin `MODULE_SIG_FORCE`). Las firmas de los módulos difieren entre compilaciones; no se deben mezclar.
6. btrfs sigue al upstream 7.0.x y a la rama principal, no al 6.18.y.
7. Al modificar trimacl, nfsd o trimafs2, no se deben debilitar las comprobaciones de las 4 correcciones de seguridad de NFS: `nfsd_permission` comprueba escritura y ejecución en trimacl, `fh_getattr` informa 0777 solo para trimacl, los identificadores de trimafs2 deben estar dentro de la raíz del puente, y solo el directorio `nfs` interno de segundo nivel cuenta como ruta NFS.
8. No se debe descomprimir ni compilar en un volumen de almacenamiento de fnOS: trimacl cambia los permisos de los archivos extraídos.
