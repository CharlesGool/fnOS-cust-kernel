---
name: project-third-party-notices-es
description: Atribuciones y avisos de cumplimiento de terceros
metadata:
  version: "1.0.0"
  lang: "es"
---

# Avisos de terceros

## Multilingüe

[简体中文](../THIRD_PARTY_NOTICES.md) | [English](../en/THIRD_PARTY_NOTICES.md) | **Español**

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Estado del proyecto: [LOG](LOG.md)
- Registros históricos: [HISTORY](HISTORY.md)
- Historial de cambios: [CHANGELOG](CHANGELOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Avisos de terceros

### Componentes

Este repositorio contiene parches para los componentes siguientes; el paquete del kernel de la Release de GitHub contiene los binarios compilados a partir de ellos. Los hashes de commit de los módulos externos están en [`MANIFEST.tsv`](../../patches/extmod/MANIFEST.tsv).

| Componente | Versión o hash | URL de origen | Licencia | Uso | Titular de los derechos | Obligaciones de distribución | Verificado el |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Linux | 6.18.65 | https://www.kernel.org/ | GPL-2.0 WITH Linux-syscall-note | Se compila con parches como vmlinuz y módulos del árbol | Colaboradores del kernel Linux | Incluir la licencia, ofrecer el código fuente completo | 2026-11-26 |
| OpenZFS | 2.4.1 | https://github.com/openzfs/zfs | CDDL-1.0 | Se compila con parches como spl.ko, zfs.ko | Colaboradores de OpenZFS, Oracle y otros | Incluir la licencia, ofrecer el código fuente | 2026-11-26 |
| r8101 | 1.039.00 | https://github.com/openwrt/rtl8101 | GPL-2.0 | Se compila con parches como módulo externo, incluye parches de ImmortalWrt | Realtek Semiconductor Corp. | Incluir la licencia, ofrecer el código fuente completo | 2026-11-26 |
| r8125 | 9.018.00 | https://github.com/openwrt/rtl8125 | GPL-2.0 | Ídem, incluye parches de ImmortalWrt | Realtek Semiconductor Corp. | Ídem | 2026-11-26 |
| r8126 | 10.016.00 | https://github.com/openwrt/rtl8126 | GPL-2.0 | Ídem, incluye parches de ImmortalWrt | Realtek Semiconductor Corp. | Ídem | 2026-11-26 |
| r8127 | 11.015.00 | https://github.com/openwrt/rtl8127 | GPL-2.0 | Ídem, incluye parches de ImmortalWrt | Realtek Semiconductor Corp. | Ídem | 2026-11-26 |
| r8168 | 8.056.02 | https://github.com/openwrt/rtl8168 | GPL-2.0 | Ídem, incluye parches de ImmortalWrt | Realtek Semiconductor Corp. | Ídem | 2026-11-26 |
| r8169 | 6.022.00 | https://github.com/smooker/realtek | GPL-2.0 | Se compila con parches como módulo externo | Realtek Semiconductor Corp. | Ídem | 2026-11-26 |
| r8152 | 2.22.1 | https://github.com/wget/realtek-r8152-linux | GPL-2.0 | Se compila con parches como módulo externo | Realtek Semiconductor Corp. | Ídem | 2026-11-26 |
| it87 | 48b87a397de8 | https://github.com/frankcrawford/it87 | GPL-2.0 | Se compila como módulo externo | Colaboradores de it87 | Ídem | 2026-11-26 |
| nft-fullcone | 07d93b626ce5 | https://github.com/fullcone-nat-nftables/nft-fullcone | GPL-2.0 | Se compila con parches como módulo externo | Colaboradores de nft-fullcone | Ídem | 2026-11-26 |
| NVIDIA MFT kernel-mft-dkms | 4.35.0-159 | https://content.mellanox.com/MFT/mft-4.35.0-159-x86_64-deb.tgz | GPL-2.0 o BSD (doble licencia) | Se compila como módulos externos mst_pci, mst_pciconf | NVIDIA Corporation | Ídem | 2026-11-26 |
| NVIDIA open-gpu-kernel-modules | 610.57.04 | https://github.com/NVIDIA/open-gpu-kernel-modules | MIT o GPL-2.0 (doble licencia) | Se compila como módulo externo | NVIDIA Corporation | Incluir la licencia, ofrecer el código fuente | 2026-11-26 |
| Módulos de kernel del controlador NVIDIA para Linux | 580.142 | https://download.nvidia.com/XFree86/Linux-x86_64/580.142/NVIDIA-Linux-x86_64-580.142.run | Acuerdo de licencia de software de NVIDIA (propietario) | La capa de interfaz del kernel se compila y se enlaza con los objetos binarios proporcionados por NVIDIA para formar un módulo externo | NVIDIA Corporation | Los binarios no deben modificarse y el acuerdo de licencia debe entregarse a cada receptor; véase la revisión de cumplimiento | 2026-11-26 |
| rtw88 | a56bcd26e770 | https://github.com/lwfinger/rtw88 | GPL-2.0 o BSD-3-Clause (doble licencia) | Se compila como módulo externo | Realtek, colaboradores de rtw88 | Incluir la licencia, ofrecer el código fuente completo | 2026-11-26 |
| rtw89 | 8b2b78deb357 | https://github.com/morrownr/rtw89 | GPL-2.0 o BSD-3-Clause (doble licencia) | Se compila como módulo externo | Realtek, colaboradores de rtw89 | Ídem | 2026-11-26 |
| aic8800 | d5e11d4b9166 | https://github.com/radxa-pkg/aic8800 | GPL (el repositorio incluye el texto de GPL-3.0, el módulo se declara GPL) | Se compila con parches como módulo externo | AICSemi, RivieraWaves | Ídem | 2026-11-26 |
| rtl8852bs | c895ffa95355 | https://github.com/armbian/wifi-rtl8852bs | GPL-2.0 | Se compila con parches como módulo externo | Realtek Semiconductor Corp. | Ídem | 2026-11-26 |
| rtl8733bu | 9f19065a24dd | https://github.com/briansune/rtl8733bu-vendor-5.15.12-123 | GPL-2.0 | Se compila como módulo externo | Realtek Semiconductor Corp. | Ídem | 2026-11-26 |
| amdxdna | 88dda53eee33 | https://github.com/amd/xdna-driver | GPL-2.0 | Se compila con parches como módulo externo | Advanced Micro Devices, Inc. | Ídem | 2026-11-26 |
| seekwave swt6621s | d78c90e61ffc | https://github.com/retro98boy/swt6621s-archived | GPL-2.0 | Se compila con parches como módulo externo | SeekWave Technology, retro98boy | Ídem | 2026-11-26 |
| drm-cx4 | 26.00.45 | https://github.com/AOSC-Tracking/cx4-kernel-dkms | GPL-2.0 | Se compila con parches como módulo externo | Shanghai Zhaoxin Semiconductor Co., Ltd. | Ídem | 2026-11-26 |

### Textos de licencia

| Licencia | Texto original |
| --- | --- |
| GPL-2.0 | [LICENSE](../../LICENSE) |
| Aviso de licencia del kernel Linux, GPL-2.0, Linux-syscall-note | [third_party/linux/](../../third_party/linux/COPYING) |
| CDDL-1.0 | [third_party/openzfs/LICENSE](../../third_party/openzfs/LICENSE), [NOTICE](../../third_party/openzfs/NOTICE) |
| GPL-3.0 incluida con aic8800 | [third_party/aic8800/LICENSE](../../third_party/aic8800/LICENSE) |
| NVIDIA open-gpu-kernel-modules (MIT) | [third_party/nvidia-open-gpu-kernel-modules/COPYING](../../third_party/nvidia-open-gpu-kernel-modules/COPYING) |
| Acuerdo de licencia de software de NVIDIA | [third_party/nvidia-linux-driver/LICENSE](../../third_party/nvidia-linux-driver/LICENSE), también disponible como recurso de la Release `NVIDIA-LICENSE.txt` |

Los componentes con doble licencia BSD se usan bajo GPL-2.0. Los demás archivos de licencia del código fuente de cada componente se entregan con los paquetes de código fuente.

### Oferta de código fuente

Cada Release de GitHub incluye el código fuente completo correspondiente al paquete del kernel:

- Kernel: `linux-<versión del upstream>.tar.xz` y su firma `.tar.sign`, más `patches/kernel/` y `config/` de la misma etiqueta de este repositorio.
- ZFS: `zfs-<versión>.tar.gz` y su firma `.asc`, más `patches/zfs/`.
- Módulos externos: `fnos-cust-kernel-<versión>-extmod-src.tar.xz`, que contiene los árboles de código fuente completos de los commits listados en `MANIFEST.tsv` (ya incluye los cambios de `patches/extmod/`).
- Scripts de compilación: `scripts/` de este repositorio.

### Revisión de cumplimiento

- Componentes GPL: el kernel y los módulos externos GPL se distribuyen en binario con el paquete; el código fuente correspondiente se ofrece según la sección anterior.
- OpenZFS (CDDL-1.0) se distribuye como módulos independientes spl.ko y zfs.ko, en el mismo paquete que el kernel GPL. Es discutible que CDDL y GPL puedan combinarse y distribuirse de esta manera; este proyecto no ha obtenido asesoramiento jurídico.
- Módulos propietarios de NVIDIA: el apartado 1.1 d) del acuerdo de licencia permite distribuirlos con un kernel de código abierto, siempre que los archivos binarios no se hayan modificado y se entregue el acuerdo a cada receptor. `nvidia.ko` y los demás módulos del paquete se forman enlazando la capa de interfaz del kernel con los objetos binarios de NVIDIA y se procesan con `strip --strip-debug`; este proyecto no puede determinar si siguen considerándose "no modificados". El acuerdo de licencia se ofrece mediante el recurso de la Release `NVIDIA-LICENSE.txt` y este repositorio, pero no dentro del paquete deb. Quien tenga dudas debe buscar asesoramiento profesional.
- El registro de la decisión está en [Decisiones de LOG](LOG.md#decisiones).
