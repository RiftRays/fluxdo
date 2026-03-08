# FluxDO

> 一个真诚、友善、团结、专业的 [Linux.do](https://linux.do/) 第三方客户端

[![Telegram Channel](https://img.shields.io/badge/Telegram-Channel-26A5E4?logo=telegram&logoColor=white)](https://t.me/ldxfd)
[![Telegram Group](https://img.shields.io/badge/Telegram-Group-26A5E4?logo=telegram&logoColor=white)](https://t.me/fluxdo_chat)

FluxDO 是为 [Linux.do](https://linux.do/) 社区打造的现代化移动和桌面客户端，基于 Flutter 开发，致力于为用户提供流畅、优雅的论坛浏览体验。

![FluxDO 预览](screenshots/preview.png)

## 仓库说明

本仓库是基于上游 `Lingyan000/fluxdo` 的维护版 Fork，当前重点放在以下三个方向：

- 面向真实使用场景优化 Android 代理与联网兼容性
- 将构建、发布、子模块依赖切换为可在个人 Fork 中独立维护
- 优先提供适合真机验证和日常分发的 Android `arm64-v8a` 版本

## 与原项目的差异对比

| 对比项 | 上游原项目 | 当前维护版 | 维护版优势 |
| --- | --- | --- | --- |
| 构建流程 | 以标签触发构建与发布，工作流职责较集中 | 拆分为 `build.yaml` 与 `release.yaml`，日常提交自动构建，发版单独执行 | 更适合持续迭代、定位问题和独立维护 |
| 发布策略 | 预设多 Android 架构与 iOS 产物 | 当前聚焦 Android `arm64-v8a` 正式包 | 出包更快、失败面更小、真机验证更直接 |
| 子模块来源 | 指向上游 `fluxdo_doh` 仓库 | 指向自己的 `RiftRays/fluxdo_doh` Fork | 子模块升级、修复和 CI 不再依赖上游节奏 |
| 上游代理模型 | 以基础 HTTP 代理为主，和 DoH 关系较松 | 改为本地网关统一接管的上游代理模型 | 代理路径更统一，Android / Dio / WebView 更容易保持一致 |
| 支持的代理协议 | 基础 HTTP | HTTP、SOCKS5、Shadowsocks、Shadowsocks 2022 | 更适合复杂网络环境和代理用户 |
| Android 联网适配 | 默认网络栈切换策略较基础 | 增加 Android 动态适配器，按代理/回退状态选择 Native / Network / WebView | 对 Cloudflare 验证、代理场景和兼容性更友好 |
| 代理可用性验证 | 代理排障能力有限 | 增加代理测试入口、认证校验、错误信息细化 | 更方便快速定位“能连代理但不能访问站点”的问题 |
| Shadowsocks 支持 | 不支持上游 Shadowsocks | 已支持 Shadowsocks，并补充 `2022-blake3-aes-256-gcm` | 可以直接接入更多现成节点配置 |

## 当前维护版优势

- **更适合代理网络环境**：围绕 Linux.do 的实际访问问题，重点增强了 Android 代理接入、连通性测试与兼容性处理。
- **更适合个人 Fork 独立维护**：子模块、构建和发布流程都可以在自己的仓库闭环完成。
- **更适合真机调试**：当前出包聚焦 `arm64-v8a`，能更快验证修复是否真正解决问题。
- **更适合持续演进**：将网络、代理、工作流拆分为更清晰的模块，后续继续维护成本更低。

## 特性

### 核心功能
- **跨平台支持**：Android、iOS、Windows、macOS、Linux
- **Material Design 3**：现代化 UI 设计，支持动态取色
- **深色模式**：自动适配系统主题
- **完整论坛功能**：浏览话题、发帖回复、搜索、通知
- **内容管理**：书签、浏览历史、关注列表
- **徽章系统**：查看和展示社区徽章
- **Markdown 编辑器**：支持富文本编辑和预览
- **图片支持**：图片上传、查看、保存
- **投票功能**：参与社区投票

### 技术特性
- **安全连接**：集成 Rust 实现的 DOH (DNS over HTTPS) 代理
- **代理兼容增强**：支持 HTTP / SOCKS5 / Shadowsocks / Shadowsocks 2022 上游代理
- **性能优化**：图片缓存、懒加载、代码高亮
- **实时通知**：MessageBus 实时消息推送
- **智能渲染**：HTML 内容分块渲染，流畅滚动

## 快速开始

### 前置要求

- Flutter SDK ^3.10.4
- Rust 工具链（用于编译 DOH 代理）
- Android Studio / Xcode（移动端开发）

### 安装步骤

1. **克隆仓库**
   ```bash
   git clone https://github.com/RiftRays/fluxdo.git
   cd fluxdo
   ```

2. **安装 Flutter 依赖**
   ```bash
   flutter pub get
   ```

3. **编译 Rust DOH 代理**（可选，用于网络加速）

   桌面平台：
   ```bash
   # Windows
   .\scripts\build_desktop.ps1

   # macOS/Linux
   ./scripts/build_desktop.sh
   ```

   Android 平台：
   ```bash
   # Windows
   .\scripts\build_android.ps1

   # macOS/Linux
   ./scripts/build_android.sh
   ```

4. **运行应用**
   ```bash
   # Android
   flutter run --dart-define=cronetHttpNoPlay=true

   # Windows
   flutter run -d windows

   # macOS
   flutter run -d macos
   ```

## 项目结构

```
fluxdo/
├── lib/
│   ├── config/              # 应用配置
│   ├── models/              # 数据模型（话题、用户、通知等）
│   ├── modules/             # 功能模块
│   ├── pages/               # 页面组件
│   ├── providers/           # Riverpod 状态管理
│   ├── services/            # 业务逻辑服务
│   │   ├── network/         # 网络层（DOH、代理、适配器）
│   │   └── ...
│   ├── utils/               # 工具类
│   ├── widgets/             # 可复用组件
│   └── main.dart
├── core/
│   └── doh_proxy/           # Rust DOH 代理实现
├── packages/                # 本地依赖包
├── scripts/                 # 构建脚本
└── pubspec.yaml
```

## 技术栈

- **前端框架**：Flutter
- **状态管理**：Riverpod
- **网络请求**：Dio + Native Dio Adapter
- **HTML 渲染**：flutter_widget_from_html
- **代码高亮**：re_highlight + google_fonts (FiraCode)
- **图片处理**：extended_image + cached_network_image
- **本地存储**：shared_preferences + flutter_secure_storage
- **网络代理**：Rust (DOH + ECH)

## DOH 代理功能

FluxDO 集成了基于 Rust 的 DOH (DNS over HTTPS) 代理，提供：

- **DNS 加密查询**：防止 DNS 污染和劫持
- **多服务器支持**：DNSPod、腾讯 DNS、阿里 DNS、Cloudflare、Canadian Shield、Google、Quad9
- **ECH 支持**：加密 TLS 握手中的 SNI 字段（用户无感知）
- **跨平台实现**：
  - Android/iOS：FFI 调用
  - Windows/macOS/Linux：独立进程

更多信息：

- 上游子模块文档：[`core/doh_proxy/README.md`](https://github.com/Lingyan000/fluxdo_doh)
- 当前维护版子模块仓库：[`RiftRays/fluxdo_doh`](https://github.com/RiftRays/fluxdo_doh)

## 发版说明

- 日常构建：提交到 `main` 后会触发 `.github/workflows/build.yaml`
- 正式发布：推送 `v*` 标签，或手动执行 `.github/workflows/release.yaml`
- Release 说明顶部会自动附带本次推送日志，随后再拼接 `.github/release_template.md`
- 当前正式 Release 仅发布 Android `arm64-v8a`

## 向上游同步的说明材料

- 已整理可直接发给原作者的修正汇总：`UPSTREAM_PR_SUMMARY.md`
- 建议后续向上游提交时，按“代理测试 → Android 适配 → 协议支持 → CI/CD”顺序分批发起 PR

## 关于 Linux.do

[Linux.do](https://linux.do/) 是一个真诚、友善、团结、专业的技术社区，汇聚了众多热爱技术、乐于分享的开发者。FluxDO 作为第三方客户端，致力于为社区成员提供更好的移动和桌面端体验。

**注意**：本项目为非官方客户端，与 Linux.do 官方无直接关联。

## 问题反馈

如果您在使用过程中遇到问题或有建议，欢迎：
- 在 [Linux.do](https://linux.do/) 论坛发帖讨论
- 提交 [Issue](https://github.com/RiftRays/fluxdo/issues)

## 开源协议

本项目基于 [GPL-3.0](LICENSE) 协议开源。

## 致谢

感谢 [Linux.do](https://linux.do/) 社区的所有成员，是你们的真诚、友善、团结、专业让这个社区充满活力。
