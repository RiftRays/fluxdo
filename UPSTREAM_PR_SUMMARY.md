# 向上游仓库提交的修正汇总

本文档用于向 `Lingyan000/fluxdo` 原仓库说明本维护版已经完成的修正与调整，便于后续挑选性合并或发起 PR。

## 背景

本维护版主要围绕两个目标展开：

- 提升 Android 在代理网络环境下访问 Linux.do 的稳定性与可排障性
- 让 Fork 仓库能够独立完成子模块维护、CI 构建和正式发版

## 变更总览

| 模块 | 变更内容 | 目的 |
| --- | --- | --- |
| 网络代理 | 将基础代理能力升级为本地网关统一接管的上游代理模型 | 统一 Dio / WebView / 本地代理的网络出口 |
| 协议支持 | 新增 SOCKS5、Shadowsocks、Shadowsocks 2022 (`2022-blake3-aes-256-gcm`) | 适配更多真实代理场景 |
| Android 适配 | 引入 Android 动态网络适配器，按代理/回退状态切换网络实现 | 提升代理环境与 Cloudflare 验证兼容性 |
| 可用性测试 | 新增代理测试入口、认证校验、错误细化 | 让“无法联网”的问题可定位、可复现 |
| Rust 子模块 | `fluxdo_doh` 切换到 Fork，并同步接入新的上游代理能力 | 避免子模块维护受制于上游节奏 |
| CI/CD | 拆分日常构建与正式发布流程 | 简化迭代验证与正式发版 |

## 详细修正说明

### 1. 上游代理网关化

- 将原先较为单一的代理配置能力，调整为由本地网关统一接管的上游代理模型
- 代理模式下，不再只关注单一 HTTP 代理，而是让本地 Rust 网关承担出站统一入口
- 这样做的收益是：
  - Android 页面与接口请求更容易保持同一路径
  - DoH / WebView / Dio 在代理场景下更容易统一行为

### 2. 新增 SOCKS5 / Shadowsocks / Shadowsocks 2022

- 在 Flutter 设置层新增协议选择与持久化
- 在 Rust 子模块中补齐：
  - SOCKS5 隧道能力
  - Shadowsocks 出站能力
  - `2022-blake3-aes-256-gcm` 映射与校验
- 对 Shadowsocks 2022 额外做了：
  - Base64 PSK 校验
  - 32 字节密钥长度校验

### 3. 增强代理测试与错误反馈

- 在设置页新增代理可用性测试入口
- 对常见问题增加更明确的反馈：
  - 代理认证失败
  - CONNECT 隧道失败
  - SOCKS5 认证失败
  - TLS 握手失败
  - Shadowsocks 配置不完整
- 对 Android 特殊情况增加了更保守的判定逻辑，减少“明明能访问但测试误报失败”的情况

### 4. Android 动态适配器

- 增加 Android 动态网络适配器
- 根据当前状态切换：
  - NativeAdapter
  - NetworkHttpAdapter
  - WebViewHttpAdapter
- 目标是尽可能减少在代理、回退、CF 验证等场景下的网络栈不一致问题

### 5. 构建与发布流程重整

- 将日常构建与正式发布拆分：
  - `build.yaml`：监听 `main` 提交，持续输出 Android `arm64-v8a` 构建产物
  - `release.yaml`：负责正式 Release
- Release 说明中：
  - 顶部自动写入本次推送日志
  - 底部追加发布模板
- 当前策略聚焦 Android `arm64-v8a`，目的是降低 CI 成本、提升验证效率

## 建议上游合并顺序

如果上游准备挑选性吸收，建议按以下顺序进行：

1. **代理测试与错误反馈优化**
2. **Android 动态适配器**
3. **SOCKS5 与上游代理网关**
4. **Shadowsocks**
5. **Shadowsocks 2022**
6. **CI/CD 调整**

## 风险与兼容性说明

- 代理相关改动涉及 Flutter 与 Rust 子模块联动，建议和子模块提交一起评估
- Shadowsocks 2022 与旧版 Shadowsocks 在密钥语义上不同，不能只改 UI 文案而不改底层校验
- CI/CD 改动偏向个人 Fork 运维策略，上游是否接受可按其发布策略决定

## 本维护版已落地的关键提交

- `6e641be` `feat: add upstream proxy gateway and split workflows`
- `266076c` `fix: avoid secrets in workflow if expressions`
- `74cc85a` `fix: disambiguate webview proxy types`
- `876cdf9` `feat: add upstream proxy testing and socks5 support`
- `cb5f22d` `fix: keep proxy enabled when test fails`
- `620ad41` `fix: update doh proxy tunnel handshake handling`
- `1778230` `feat: use webview adapter for android proxy mode`
- `6ac1c50` `feat: add shadowsocks upstream settings`
- `993dcf1` `fix: handle shadowsocks switch branch`
- `ea9b6ef` `feat: support shadowsocks 2022 aes-256-gcm`

## 备注

如果要向上游仓库发起 PR，建议将本文档作为说明基础，再根据实际提交范围拆分为多个更小的 PR，以便审阅与回归测试。
