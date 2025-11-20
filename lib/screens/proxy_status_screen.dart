import 'package:flutter/material.dart';
import '../services/proxy_manager.dart';
import '../config/theme.dart';
import 'dart:async';

/// 代理状态监控界面
class ProxyStatusScreen extends StatefulWidget {
  const ProxyStatusScreen({super.key});

  @override
  State<ProxyStatusScreen> createState() => _ProxyStatusScreenState();
}

class _ProxyStatusScreenState extends State<ProxyStatusScreen> {
  final ProxyManager _proxyManager = ProxyManager();
  Timer? _refreshTimer;
  Map<String, dynamic> _status = {};
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    
    // 每5秒刷新一次状态
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshStatus(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });

    final status = _proxyManager.getStatus();
    final isHealthy = await _proxyManager.checkProxyHealth();
    
    setState(() {
      _status = {
        ...status,
        'isHealthy': isHealthy,
      };
      _isChecking = false;
    });
  }

  Future<void> _startProxy() async {
    setState(() {
      _isChecking = true;
    });

    final success = await _proxyManager.startProxy();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ 代理启动成功' : '❌ 代理启动失败'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    await _refreshStatus();
  }

  Future<void> _stopProxy() async {
    setState(() {
      _isChecking = true;
    });

    await _proxyManager.stopProxy();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('代理已停止'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _status['isRunning'] as bool? ?? false;
    final isHealthy = _status['isHealthy'] as bool? ?? false;
    final proxyUrl = _status['proxyUrl'] as String? ?? '';
    final restartAttempts = _status['restartAttempts'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('代理服务状态'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MiaoTheme.indigoDye,
                MiaoTheme.indigoDye.withAlpha((0.8 * 255).round()),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 状态卡片
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isRunning && isHealthy
                              ? Icons.check_circle
                              : Icons.error,
                          color: isRunning && isHealthy
                              ? Colors.green
                              : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRunning && isHealthy
                                    ? '代理服务运行正常'
                                    : isRunning
                                        ? '代理服务异常'
                                        : '代理服务未运行',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                proxyUrl,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    // 详细信息
                    _buildInfoRow('运行状态', isRunning ? '运行中' : '已停止'),
                    _buildInfoRow('健康检查', isHealthy ? '正常' : '异常'),
                    _buildInfoRow('重启次数', '$restartAttempts 次'),
                    _buildInfoRow('代理地址', proxyUrl),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isChecking || isRunning ? null : _startProxy,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('启动代理'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isChecking || !isRunning ? null : _stopProxy,
                    icon: const Icon(Icons.stop),
                    label: const Text('停止代理'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 刷新按钮
            ElevatedButton.icon(
              onPressed: _isChecking ? null : _refreshStatus,
              icon: _isChecking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isChecking ? '检查中...' : '刷新状态'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MiaoTheme.indigoDye,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

            // 说明文字
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '关于代理服务',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '代理服务用于解决百度API的跨域访问问题。'
                      '应用启动时会自动检测并启动代理服务。\n\n'
                      '如果代理服务异常，请确保：\n'
                      '1. Node.js已正确安装\n'
                      '2. 端口3000未被占用\n'
                      '3. baidu-proxy目录存在',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
