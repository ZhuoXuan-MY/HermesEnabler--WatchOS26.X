# HermesEnabler · watchOS 26.x 相容性研究

**狀態：BLOCKED — 目前技術路線受阻，尚未成功解鎖原生 Hermès 錶面。**

本儲存庫記錄我在 **第一代 Apple Watch Ultra（Watch6,18 / n199ap）**、**watchOS 26.6.1（23U95）** 上進行的實機測試、系統權限研究及原生 Hermès 錶面相容性分析。

實際測試確認受保護的 MobileGestalt 快取可以讀取，但以寫入方式開啟會得到 `EPERM`；另外，ClockKit／NanoTimeKit 的原生錶面資格檢查仍有限制。**本專案不是可用的解鎖工具，沒有已驗證成功的 IPA。**

為保留歷史證據與版本追溯，部分舊研究檔名仍包含早期內部代號 `RO23`，但它不是產品名稱或系統版本。

[完整專案說明與開發紀錄（簡體中文）](README.zh-CN.md) · [English summary](README.md#english-summary) · [原作者專案](https://github.com/pookjw/HermesEnabler) · [研究 Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) · [LICENSE](LICENSE)

**本專案為獨立研究，與 Apple 或 Hermès 無官方關聯。**
