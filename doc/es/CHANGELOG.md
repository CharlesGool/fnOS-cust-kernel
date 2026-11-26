---
name: project-changelog-es
description: Historial de cambios
metadata:
  version: "1.0.0"
  lang: "es"
---

# Historial de cambios

## Multilingüe

[简体中文](../CHANGELOG.md) | [English](../en/CHANGELOG.md) | **Español**

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Estado del proyecto: [LOG](LOG.md)
- Registros históricos: [HISTORY](HISTORY.md)
- Historial de cambios: [CHANGELOG](CHANGELOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Historial de cambios

### v6.18.65-3 (2026-11-26)

Primera versión pública. Paquete del kernel `linux-image-6.18.65.c1186-trim_6.18.65-3_amd64.deb`, sha256 `8137206846024a173b28bd40c99bbfed345c3ae402915918bc99b1b4f94c3af9`.

#### Añadido

- Linux oficial 6.18.65 más 110 parches que restauran las funciones privadas del kernel de fnOS 1.2.1000: permisos trimacl, llamadas al sistema trim, papelera de reciclaje, trimafs2, notificación de eventos, md DFR y llbitmap, recvfile, velocidad mixta en bonding, cambios en controladores de red y libata; btrfs es un port de la versión 7.0.9 del upstream.
- OpenZFS 2.4.1 más 8 parches (trimacl, recvfile).
- Módulos externos con la misma disposición que fnOS: controladores de red del fabricante Realtek r8101, r8125, r8126, r8127, r8152, r8168, r8169, it87, nft_fullcone, mft, NVIDIA de código abierto 610.57.04 y propietario 580.142, rtw88, rtw89, aic8800, rtl8852bs, rtl8733bu, amdxdna, seekwave, drm-cx4.
- Scripts para compilar, empaquetar, comparar y probar a partir de los paquetes de código fuente del upstream y los parches.

#### Corregido

- NFS: en volúmenes trimacl, `nfsd_permission` también comprueba los permisos de escritura y ejecución; la versión original de fnOS solo comprobaba lectura.
- NFS: `fh_getattr` informa 0777 solo para archivos trimacl; en los sistemas de archivos normales informa los permisos reales.
- trimafs2: un identificador de nivel inferior falsificado que no sea un directorio ya no puede abrir archivos fuera del directorio puente.
- trimafs2: solo el directorio `nfs` interno de segundo nivel del nivel superior cuenta como ruta de recurso compartido NFS; un directorio del mismo nombre creado por el usuario no cuenta.
- La versión USB de aic8800 exportaba símbolos con los mismos nombres que la versión SDIO, lo que hacía fallar la carga de `aic8800DC_fdrv`.
- Descargar `skw_usb_lite` de seekwave sin hardware presente provocaba un oops.

Verificación: en la máquina de pruebas KVM (fnOS 1.2.1000 original), el arranque, los espacios de almacenamiento, los permisos, SMB, NFS, la papelera de reciclaje, la degradación de md y DFR coinciden con los del kernel original; 90 módulos externos se cargaron y descargaron sin Oops. Los controladores de red, el bonding, la red inalámbrica y NVIDIA no se probaron en hardware real.
