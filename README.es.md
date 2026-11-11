# HermesEnabler · Investigación de compatibilidad con watchOS 26.x

**Estado: BLOCKED — La vía técnica actual está bloqueada. No se han habilitado esferas Hermès nativas.**

Este repositorio documenta mis pruebas en un **Apple Watch Ultra de primera generación (Watch6,18 / n199ap)** con **watchOS 26.6.1 (23U95)**, incluidos los análisis de permisos del sistema y de elegibilidad de las esferas.

Pude leer la caché protegida de MobileGestalt, pero la apertura para escritura devolvió `EPERM`. ClockKit/NanoTimeKit también aplica restricciones independientes. **No es una herramienta de desbloqueo funcional y no ofrece una IPA con desbloqueo verificado.**

`RO23`, presente en nombres de archivos antiguos, es un identificador interno histórico, no el nombre del producto ni una versión compatible.

[Investigación e historial completos (chino)](README.zh-CN.md) · [English summary](README.md#english-summary) · [Proyecto original](https://github.com/pookjw/HermesEnabler) · [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) · [LICENSE](LICENSE)

**Investigación independiente sin afiliación oficial con Apple ni Hermès.**
