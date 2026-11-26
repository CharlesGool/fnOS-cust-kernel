---
name: project-history-es
description: Registros históricos
metadata:
  version: "1.0.0"
  lang: "es"
---

# Registros históricos

## Multilingüe

[简体中文](../HISTORY.md) | [English](../en/HISTORY.md) | **Español**

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Estado del proyecto: [LOG](LOG.md)
- Registros históricos: [HISTORY](HISTORY.md)
- Historial de cambios: [CHANGELOG](CHANGELOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Registros históricos

### 2026-11-24: restauración por ingeniería inversa de los parches privados de fnOS

Sobre el 6.18.18 oficial se restauraron en 12 pasos los cambios privados del `6.18.18.c1186-trim` de fnOS, se recompilaron con la misma cadena de herramientas y se compararon los binarios función por función:

| Paso | Parte | Resultado |
| --- | --- | --- |
| 1 | event_report | 13 idénticas, 2 difieren solo en la asignación de registros, 2 difieren en 1 instrucción cada una |
| 2 | Notificación de eventos de libata, `ATA_FORCE_MANAGE_RESTART` | Idéntico; 1 función difiere solo en la asignación de registros |
| 3 | Cambios menores en vmlinux (unas 60 funciones) | Idéntico, salvo la lista blanca de ACPI (comportamiento idéntico, disposición distinta) |
| 4 | Controladores de red | r8169: 201 idénticas, 3 difieren solo en registros, 4 solo en la disposición de ramas; PHY y mdio idénticos |
| 5 | md | De 461 funciones, 384 idénticas, 19 difieren solo en registros, 56 no coinciden; grado de restauración bajo |
| 6 | Núcleo de trimacl | Idéntico o difiere solo en la disposición del compilador |
| 7 | Adaptación de trimacl a los sistemas de archivos | Cambios privados de ext4, fuse y nfsd idénticos; btrfs es un port completo de la versión 7.0.9 del upstream |
| 8 | Llamada al sistema recvfile | Tabla de llamadas al sistema idéntica |
| 9 | trimafs2 | Escrito desde cero; de 115 funciones, 51 idénticas, 13 difieren solo en registros, el resto son diferencias de generación de código |
| 10 | bonding, GPU | bonding restaurado; en amdgpu todo son backports del upstream; i915 y xe sin restaurar |
| 11 | ZFS | OpenZFS 2.4.1 + 7 parches privados + 1 corrección del upstream; de 6750 elementos de zfs.ko solo quedan 2 diferencias de generación de código |
| 12 | Port a 6.18.65 y arranque en la máquina de pruebas KVM | Arranque, montaje de espacios de almacenamiento, permisos y recursos compartidos de solo lectura, SMB, papelera de reciclaje, recuperación de md degradado, desconexión en caliente con DFR, `sync_action` y dos reinicios coinciden con el kernel original; las pruebas revelaron una omisión en la restauración de `action_store` de md, ya corregida |

Durante la restauración se descubrió que los identificadores NFS de trimafs2 podían salir del directorio puente.

### 2026-11-24: 6.18.65-1 (versión interna)

110 parches, entre ellos 4 correcciones de seguridad de NFS. En la máquina de pruebas KVM se comparó NFS antes y después de las correcciones con el mismo script: tras corregir los 4 problemas, la funcionalidad normal no cambia.

### 2026-11-25: 6.18.65-2 (versión interna)

Los módulos externos se incluyeron en el paquete del kernel con la misma disposición que fnOS. En la máquina de pruebas KVM se cargaron y descargaron uno por uno; se detectó que el módulo USB de aic8800 tenía una dependencia incorrecta y que seekwave provocaba un oops al descargarse sin hardware.

### 2026-11-25: 6.18.65-3

Corrección de los dos problemas de módulos externos citados. Se probaron por línea de comandos RAID5, conversión en línea a llbitmap, instantáneas de btrfs, qgroup, scrub, balance y espejo de ZFS; la verificación de datos fue correcta.

### 2026-11-26: separación como proyecto independiente y verificación de la reconstrucción

El mantenimiento del kernel se separó de la compilación del sistema y pasó a ser este proyecto. Se reconstruyó 6.18.65-3 con los paquetes de código fuente oficiales más `patches/`:

- Los hashes de árbol de Git del árbol del kernel y del árbol de ZFS coinciden con los del árbol de trabajo original.
- La lista de archivos del paquete es idéntica (3881). De 3863 módulos, tras quitar la firma y poner a cero el build-id, 3855 son idénticos byte a byte; los otros 8: i915 y hamachi difieren solo en el orden de `.BTF`; rtl8733bu, rtl8852bs y 2 módulos de NVIDIA de código abierto difieren solo en `__DATE__`/`__TIME__`; spl y zfs difieren solo en la ruta de compilación dentro de `__FILE__`.
- vmlinuz difiere solo en la cadena de hora de compilación y en el certificado de firma incorporado.

El repositorio publicado por primera vez ese mismo día contenía rutas de la máquina local; se eliminó y se volvió a publicar con la estructura actual.
