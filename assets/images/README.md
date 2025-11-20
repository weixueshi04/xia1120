# 图片资源说明

本项目的图片资源组织结构如下：

## 目录结构

```
assets/images/
├── heritage/          # 非遗档案图片
│   ├── batik/        # 蜡染相关
│   ├── silverware/   # 银饰相关
│   ├── embroidery/   # 刺绣相关
│   └── craftsmen/    # 传承人照片
├── products/          # 文创产品图片
│   ├── bookmarks/    # 书签类
│   ├── bags/         # 包袋类
│   ├── jewelry/      # 饰品类
│   └── stationery/   # 文具类
├── avatars/           # 头像和角色图片
│   ├── xiatonge.png  # 夏同龢头像
│   └── roles/        # 各角色图标
└── launcher_icon.png  # 应用图标
```

## 图片命名规范

### 非遗档案图片
- 格式: `类型_名称_序号.jpg`
- 示例: `batik_butterfly_pattern_01.jpg` (蜡染-蝴蝶纹样-01)
- 示例: `silverware_necklace_miao_01.jpg` (银饰-苗族项圈-01)

### 文创产品图片
- 格式: `产品类型_设计主题_序号.jpg`
- 示例: `bookmark_batik_traditional_01.jpg` (书签-蜡染传统款-01)
- 示例: `bag_canvas_butterfly_01.jpg` (帆布包-蝴蝶图案-01)

### 传承人照片
- 格式: `craftsman_姓名_工艺.jpg`
- 示例: `craftsman_wang_batik.jpg` (王师傅-蜡染)

## 推荐尺寸

### 非遗档案图片
- 列表缩略图: 300x300px
- 详情页大图: 1200x800px
- 传承人照片: 600x800px (竖版)

### 文创产品图片
- 列表缩略图: 400x400px
- 详情页大图: 1500x1500px
- 多角度展示: 800x800px

### 头像图标
- 用户头像: 200x200px
- 角色图标: 128x128px
- 应用图标: 512x512px

## 图片格式建议

- **照片类**: 使用 JPG 格式，质量 80-90%
- **图标/矢量**: 使用 PNG 格式（透明背景）
- **大图**: 提供 @2x 和 @3x 版本（可选）

## 图片来源说明

所有非遗相关图片应标注来源：
- 实地拍摄
- 传承人提供
- 档案馆/博物馆授权
- 公共领域资源

## 使用示例

### 在Flutter中使用

```dart
// 本地图片
Image.asset('assets/images/heritage/batik/butterfly_pattern_01.jpg')

// 带占位图
Image.asset(
  'assets/images/products/bookmarks/batik_traditional_01.jpg',
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.image_not_supported);
  },
)
```

### 在Product模型中使用

```dart
Product(
  id: 1,
  name: '蜡染书签',
  imagePath: 'assets/images/products/bookmarks/batik_traditional_01.jpg',
  gallery: [
    'assets/images/products/bookmarks/batik_traditional_01.jpg',
    'assets/images/products/bookmarks/batik_traditional_02.jpg',
  ],
)
```

## 注意事项

1. 所有图片文件名使用小写字母和下划线
2. 避免使用中文文件名
3. 压缩图片以减小应用体积
4. 版权清晰，确保有使用授权
5. 定期清理未使用的图片资源

## 图片优化工具推荐

- **TinyPNG**: 在线压缩工具 (https://tinypng.com/)
- **ImageOptim**: Mac平台图片优化工具
- **Squoosh**: Google开源的图片压缩工具

## 占位图生成

在实际图片未准备好时，可使用以下占位服务：
- Unsplash Source: `https://source.unsplash.com/300x300/?heritage`
- Picsum: `https://picsum.photos/300/300`
- 纯色占位: 使用Container with Color

---

**最后更新**: 2025-01-20
