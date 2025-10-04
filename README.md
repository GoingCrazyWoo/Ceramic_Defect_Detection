# 陶瓷缺陷检测系统

基于传统图像处理方法的陶瓷表面缺陷检测系统，使用 MATLAB 实现。

## 项目简介

本项目实现了完整的陶瓷缺陷检测流程，包括：
- CLAHE 对比度增强
- 全局/局部 Otsu 二值化分割
- 多种边缘检测方法（Canny、Sobel、LoG）
- 基于霍夫变换的直线和圆形缺陷检测

## 核心文件说明

### 算法核心（3个文件）
1. **`ceramic_defect_pipeline.m`** - 核心检测流程
2. **`ceramic_default_options.m`** - 默认参数配置
3. **`ceramic_toolkit.m`** - 统一工具包

### 数据处理（3个文件）
4. **`ceramic_results_summary.m`** - 结果汇总
5. **`ceramic_performance_metrics.m`** - 性能指标计算
6. **`ceramic_unified_schema.m`** - 统一数据模式

### 辅助工具（2个文件）
7. **`auto_run.m`** - 一键自动运行脚本
8. **`collect_sample_images.m`** - 样本图片收集

## 快速开始

### 方式1：一键运行（推荐）

1. 将测试图片放入 `samples/` 目录
2. 在 MATLAB 中切换到 `matlab/` 目录
3. 运行自动脚本：

```matlab
auto_run
```

程序将自动：
- ✅ 收集样本图片
- ✅ 初始化工具包
- ✅ 批量处理所有图片
- ✅ 生成 CSV 汇总报告
- ✅ 保存详细检测结果

所有结果保存在 `run_yyyymmdd_HHMMSS/` 目录中。

### 方式2：手动使用工具包

```matlab
% 初始化工具包
toolkit = ceramic_toolkit();

% 可视化演示（弹出文件选择框）
toolkit.runDemo();

% 或直接指定图片
toolkit.runDemo('samples/20250929_defect_01.jpg');

% 批量处理
toolkit.batchProcess('*.jpg');
```

### 方式3：直接调用检测流程

```matlab
% 使用默认参数
results = ceramic_defect_pipeline('samples/test.jpg');

% 使用自定义参数
opts = struct('ClipLimit', 0.02, 'NumTiles', [10 10]);
results = ceramic_defect_pipeline('samples/test.jpg', opts);
```

## 参数说明

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| ClipLimit | 0.015 | CLAHE 对比度限制强度 |
| NumTiles | [8 8] | CLAHE 分块数量 |
| LocalBlockSize | [64 64] | 局部 Otsu 计算窗口 |
| MorphOpenRadius | 2 | 形态学开运算半径 |
| LineFillGap | 10 | 霍夫直线间隙填充 |
| LineMinLength | 30 | 最小直线长度 |
| CircleRadius | [6 40] | 圆形缺陷半径范围 |
| CircleSensitivity | 0.9 | 圆形检测灵敏度 |

### 参数调整建议

根据检测结果调整 `matlab/ceramic_default_options.m` 中的参数：

| 问题 | 调整方法 |
|------|----------|
| 缺陷覆盖率过高（>50%） | 增大 `LocalBlockSize`（如改为 [256 256]） |
| 检测到过多圆形（>200个） | 降低 `CircleSensitivity`（如改为 0.85） |
| 图像对比度低 | 提高 `ClipLimit`（如改为 0.02） |
| 大尺寸图像（>4000px） | 增大 `LocalBlockSize` 和 `NumTiles` |

## 输出结果说明

检测结果包含以下数据：

- **original** - 原始灰度图像
- **enhanced** - CLAHE + 双边滤波增强图像
- **binaryGlobal** - 全局 Otsu 二值化结果
- **binaryLocal** - 局部 Otsu 二值化结果
- **edgeMaps** - 边缘检测结果（Sobel/Canny/LoG）
- **houghLines** - 霍夫直线检测信息
- **circles** - 圆形缺陷检测信息

## 批量处理输出

运行 `auto_run` 后，会在 `matlab/run_yyyymmdd_HHMMSS/results/` 目录下生成：

- `batch_summary_*.csv` - CSV汇总报告
- `results_*.mat` - 每张图片的详细检测结果

**CSV 报告包含：**
- 文件名、缺陷覆盖率、直线数量、圆形数量、质量评分

**结果管理：**
- 运行结果会自动保存，不会覆盖之前的结果
- 可以定期删除旧的 `run_*` 目录节省空间
- `.gitignore` 已配置忽略运行结果，不会提交到版本库

## 项目结构

```
Ceramic_Defect_Detection/
├── samples/                            # 测试图片目录
│   ├── 20250929_defect_01.jpg
│   └── README.md
│
├── matlab/                             # 核心代码
│   ├── auto_run.m                      # 一键运行脚本
│   ├── ceramic_defect_pipeline.m       # 核心检测流程
│   ├── ceramic_toolkit.m               # 工具包（演示+批处理）
│   ├── ceramic_default_options.m       # 参数配置（当前：v2.1）
│   ├── ceramic_results_summary.m       # 结果汇总
│   ├── ceramic_performance_metrics.m   # 性能指标
│   ├── ceramic_unified_schema.m        # 统一数据模式
│   ├── collect_sample_images.m         # 样本收集
│   ├── create_version.m                # 版本管理工具
│   │
│   └── run_*/                          # 运行结果（自动生成，已忽略）
│       └── results/
│
├── versions/                           # 版本历史（重要！）
│   ├── README.md                       # 版本管理说明
│   ├── CHANGELOG.md                    # 更新日志
│   ├── v2.0_baseline/                  # v2.0基线版本
│   │   ├── VERSION_INFO.md             # 版本详细说明
│   │   ├── code/                       # 代码快照
│   │   └── run_results/                # 检测结果
│   │
│   └── v2.1_large_image_optimization/  # v2.1优化版本
│       ├── VERSION_INFO.md
│       └── code/
│
├── README.md                           # 项目文档
└── .gitignore                          # Git忽略配置
```

## 使用建议

### 样本准备
- 图像分辨率建议在 500×500 至 2000×2000 像素之间
- 拍摄时避免强烈阴影，确保缺陷边缘清晰
- 可涵盖传统缺陷类型：裂纹、气泡、污点、划痕等

### 参数调整建议
- 高噪声图像：增大 `MorphOpenRadius`，降低 `ClipLimit`
- 低对比度图像：增大 `ClipLimit`，调整 `NumTiles`
- 细小裂纹：降低 `LineMinLength`
- 小气泡检测：调整 `CircleRadius` 下限

## 版本管理

### 当前版本
**v2.1** - 大图像优化版本（已针对6000×8000图像优化参数）

### 查看版本历史
```matlab
% 查看所有版本
dir ../versions/

% 查看版本更新日志
edit ../versions/CHANGELOG.md
```

### 创建新版本
当你调整参数后，可以保存为新版本：

```matlab
cd matlab
create_version('v2.2_my_update', '我的优化说明');
```

### 回滚到历史版本
如果新参数效果不好，可以恢复旧版本：

```matlab
% 恢复到v2.0
copyfile('../versions/v2.0_baseline/code/ceramic_default_options.m', 'ceramic_default_options.m');
```

详细版本管理说明：[versions/README.md](versions/README.md)

## 许可证

本项目仅供学习和研究使用。

## 系统要求

- MATLAB R2019b 或更高版本
- Image Processing Toolbox
