# v3.0 ROI检测功能说明

**版本**：v3.0  
**日期**：2025-10-04  
**核心改进**：增加陶瓷管ROI检测，确保只在陶瓷管区域内检测缺陷

## 🎯 核心目标

**确保检测到所有白色陶瓷管，排除背景和遮挡物的干扰**

## 📁 新增文件

### 1. `detect_ceramic_roi.m`
**功能**：检测图像中的陶瓷管区域（ROI）

**算法策略**：
1. **基于亮度** - 陶瓷管是白色/灰色，比背景亮
2. **基于位置** - 陶瓷管在图像中间的水平带状区域
3. **形态学连接** - 连接所有相邻的管子
4. **保守策略** - 宁可多检测，不漏检任何管子

**关键参数**：
```matlab
- BrightnessThreshold: 0.20（默认）- 较低以确保不漏检
- HeightRange: [0.25, 0.75]（默认）- 图像中间50%
- MorphCloseRadius: 40（默认）- 大半径连接管子
- MorphOpenRadius: 15（默认）- 去除小噪声
```

**使用方法**：
```matlab
% 基本用法
roiMask = detect_ceramic_roi(grayImage);

% 自定义参数
roiMask = detect_ceramic_roi(grayImage, ...
    'BrightnessThreshold', 0.18, ...  % 更低=更多管子
    'HeightRange', [0.2, 0.8]);        % 更大范围
```

### 2. `test_roi_detection.m`
**功能**：测试和验证ROI检测效果

**输出**：
- 6个子图对比不同参数的ROI检测效果
- ROI覆盖率统计
- ROI边界叠加在原图上

**使用方法**：
```matlab
cd matlab
test_roi_detection
```

**查看结果**：
- 确认绿色边界是否覆盖所有白色管子
- 如果有管子未覆盖，调整参数重新测试

## 🔧 修改的文件

### 1. `ceramic_defect_pipeline.m`
**主要改进**：

#### 新增参数
```matlab
- EnableROI: true（默认）- 是否启用ROI检测
- ROIBrightnessThreshold: 0.20 - ROI检测亮度阈值
- ROIHeightRange: [0.25, 0.75] - ROI检测垂直范围
```

#### 改进流程
```matlab
旧流程（v2.2）：
1. CLAHE增强（整张图）
2. Otsu分割（整张图）
3. 边缘检测（整张图）
4. 直线/圆形检测（整张图）

新流程（v3.0）：
1. 🆕 检测陶瓷管ROI
2. CLAHE增强（整张图，但后续只用ROI）
3. 🆕 Otsu分割（只在ROI内）
4. 🆕 边缘检测（只在ROI内）
5. 🆕 直线/圆形检测（只在ROI内）
```

### 2. `ceramic_performance_metrics.m`
**改进**：

**缺陷率计算**：
```matlab
v2.2: 缺陷覆盖率 = 缺陷像素数 / 整张图像素数
      → 51%（包含背景，不准确）

v3.0: 缺陷覆盖率 = 缺陷像素数 / ROI像素数
      → <5%（只计算陶瓷管区域，准确）
```

**新增指标**：
```matlab
performance.roiCoverage  % ROI占整张图的比例
```

### 3. `view_results.m`
已更新以支持ROI可视化（自动兼容v2.x和v3.0）

## 🚀 使用方法

### 快速开始

1. **测试ROI检测效果**：
```matlab
cd matlab
test_roi_detection  % 查看ROI是否覆盖所有管子
```

2. **处理单张图片（v3.0）**：
```matlab
cd matlab
% auto_run已默认启用v3.0
auto_run
```

3. **查看结果**：
```matlab
quick_view  % 会显示ROI掩码
```

### 高级用法

#### 禁用ROI（回到v2.2模式）
```matlab
results = ceramic_defect_pipeline(imagePath, ...
    struct('EnableROI', false));
```

#### 自定义ROI参数
```matlab
results = ceramic_defect_pipeline(imagePath, ...
    struct('ROIBrightnessThreshold', 0.18, ...
           'ROIHeightRange', [0.2, 0.8]));
```

#### 只使用ROI检测功能
```matlab
Igray = im2double(rgb2gray(imread('sample.jpg')));
roiMask = detect_ceramic_roi(Igray);
imshow(roiMask);
```

## 📊 预期效果对比

| 指标 | v2.2（无ROI） | v3.0（有ROI） |
|------|--------------|--------------|
| **检测区域** | 整张图（100%） | 陶瓷管区域（~45%） |
| **缺陷覆盖率** | 51.03% | **<5%** ✅ |
| **背景干扰** | 严重 | **无** ✅ |
| **前景遮挡** | 包含 | **部分排除** |
| **指标准确性** | 低（混杂背景） | **高** ✅ |
| **符合需求** | ❌ | **✅** |

