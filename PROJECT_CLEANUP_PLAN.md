# 项目清理计划

## 📊 当前项目结构分析

### ✅ 核心文件（必须保留）

#### MATLAB核心代码
1. **`matlab/auto_run.m`** - 主运行脚本 ✅
2. **`matlab/ceramic_defect_pipeline.m`** - 核心检测pipeline（v3.0） ✅
3. **`matlab/detect_ceramic_roi.m`** - ROI检测（v3.0新增） ✅
4. **`matlab/ceramic_default_options.m`** - 参数配置 ✅
5. **`matlab/ceramic_performance_metrics.m`** - 性能指标 ✅
6. **`matlab/ceramic_results_summary.m`** - 结果汇总 ✅
7. **`matlab/ceramic_unified_schema.m`** - 统一数据结构 ✅
8. **`matlab/ceramic_toolkit.m`** - 工具包 ✅
9. **`matlab/collect_sample_images.m`** - 样本收集 ✅

#### 可视化工具
10. **`matlab/view_results.m`** - 查看结果 ✅
11. **`matlab/quick_view.m`** - 快速查看 ✅

#### 版本管理
12. **`matlab/create_version.m`** - 版本创建工具 ✅
13. **`versions/`** - 版本历史记录 ✅

#### 文档
14. **`README.md`** - 主文档 ✅
15. **`samples/README.md`** - 样本说明 ✅

### ⚠️ 调试/测试文件（可以清理或归档）

#### 临时测试脚本
- **`matlab/test_roi_detection.m`** - ROI测试 🟡
- **`matlab/test_roi_threshold.m`** - 阈值测试 🟡
- **`matlab/visualize_roi_detail.m`** - ROI详细可视化 🟡

**建议：** 保留，但移动到 `matlab/tools/` 子目录

#### 临时文档
- **`matlab/QUICK_FIX_GUIDE.md`** - 快速修复指南 🟡
- **`matlab/README_v3.0.md`** - v3.0说明 🟡
- **`matlab/UPDATED_FIX.md`** - 更新修复说明 🟡
- **`CURRENT_PROBLEM_ANALYSIS.md`** - 问题分析 🟡
- **`IMAGE_ANALYSIS_AND_SOLUTION.md`** - 图像分析 🟡

**建议：** 合并到一个文档，或移动到 `docs/archive/`

### ❌ 可以删除的内容

#### 旧的运行结果
- **`matlab/run_20251002_230704/`** - v2.2结果 ❌
- **`matlab/run_20251003_180009/`** - v3.0测试结果 ❌

**建议：** 删除或移动到 `versions/` 对应版本下

## 🎯 清理后的理想结构

```
Ceramic_Defect_Detection/
│
├── README.md                          # 主文档
├── .gitignore
│
├── matlab/                            # MATLAB代码
│   ├── auto_run.m                    # 主运行脚本
│   ├── ceramic_defect_pipeline.m     # 核心pipeline
│   ├── detect_ceramic_roi.m          # ROI检测（v3.0）
│   ├── ceramic_default_options.m     # 参数配置
│   ├── ceramic_performance_metrics.m
│   ├── ceramic_results_summary.m
│   ├── ceramic_unified_schema.m
│   ├── ceramic_toolkit.m
│   ├── collect_sample_images.m
│   ├── view_results.m
│   ├── quick_view.m
│   ├── create_version.m
│   │
│   ├── tools/                        # 测试和调试工具
│   │   ├── test_roi_detection.m
│   │   ├── test_roi_threshold.m
│   │   └── visualize_roi_detail.m
│   │
│   └── README.md                     # MATLAB代码说明
│
├── samples/                          # 样本图像
│   ├── 20250929_defect_01.jpg
│   ├── 20250929_defect_02.jpg
│   ├── 20250929_defect_03.jpg
│   ├── 20250929_defect_04.jpg
│   └── README.md
│
├── versions/                         # 版本历史
│   ├── README.md
│   ├── CHANGELOG.md
│   ├── v2.0_baseline/
│   ├── v2.1_large_image_optimization/
│   ├── v2.2_continued_optimization/
│   └── v3.0_roi_detection/           # 新增v3.0记录
│       ├── VERSION_INFO.md
│       ├── code/
│       │   ├── ceramic_default_options.m
│       │   └── detect_ceramic_roi.m
│       ├── run_results/
│       └── docs/
│           ├── PROBLEM_ANALYSIS.md   # 合并的问题分析
│           └── SOLUTION_DESIGN.md    # 合并的解决方案
│
└── docs/                             # 文档（新建）
    ├── DEVELOPMENT_HISTORY.md        # 开发历史
    ├── PARAMETER_TUNING_GUIDE.md     # 参数调整指南
    └── TROUBLESHOOTING.md            # 故障排除
```

## 📝 具体清理步骤

### 步骤1：创建目录结构
```bash
mkdir matlab/tools
mkdir docs
mkdir versions/v3.0_roi_detection
mkdir versions/v3.0_roi_detection/code
mkdir versions/v3.0_roi_detection/docs
```

### 步骤2：移动测试工具
```bash
mv matlab/test_roi_detection.m matlab/tools/
mv matlab/test_roi_threshold.m matlab/tools/
mv matlab/visualize_roi_detail.m matlab/tools/
```

### 步骤3：整理文档
```bash
# 合并临时文档到一个文件
# CURRENT_PROBLEM_ANALYSIS.md + IMAGE_ANALYSIS_AND_SOLUTION.md 
# → versions/v3.0_roi_detection/docs/PROBLEM_ANALYSIS.md

# QUICK_FIX_GUIDE.md + UPDATED_FIX.md + README_v3.0.md
# → versions/v3.0_roi_detection/docs/SOLUTION_GUIDE.md
```

### 步骤4：删除旧运行结果
```bash
rm -rf matlab/run_20251002_230704
rm -rf matlab/run_20251003_180009
```

### 步骤5：更新.gitignore
```
# 运行结果（所有run_*目录）
matlab/run_*/

# MATLAB临时文件
*.asv
*.m~
```

### 步骤6：创建v3.0版本记录
复制当前代码和文档到 `versions/v3.0_roi_detection/`

## 📊 清理效果对比

| 项目 | 清理前 | 清理后 | 变化 |
|------|--------|--------|------|
| **根目录文件数** | 3个 | 2个 | -1 |
| **matlab/文件数** | 17个 | 14个 | -3 |
| **临时文档** | 5个 | 0个 | -5 ✅ |
| **运行结果目录** | 2个 | 0个 | -2 ✅ |
| **文档组织** | 分散 | 集中 | ✅ |

## ✅ 清理后的优势

1. **结构清晰** - 核心代码、工具、文档分离
2. **易于维护** - 临时文件归档，不干扰主代码
3. **版本追溯** - v3.0完整记录在versions/中
4. **减少体积** - 删除重复的运行结果
5. **便于协作** - 新用户能快速找到需要的文件

## 🚀 执行清理？

**选项A：自动清理（推荐）**
我创建一个清理脚本，一键执行所有步骤

**选项B：手动清理**
按照上述步骤逐步执行

**选项C：部分清理**
只执行某些步骤（如删除旧运行结果）

你想执行哪个选项？

