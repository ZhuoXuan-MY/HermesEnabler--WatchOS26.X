# HermesEnabler · watchOS 26.x 互換性調査

**状況：BLOCKED — 現在の手法では制限を解除できず、純正 Hermès 文字盤は有効化されていません。**

このリポジトリには、私が **初代 Apple Watch Ultra（Watch6,18 / n199ap）** と **watchOS 26.6.1（23U95）** で行った実機検証、システム権限の調査、純正 Hermès 文字盤の互換性分析を記録しています。

保護された MobileGestalt キャッシュの読み取りには成功しましたが、書き込み用に開くと `EPERM` が返されました。ClockKit／NanoTimeKit 側にも独立した文字盤の適格性チェックがあります。**動作確認済みの解除ツールや IPA はありません。**

古い研究ファイル名の `RO23` は内部識別子であり、製品名や対応 OS バージョンではありません。

[研究内容・全バージョン履歴（中文）](README.zh-CN.md) · [English summary](README.md#english-summary) · [上流プロジェクト](https://github.com/pookjw/HermesEnabler) · [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) · [LICENSE](LICENSE)

**この研究は Apple および Hermès の公式プロジェクトではありません。**
