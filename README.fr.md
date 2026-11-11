# HermesEnabler · Étude de compatibilité watchOS 26.x

**Statut : BLOCKED — La méthode actuelle est bloquée. Aucun cadran Hermès natif n'a été déverrouillé.**

Ce dépôt documente mes essais sur une **Apple Watch Ultra de première génération (Watch6,18 / n199ap)** sous **watchOS 26.6.1 (23U95)** ainsi que l'analyse des autorisations système et des restrictions des cadrans natifs.

La lecture du cache MobileGestalt protégé a fonctionné, mais son ouverture en écriture a renvoyé `EPERM`. ClockKit/NanoTimeKit impose également des vérifications indépendantes. **Ce dépôt n'est pas un outil de déverrouillage opérationnel et ne propose aucune IPA dont le déverrouillage a été vérifié.**

Le préfixe `RO23` de certains anciens fichiers est un identifiant historique interne, pas un nom de produit ni une version compatible.

[Recherche complète et historique (chinois)](README.zh-CN.md) · [English summary](README.md#english-summary) · [Projet d'origine](https://github.com/pookjw/HermesEnabler) · [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) · [LICENSE](LICENSE)

**Recherche indépendante, non affiliée à Apple ou Hermès.**
