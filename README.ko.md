# HermesEnabler · watchOS 26.x 호환성 연구

**상태: BLOCKED — 현재 방식으로는 제한을 해제할 수 없으며, 순정 Hermès 워치 페이스는 활성화되지 않았습니다.**

이 저장소에는 제가 **1세대 Apple Watch Ultra(Watch6,18 / n199ap)** 및 **watchOS 26.6.1(23U95)** 환경에서 수행한 실제 기기 테스트, 시스템 접근 권한 분석, 순정 Hermès 워치 페이스 호환성 연구가 기록되어 있습니다.

보호된 MobileGestalt 캐시는 읽을 수 있었지만 쓰기 모드로 열면 `EPERM` 오류가 발생했습니다. ClockKit/NanoTimeKit의 별도 적격성 검사도 통과하지 못했습니다. **현재 검증된 잠금 해제 도구나 정상 작동하는 IPA는 없습니다.**

이전 연구 파일의 `RO23`은 내부 식별자일 뿐 제품명이나 지원 OS 버전이 아닙니다.

[전체 연구 및 버전 기록(중국어)](README.zh-CN.md) · [English summary](README.md#english-summary) · [원본 프로젝트](https://github.com/pookjw/HermesEnabler) · [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) · [LICENSE](LICENSE)

**Apple 또는 Hermès의 공식 프로젝트가 아닌 독립 연구입니다.**