## ⚠️ 注意事项

### 1. ROI检测验证
**每次使用新数据前，务必先运行`test_roi_detection`验证ROI效果！**

检查清单：
- ✅ 所有白色管子都被绿色边界包围
- ✅ ROI覆盖率在30%-60%之间合理
- ✅ 深色背景被排除在外
- 🟡 前景白色支撑杆可能部分包含（可接受）

### 2. 参数调整建议

如果ROI漏检管子：
```matlab
% 降低亮度阈值
'ROIBrightnessThreshold', 0.15  % 从0.20降低

% 扩大垂直范围
'ROIHeightRange', [0.2, 0.8]    % 从[0.25,0.75]扩大
```

如果ROI包含太多背景：
```matlab
% 提高亮度阈值
'ROIBrightnessThreshold', 0.25  % 从0.20提高

% 缩小垂直范围
'ROIHeightRange', [0.3, 0.7]    % 从[0.25,0.75]缩小
```

### 3. 前景遮挡处理
白色支撑杆可能会被包含在ROI中（因为也是白色）。

如需去除：
```matlab
roiMask = detect_ceramic_roi(Igray, 'RemoveForeground', true);
```

**警告**：此功能可能会误删除部分管子，谨慎使用！

## 🐛 故障排除

### 问题1：ROI覆盖率过低（<20%）
**原因**：亮度阈值太高，漏检了管子

**解决**：
```matlab
% 在test_roi_detection.m中测试
roiMask = detect_ceramic_roi(Igray, 'BrightnessThreshold', 0.15);
```

### 问题2：ROI覆盖率过高（>70%）
**原因**：亮度阈值太低，包含了背景

**解决**：
```matlab
roiMask = detect_ceramic_roi(Igray, 'BrightnessThreshold', 0.28);
```

### 问题3：上下边缘的管子被裁剪
**原因**：`HeightRange`太窄

**解决**：
```matlab
roiMask = detect_ceramic_roi(Igray, 'HeightRange', [0.15, 0.85]);
```

### 问题4：缺陷率仍然很高（>10%）
**可能原因**：
1. ROI包含了太多背景 → 调整ROI参数
2. 陶瓷管本身纹理被误判 → 调整Otsu参数
3. 真的有很多缺陷 → 这是正常的

**诊断方法**：
```matlab
cd matlab
quick_view
% 查看"局部Otsu"子图，检查红色区域是否合理
```

## 📝 版本兼容性

v3.0完全向后兼容v2.x：

**自动兼容**：
- 旧代码无需修改
- 默认启用ROI（`EnableROI = true`）
- 如需v2.x行为：`struct('EnableROI', false)`

**结果结构体**：
```matlab
v2.x结果：
- results.original
- results.enhanced
- results.binaryGlobal
- results.binaryLocal
- results.edgeMaps
- results.houghLines
- results.circles

v3.0新增：
- results.roiMask      % ROI掩码
- results.roiEnabled   % 是否启用ROI
```

## 🎓 技术细节

### ROI检测算法流程

```
输入：灰度图像
 ↓
步骤1：亮度筛选
 ├─ threshold = 0.20（可调）
 └─ brightMask = image > threshold
 ↓
步骤2：位置约束
 ├─ heightRange = [0.25, 0.75]（可调）
 └─ positionMask = 中间区域
 ↓
步骤3：组合
 └─ ceramicRough = brightMask & positionMask
 ↓
步骤4：形态学连接
 ├─ 闭运算（半径40）→ 连接管子
 ├─ 填充孔洞
 └─ 开运算（半径15）→ 去噪声
 ↓
步骤5：保留最大区域
 └─ 面积 > 20%图像
 ↓
输出：ROI掩码
```

### 为什么使用保守策略？

**宁可多检测（false positive），不要漏检（false negative）**

理由：
1. 漏检管子 = 丢失缺陷信息（严重）
2. 多检测一些边缘 = 缺陷率略高（可接受）
3. 后续的Otsu分割会进一步筛选真实缺陷

## 📚 参考

- [CURRENT_PROBLEM_ANALYSIS.md](../../CURRENT_PROBLEM_ANALYSIS.md) - 问题分析
- [IMAGE_ANALYSIS_AND_SOLUTION.md](../../IMAGE_ANALYSIS_AND_SOLUTION.md) - 解决方案设计

## 🚦 下一步

1. **立即测试**：运行`test_roi_detection`
2. **验证ROI**：确认覆盖所有管子
3. **运行检测**：`auto_run`处理样本
4. **查看结果**：`quick_view`验证效果
5. **调整参数**：根据效果微调

