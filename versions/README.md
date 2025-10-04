# 版本历史记录

本目录保存每次参数调整的完整记录，包括：
- 版本说明和优化目标
- 参数调整详情
- 检测结果分析
- 代码快照
- 运行结果对比

## 版本列表

### v2.1 - 2025-10-02
**优化目标**：解决大尺寸图像（6000×8000）检测问题
- 目录：`v2.1_large_image_optimization/`
- 状态：✅ 已优化

### v2.0 - 2025-10-02
**初始版本**：基础检测流程
- 目录：`v2.0_baseline/`
- 状态：⚠️ 发现问题（缺陷率57%、圆形350+）

---

## 使用说明

### 查看某个版本
```bash
cd versions/v2.1_large_image_optimization/
```

### 恢复到某个版本
```matlab
% 复制历史版本的参数文件到当前目录
copyfile('versions/v2.1_*/code/ceramic_default_options.m', 'matlab/');
```

### 创建新版本
每次重大调整后，运行：
```matlab
create_version  % 自动创建版本快照
```

