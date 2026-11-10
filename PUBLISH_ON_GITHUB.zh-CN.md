# 将 HermesEnabler RO23 发布到你自己的 GitHub

> **发布性质：源代码研究快照，不是 23U95 Hermès 解锁工具，也不是已验证可运行的 IPA。**

## 1. 准备 GitHub 仓库

1. 登录你自己的 GitHub，点击右上角 **+ → New repository**。
2. 建议 Repository name 填写：`HermesEnabler-RO23`。
3. Description 可以填写：`Unofficial research fork of Jinwoo Kim's HermesEnabler for Apple Watch Ultra 1 / watchOS 26.6.1 (23U95). Read-only diagnostics; no verified Hermès activation.`
4. 推荐先选择 **Private**，完成代码复核和本机 Xcode 编译后再切换 Public。
5. 创建空仓库时，不要再自动创建 README / .gitignore / LICENSE：本源码包已经附带。

## 2. 上传文件

将 `HermesEnabler-RO23-Public-Source.zip` 解压。把内部 `HermesEnabler-RO23` **目录里的全部内容**（README.md、LICENSE、HermesEnabler2 文件夹、Xcode 项目等）上传到新仓库**根目录**。

### 推荐：GitHub 网页上传

打开新仓库 → **Add file → Upload files** → 上传已解压的项目文件 → Commit changes。

### 可选：Mac 终端使用 Git

在你 Mac 上进入解压后的 `HermesEnabler-RO23` 文件夹并运行（把 `<你的 GitHub 仓库 HTTPS 地址>` 换成实际地址）：

```bash
cd "你的解压目录/HermesEnabler-RO23"
git init
git branch -M main
git add .
git commit -m "Initial sanitized RO23 research source and documentation"
git remote add origin "<你的 GitHub 仓库 HTTPS 地址>"
git push -u origin main
```

该示例要求本机已完成 Git 身份配置和 GitHub 凭据认证。

## 3. 原作者署名与许可

- **原作者：Jinwoo Kim（@pookjw）**，上游项目：https://github.com/pookjw/HermesEnabler
- **RO23 实机研究：@ZhuoXuan-MY**，Issue #17：https://github.com/pookjw/HermesEnabler/issues/17
- **第三方致谢：Gester**，保留 `HermesEnabler2/Gester-LICENSE.txt`。
- 保留原始 MIT LICENSE 中 `Copyright (c) 2026 Jinwoo Kim`，不要把上游原创归到自己名下。

## 4. 发布前最低限度验证

- [x] 清理原始归档的 .git 历史、重复备份、原开发团队和个人 App Group ID
- [x] 移除错误偏移 `0x670` 的 23U95 直接写入实现
- [x] 禁止系统 MG 保存、恢复、强制 Hermès 修改与能力覆盖
- [x] 禁用所有原有诊断 constructor 自动执行，改为手动按钮
- [x] 确认 ZIP 不含 AEA/dylib/Apple 系统组件及个人日志
- [ ] 在你自己的 Xcode / watchOS SDK 上完成干净的源码编译
- [ ] 在自己的 Apple Watch 上核查 UI、签名和诊断输出
- [ ] 公开发布前再次检查 README、许可、资源归属和用户身份信息

不要把此源码包命名为「适配 watchOS 26.6.1 的 Hermès 解锁正式版」；目前没有成功解锁的实机证据。
