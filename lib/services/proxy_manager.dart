import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// 百度API代理管理器
/// 
/// 功能：
/// - 自动检测代理是否运行
/// - 自动启动Node.js代理服务
/// - 监控代理健康状态
/// - 自动重启失败的代理
class ProxyManager {
  static final ProxyManager _instance = ProxyManager._internal();
  factory ProxyManager() => _instance;
  ProxyManager._internal();

  Process? _proxyProcess;
  Timer? _healthCheckTimer;
  bool _isRunning = false;
  int _restartAttempts = 0;
  static const int _maxRestartAttempts = 3;

  /// 代理服务器配置
  static const String proxyHost = 'localhost';
  static const int proxyPort = 3000;
  static const String proxyUrl = 'http://$proxyHost:$proxyPort';
  static const String healthCheckUrl = '$proxyUrl/health';

  /// 代理是否正在运行
  bool get isRunning => _isRunning;

  /// 获取代理URL
  String get baseUrl => proxyUrl;

  /// 初始化代理管理器
  Future<void> initialize() async {
    Logger.info('初始化代理管理器...');
    
    // 检查代理是否已经在运行
    final isAlreadyRunning = await checkProxyHealth();
    
    if (isAlreadyRunning) {
      Logger.info('✅ 代理服务已在运行');
      _isRunning = true;
      _startHealthCheck();
      return;
    }

    // 尝试启动代理
    await startProxy();
  }

  /// 启动代理服务
  Future<bool> startProxy() async {
    if (_isRunning) {
      Logger.info('代理服务已在运行');
      return true;
    }

    try {
      Logger.info('🚀 正在启动百度API代理服务...');

      // 获取项目根目录
      final projectRoot = Directory.current.path;
      final proxyDir = '$projectRoot${Platform.pathSeparator}baidu-proxy';

      // 检查代理目录是否存在
      if (!await Directory(proxyDir).exists()) {
        Logger.error('代理目录不存在: $proxyDir');
        return false;
      }

      // 检查Node.js是否安装
      if (!await _checkNodeInstalled()) {
        Logger.error('Node.js未安装，请先安装Node.js');
        return false;
      }

      // 启动Node.js服务器
      if (Platform.isWindows) {
        // Windows: 使用start.bat或直接运行node
        _proxyProcess = await Process.start(
          'node',
          ['server.js'],
          workingDirectory: proxyDir,
          mode: ProcessStartMode.detached,
        );
      } else {
        // Linux/Mac: 直接运行node
        _proxyProcess = await Process.start(
          'node',
          ['server.js'],
          workingDirectory: proxyDir,
          mode: ProcessStartMode.detached,
        );
      }

      // 监听输出
      _proxyProcess!.stdout.listen((data) {
        final output = String.fromCharCodes(data);
        Logger.debug('[Proxy] $output');
      });

      _proxyProcess!.stderr.listen((data) {
        final error = String.fromCharCodes(data);
        Logger.warning('[Proxy Error] $error');
      });

      // 等待服务启动
      await Future.delayed(const Duration(seconds: 2));

      // 验证服务是否启动成功
      final isHealthy = await checkProxyHealth();
      
      if (isHealthy) {
        _isRunning = true;
        _restartAttempts = 0;
        Logger.info('✅ 代理服务启动成功！');
        Logger.info('   地址: $proxyUrl');
        
        // 开始健康检查
        _startHealthCheck();
        
        return true;
      } else {
        Logger.error('❌ 代理服务启动失败');
        await stopProxy();
        return false;
      }

    } catch (e, stackTrace) {
      Logger.error('启动代理服务时出错', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 停止代理服务
  Future<void> stopProxy() async {
    Logger.info('停止代理服务...');

    // 停止健康检查
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    // 终止进程
    if (_proxyProcess != null) {
      _proxyProcess!.kill();
      _proxyProcess = null;
    }

    _isRunning = false;
    Logger.info('代理服务已停止');
  }

  /// 检查代理健康状态
  Future<bool> checkProxyHealth() async {
    try {
      final response = await http.get(
        Uri.parse(healthCheckUrl),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 开始健康检查（每30秒检查一次）
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        final isHealthy = await checkProxyHealth();
        
        if (!isHealthy && _isRunning) {
          Logger.warning('⚠️ 代理服务健康检查失败');
          
          // 尝试重启
          if (_restartAttempts < _maxRestartAttempts) {
            _restartAttempts++;
            Logger.info('尝试重启代理服务 (第$_restartAttempts次)...');
            
            await stopProxy();
            await Future.delayed(const Duration(seconds: 2));
            await startProxy();
          } else {
            Logger.error('代理服务重启失败次数过多，停止尝试');
            timer.cancel();
          }
        } else if (isHealthy && !_isRunning) {
          // 代理恢复了
          _isRunning = true;
          _restartAttempts = 0;
          Logger.info('✅ 代理服务已恢复');
        }
      },
    );
  }

  /// 检查Node.js是否安装
  Future<bool> _checkNodeInstalled() async {
    try {
      final result = await Process.run('node', ['--version']);
      if (result.exitCode == 0) {
        final version = result.stdout.toString().trim();
        Logger.info('检测到Node.js版本: $version');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 获取代理状态信息
  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _isRunning,
      'proxyUrl': proxyUrl,
      'restartAttempts': _restartAttempts,
      'hasProcess': _proxyProcess != null,
    };
  }

  /// 清理资源
  Future<void> dispose() async {
    await stopProxy();
  }
}
