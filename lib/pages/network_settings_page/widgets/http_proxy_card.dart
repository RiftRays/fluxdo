import 'package:flutter/material.dart';

import '../../../services/network/proxy/proxy_settings_service.dart';
import '../../../services/toast_service.dart';

/// 上游代理设置卡片
class HttpProxyCard extends StatelessWidget {
  const HttpProxyCard({
    super.key,
    required this.proxySettings,
    required this.dohEnabled,
  });

  final ProxySettings proxySettings;
  final bool dohEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final proxyService = ProxySettingsService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([
        proxyService.isTesting,
        proxyService.testResultNotifier,
      ]),
      builder: (context, _) {
        final isTesting = proxyService.isTesting.value;
        final testResult = proxyService.testResultNotifier.value;

        return Card(
          clipBehavior: Clip.antiAlias,
          color: proxySettings.enabled
              ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: proxySettings.enabled
                ? BorderSide(color: theme.colorScheme.tertiary.withValues(alpha: 0.3))
                : BorderSide.none,
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('上游代理'),
                subtitle: Text(
                  proxySettings.enabled
                      ? '已启用 ${proxySettings.protocol.displayName} 上游代理，由本地网关统一转发'
                      : '为本地网关配置远端 HTTP / SOCKS5 代理',
                ),
                secondary: Icon(
                  proxySettings.enabled ? Icons.vpn_key : Icons.vpn_key_outlined,
                  color: proxySettings.enabled ? theme.colorScheme.tertiary : null,
                ),
                value: proxySettings.enabled,
                onChanged: (value) async {
                  if (value) {
                    final hasConfig = proxySettings.hasServer;
                    if (!hasConfig) {
                      final saved = await _showProxyConfigDialog(context, proxySettings);
                      if (saved != true) return;
                    }
                  }

                  await proxyService.setEnabled(value);
                  if (!value) {
                    return;
                  }

                  final existingResult = proxyService.testResultNotifier.value;
                  final shouldRetest = existingResult == null ||
                      !existingResult.success ||
                      DateTime.now().difference(existingResult.testedAt) >
                          const Duration(seconds: 30);
                  if (!shouldRetest) {
                    return;
                  }

                  await _runProxyTest(showToast: true);
                },
              ),
              if (proxySettings.hasServer || proxySettings.enabled) ...[
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                ListTile(
                  leading: const Icon(Icons.dns),
                  title: const Text('上游代理服务器'),
                  subtitle: Text(
                    proxySettings.host.isNotEmpty
                        ? '${proxySettings.protocol.displayName} · ${proxySettings.host}:${proxySettings.port}'
                        : '未配置',
                  ),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _showProxyConfigDialog(context, proxySettings),
                ),
                if (proxySettings.username != null && proxySettings.username!.isNotEmpty) ...[
                  Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('认证'),
                    subtitle: Text('用户名: ${proxySettings.username}'),
                    dense: true,
                  ),
                ],
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                ListTile(
                  leading: Icon(
                    _resolveTestIcon(isTesting, testResult),
                    color: _resolveTestColor(theme, isTesting, testResult),
                  ),
                  title: const Text('测试代理可用性'),
                  subtitle: Text(
                    _buildTestSubtitle(
                      isTesting: isTesting,
                      testResult: testResult,
                    ),
                  ),
                  trailing: isTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: () => _runProxyTest(showToast: true),
                          child: const Text('测试'),
                        ),
                  onTap: isTesting ? null : () => _runProxyTest(showToast: true),
                ),
                if (proxySettings.enabled && dohEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Icon(Icons.hub_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '当前会通过本地 DoH 网关转发到上游代理；关闭 DoH 时会切换为纯代理转发',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (!proxySettings.enabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '开启后会保留代理模式开关，由本地网关统一接管 Dio 和 WebView 出口',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<ProxyTestResult> _runProxyTest({required bool showToast}) async {
    final proxyService = ProxySettingsService.instance;
    final result = await proxyService.testCurrentAvailability();
    if (showToast) {
      if (result.success) {
        final latency = result.latency == null ? '' : ' · ${result.latency!.inMilliseconds}ms';
        ToastService.showSuccess('${result.detail}$latency');
      } else {
        ToastService.showError(result.detail);
      }
    }
    return result;
  }

  Future<bool> _showProxyConfigDialog(BuildContext context, ProxySettings proxySettings) async {
    final proxyService = ProxySettingsService.instance;
    final hostController = TextEditingController(text: proxySettings.host);
    final portController = TextEditingController(
      text: proxySettings.port > 0 ? proxySettings.port.toString() : '',
    );
    final usernameController = TextEditingController(text: proxySettings.username ?? '');
    final passwordController = TextEditingController(text: proxySettings.password ?? '');
    final showAuth = ValueNotifier<bool>(
      (proxySettings.username?.isNotEmpty ?? false) ||
          (proxySettings.password?.isNotEmpty ?? false),
    );
    final protocol = ValueNotifier<UpstreamProxyProtocol>(proxySettings.protocol);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('配置上游代理'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<UpstreamProxyProtocol>(
                  valueListenable: protocol,
                  builder: (context, value, _) {
                    return DropdownButtonFormField<UpstreamProxyProtocol>(
                      value: value,
                      decoration: const InputDecoration(
                        labelText: '协议',
                      ),
                      items: UpstreamProxyProtocol.values
                          .map(
                            (item) => DropdownMenuItem<UpstreamProxyProtocol>(
                              value: item,
                              child: Text(item.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (selected) {
                        if (selected != null) {
                          protocol.value = selected;
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hostController,
                  decoration: const InputDecoration(
                    labelText: '服务器地址',
                    hintText: '例如：192.168.1.1 或 proxy.example.com',
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portController,
                  decoration: const InputDecoration(
                    labelText: '端口',
                    hintText: '例如：8080 或 1080',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: showAuth,
                  builder: (context, show, _) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: show,
                              onChanged: (v) => showAuth.value = v ?? false,
                            ),
                            const Text('需要认证'),
                          ],
                        ),
                        if (show) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: '用户名',
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText: '密码',
                            ),
                            obscureText: true,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final host = hostController.text.trim();
                final portText = portController.text.trim();
                if (host.isEmpty || portText.isEmpty) {
                  ToastService.showInfo('请填写服务器地址和端口');
                  return;
                }
                final port = int.tryParse(portText);
                if (port == null || port <= 0 || port > 65535) {
                  ToastService.showError('端口无效');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final host = hostController.text.trim();
      final port = int.tryParse(portController.text.trim()) ?? 0;
      final username = showAuth.value ? usernameController.text.trim() : null;
      final password = showAuth.value ? passwordController.text.trim() : null;
      await proxyService.setServer(
        protocol: protocol.value,
        host: host,
        port: port,
        username: username,
        password: password,
      );
      await _runProxyTest(showToast: true);
    }

    hostController.dispose();
    portController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    showAuth.dispose();
    protocol.dispose();

    return result == true;
  }

  IconData _resolveTestIcon(bool isTesting, ProxyTestResult? testResult) {
    if (isTesting) {
      return Icons.network_check;
    }
    if (testResult == null) {
      return Icons.checklist_rtl_outlined;
    }
    return testResult.success ? Icons.check_circle_outline : Icons.error_outline;
  }

  Color? _resolveTestColor(ThemeData theme, bool isTesting, ProxyTestResult? testResult) {
    if (isTesting || testResult == null) {
      return theme.colorScheme.primary;
    }
    return testResult.success ? theme.colorScheme.primary : theme.colorScheme.error;
  }

  String _buildTestSubtitle({
    required bool isTesting,
    required ProxyTestResult? testResult,
  }) {
    if (isTesting) {
      return '正在验证是否能通过当前代理访问 linux.do';
    }
    if (testResult == null) {
      return '保存后会自动测试，也可以手动重新测试';
    }

    final latency = testResult.latency == null
        ? ''
        : ' · ${testResult.latency!.inMilliseconds}ms';
    return '${testResult.detail}$latency · ${_formatTime(testResult.testedAt)}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
