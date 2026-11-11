# HermesEnabler · Pesquisa de compatibilidade com watchOS 26.x

**Status: BLOCKED — A abordagem atual está bloqueada. Nenhum mostrador Hermès nativo foi desbloqueado.**

Este repositório documenta meus testes com um **Apple Watch Ultra de primeira geração (Watch6,18 / n199ap)** no **watchOS 26.6.1 (23U95)**, incluindo análises das permissões do sistema e das verificações de elegibilidade dos mostradores.

Foi possível ler o cache protegido do MobileGestalt, mas a abertura para escrita retornou `EPERM`. ClockKit/NanoTimeKit também impõe restrições independentes. **Não é uma ferramenta de desbloqueio funcional e não há IPA com desbloqueio comprovado.**

O prefixo `RO23` em arquivos antigos é apenas um identificador interno histórico, não o nome do projeto nem uma versão compatível.

[Pesquisa e histórico completos (chinês)](README.zh-CN.md) · [English summary](README.md#english-summary) · [Projeto original](https://github.com/pookjw/HermesEnabler) · [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) · [LICENSE](LICENSE)

**Pesquisa independente, sem vínculo oficial com Apple ou Hermès.**
