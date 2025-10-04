# 测试图片目录

将陶瓷样本图片放在本目录，供 MATLAB 脚本读取。

## 支持格式

- PNG (.png)
- JPEG (.jpg, .jpeg)
- BMP (.bmp)
- TIFF (.tiff)

## 拍摄建议

1. **分辨率**：保持在 500×500 至 2000×2000 像素之间
2. **光照**：避免强烈阴影或高光，确保缺陷边缘清晰
3. **覆盖类型**：尽量覆盖常见缺陷类型：裂纹、气泡、污点、划痕等

## 文件命名规范

推荐使用：`<日期>_<缺陷类型>_<编号>.<扩展名>`

示例：
- `20250929_defect_01.jpg` - 2025年9月29日的缺陷样本第1张
- `20250929_defect_02.jpg` - 同日缺陷样本第2张
- `20250929_normal_01.jpg` - 正常样本第1张

## 使用示例

### 手动处理单张图片

```matlab
% 使用默认参数
results = ceramic_defect_pipeline('samples/20250929_defect_01.jpg');

% 可视化演示
toolkit = ceramic_toolkit();
toolkit.runDemo('samples/20250929_defect_01.jpg');
```

### 批量处理所有图片

```matlab
% 切换到 matlab 目录后运行
auto_run
```

或者：

```matlab
toolkit = ceramic_toolkit();
toolkit.batchProcess('*.jpg');
```

## 当前样本

本目录包含4张测试图片：
- `20250929_defect_01.jpg`
- `20250929_defect_02.jpg`
- `20250929_defect_03.jpg`
- `20250929_defect_04.jpg`

可以添加更多样本图片进行测试。
