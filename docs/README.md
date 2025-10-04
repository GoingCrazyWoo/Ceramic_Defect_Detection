# 陶瓷缺陷检测系统 - 文档中心

## 📚 文档列表

### 主要文档

- **[V3.0-R6_FINAL_GUIDE.md](V3.0-R6_FINAL_GUIDE.md)** - v3.0-R6最终使用指南（推荐阅读）
  - 快速开始
  - 参数调整
  - 高级用法
  - 常见问题

### 版本文档

详细的版本演进和技术细节请查看:
- `../versions/CHANGELOG.md` - 完整版本历史
- `../versions/v3.0_roi_detection/` - v3.0版本详细文档

### 技术文档

历史技术文档（已归档）:
- CRITICAL_FIXES.md
- OPTIMIZATION_SUMMARY.md
- PATH_FIX_SUMMARY.md
- FINAL_DEDUPLICATION.md

---

## 🚀 快速开始

### 运行批量检测

```matlab
cd matlab
matlab -batch "auto_run"
```

### 生成可视化图片

```matlab
cd matlab
matlab -batch "batch_visualize_results()"
```

### 查看结果

```matlab
cd matlab
matlab
>> view_single_result('defect_01')
```

---

## 📊 系统特性

### v3.0-R6 核心功能

1. ✅ **ROI自动检测** - 精确识别陶瓷管区域
2. ✅ **不规则缺陷检测** - 全面检测所有类型缺陷
3. ✅ **自动分类** - 4种缺陷类型（圆形、线状、空心、不规则）
4. ✅ **高质量可视化** - 彩色标注、详细统计
5. ✅ **批量处理** - 快速处理多张图片（~30秒/图）

### 检测结果

- **平均缺陷率**: 1.76%（相对ROI）
- **平均检测数**: 19.5个缺陷/图
- **质量评分**: 56.5/100
- **ROI覆盖率**: 36.1%（精确管子区域）

---

## 🎨 可视化效果

每张检测结果包含6个子图:

1. 原始图像 + ROI边界（青色）
2. CLAHE增强图
3. ROI区域叠加
4. 缺陷掩码（二值图）
5. **缺陷分类标注**（彩色边界）
   - 🟢 绿色：圆形孔洞
   - 🔴 红色：线状裂纹
   - 🟡 黄色：空心缺陷
   - 🟣 洋红：不规则污渍
6. 统计信息文本

---

## 📞 技术支持

如有问题或建议，请参考:
- 使用指南: `V3.0-R6_FINAL_GUIDE.md`
- 版本历史: `../versions/CHANGELOG.md`
- 项目主页: `../README.md`

---

**最后更新**: 2025-10-04  
**当前版本**: v3.0-R6（生产就绪）
