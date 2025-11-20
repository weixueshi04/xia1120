import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'config/theme.dart';
import 'config/api_config.dart';
import 'screens/main_navigation_screen.dart';
import 'utils/logger.dart';
import 'services/proxy_manager.dart';

Future<void> main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 初始化API配置
    await APIConfig().initialize();
    
    // 只在Web环境下启动代理（解决跨域问题）
    if (kIsWeb) {
      Logger.info('🌐 Web环境检测到，启动百度API代理...');
      final proxyManager = ProxyManager();
      await proxyManager.initialize();
      
      if (proxyManager.isRunning) {
        Logger.info('✅ 代理服务已就绪');
      } else {
        Logger.warning('⚠️ 代理服务启动失败，将尝试直连');
      }
    } else {
      Logger.info('📱 移动端环境，跳过代理（直接调用API）');
    }
  } catch (e) {
    Logger.error('初始化失败', error: e);
  }
  
  runApp(const XiaApp());
}

class XiaApp extends StatelessWidget {
  const XiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '夏同龢 · 麻江非遗数字文创平台',
      theme: MiaoTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
