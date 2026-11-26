---
name: project-log-es
description: Errores, limitaciones, decisiones y traspaso del proyecto
metadata:
  version: "1.0.0"
  lang: "es"
---

# Registro

## Multilingüe

[简体中文](../LOG.md) | [English](../en/LOG.md) | **Español**

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Estado del proyecto: [LOG](LOG.md)
- Registros históricos: [HISTORY](HISTORY.md)
- Historial de cambios: [CHANGELOG](CHANGELOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Registros

- [Registros históricos](HISTORY.md)
- [Historial de cambios](CHANGELOG.md)

## Errores

- [ ] Falta `houmo-drv-xh2` (`xh2a_drv.ko`): está en el paquete de fnOS, pero no hay código fuente.
- [ ] `rtl8733bu` usa una versión aproximada, la 5.15.12-123; no se encontró el código fuente de la -264 que usa fnOS.
- [ ] El controlador del fabricante `r8169` es una versión provisional 6.022.00.
- [ ] Los módulos NVIDIA de código abierto no incluyen los cambios de fnOS para la CMP 40HX.
- [ ] No se han restaurado 4 grupos de cambios presuntamente privados en i915 y xe (no afectan al almacenamiento ni a los permisos).
- [ ] El grado de restauración de md es bajo: `md_do_sync` tiene 18 instrucciones menos, `mddev_create_serial_pool` carece de una comprobación y las funciones grandes de raid10 no se han comparado tramo a tramo.
- [ ] Los módulos externos solo se probaron cargándolos y descargándolos, no en el hardware correspondiente.

## Limitaciones

- La funcionalidad real de los controladores de red, el bonding, la red inalámbrica y NVIDIA no se puede probar en la máquina de pruebas KVM; hace falta hardware real.
- RAID5, la conversión en línea a llbitmap, las instantáneas y qgroup de btrfs y el espejo de ZFS solo se probaron por línea de comandos, sin crearlos ni gestionarlos desde la interfaz web de fnOS.

## Decisiones

| Fecha | Decisión | Estado | Motivo |
| --- | --- | --- | --- |
| 2026-11-24 | Permanecer en fnOS 1.2.1000, mantener el kernel por cuenta propia y portarlo a 6.18 LTS | Aceptada | fnOS no publica el código fuente del kernel y el kernel original no puede recibir correcciones del upstream. |
| 2026-11-24 | No seguir las versiones nuevas oficiales de fnOS | Aceptada | Las versiones nuevas tampoco incluyen el código fuente, por lo que no se pueden revisar ni parchear. |
| 2026-11-26 | Mantener un solo kernel; el árbol restaurado de 6.18.18 solo sirve como referencia de comparación | Aceptada | Mantener dos en paralelo duplicaría el trabajo de correcciones de seguridad y de pruebas. |
| 2026-11-26 | Excepción del proyecto: se exime de la regla 2 de `版本标识` del flujo de publicación del Skill all-in-one (las versiones oficiales solo usan `vMAJOR.MINOR.PATCH`). Alcance: las etiquetas y Releases de este proyecto. Restricción: la etiqueta debe ser `v<versión del upstream>-<revisión>`, coherente con la versión del paquete | Aceptada | La versión del paquete se compone de la versión del kernel del upstream y el número de revisión, y ya está incrustada en el deb y en uso. |
| 2026-11-26 | El repositorio se licencia bajo GPL-2.0-only | Aceptada | Los parches del kernel son obras derivadas de Linux. |
| 2026-11-26 | Cada Release ofrece el deb y el código fuente completo (paquetes fuente del upstream y de los módulos externos) | Aceptada | Distribuir binarios obliga a cumplir la obligación de la GPL de ofrecer el código fuente. |
| 2026-11-26 | No se publican las herramientas de la fase de ingeniería inversa, los registros de comparación ni los binarios de fnOS | Aceptada | La compilación no los necesita y contienen binarios y desensamblados de fnOS. |

## Traspaso

Consulte el traspaso vigente en el [LOG.md en chino simplificado](../LOG.md#交接).
