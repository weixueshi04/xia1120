const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// ==================== 百度千帆Agent API代理 ====================

/**
 * 创建会话
 * POST /api/baidu/conversation
 */
app.post('/api/baidu/conversation', async (req, res) => {
  try {
    const { appId, bearerToken } = req.body;
    
    console.log('🆕 创建百度Agent会话...');
    
    const response = await axios.post(
      'https://qianfan.baidubce.com/v2/app/conversation',
      { app_id: appId },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${bearerToken}`,
        }
      }
    );
    
    console.log('✅ 会话创建成功');
    res.json(response.data);
    
  } catch (error) {
    console.error('❌ 会话创建失败:', error.response?.data || error.message);
    res.status(500).json({ 
      error: '会话创建失败', 
      details: error.response?.data || error.message 
    });
  }
});

/**
 * 调用Agent对话
 * POST /api/baidu/chat
 */
app.post('/api/baidu/chat', async (req, res) => {
  try {
    const { appId, bearerToken, query, conversationId } = req.body;
    
    console.log('💬 调用百度Agent...');
    console.log(`   应用ID: ${appId}`);
    console.log(`   用户问题: ${query}`);
    
    const response = await axios.post(
      'https://qianfan.baidubce.com/v2/app/conversation/runs',
      {
        app_id: appId,
        query: query,
        conversation_id: conversationId || '',
        stream: false
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${bearerToken}`,
        }
      }
    );
    
    console.log('✅ Agent回答成功');
    res.json(response.data);
    
  } catch (error) {
    console.error('❌ Agent调用失败:', error.response?.data || error.message);
    res.status(500).json({ 
      error: 'Agent调用失败', 
      details: error.response?.data || error.message 
    });
  }
});

// ==================== 百度语音API代理 ====================

/**
 * 获取百度语音Token
 * POST /api/baidu/speech/token
 */
app.post('/api/baidu/speech/token', async (req, res) => {
  try {
    const { apiKey, secretKey } = req.body;
    
    console.log('🔑 获取百度语音Token...');
    
    const response = await axios.get('https://aip.baidubce.com/oauth/2.0/token', {
      params: {
        grant_type: 'client_credentials',
        client_id: apiKey,
        client_secret: secretKey,
      }
    });
    
    console.log('✅ Token获取成功');
    res.json(response.data);
    
  } catch (error) {
    console.error('❌ Token获取失败:', error.response?.data || error.message);
    res.status(500).json({ 
      error: 'Token获取失败', 
      details: error.response?.data || error.message 
    });
  }
});

/**
 * 文字转语音
 * GET /api/baidu/speech/tts
 */
app.get('/api/baidu/speech/tts', async (req, res) => {
  try {
    console.log('🔊 调用百度TTS...');
    
    // 直接将请求转发到百度TTS API
    const ttsUrl = 'https://tsn.baidu.com/text2audio';
    
    // 转发请求参数
    const params = { ...req.query };
    
    // 设置响应类型为流
    res.setHeader('Content-Type', 'audio/wav');
    
    // 转发请求到百度TTS API
    const response = await axios({
      method: 'GET',
      url: ttsUrl,
      params: params,
      responseType: 'stream'
    });
    
    // 将响应流转发给客户端
    response.data.pipe(res);
    
    console.log('✅ TTS音频流传输成功');
    
  } catch (error) {
    console.error('❌ TTS调用失败:', error.response?.data || error.message);
    res.status(500).json({ 
      error: 'TTS调用失败', 
      details: error.response?.data || error.message 
    });
  }
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: '百度Agent代理服务器运行正常',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log('');
  console.log('========================================');
  console.log('🚀 百度Agent代理服务器启动成功！');
  console.log('========================================');
  console.log(`📍 本地地址: http://localhost:${PORT}`);
  console.log(`🔗 健康检查: http://localhost:${PORT}/health`);
  console.log('');
  console.log('可用接口:');
  console.log('  POST /api/baidu/conversation     - 创建会话');
  console.log('  POST /api/baidu/chat             - Agent对话');
  console.log('  POST /api/baidu/speech/token     - 获取语音Token');
  console.log('  GET  /api/baidu/speech/tts       - 文字转语音');
  console.log('  GET  /health                     - 健康检查');
  console.log('');
  console.log('按 Ctrl+C 停止服务器');
  console.log('========================================');
  console.log('');
});
