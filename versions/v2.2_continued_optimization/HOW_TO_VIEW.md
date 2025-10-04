# 如何查看v2.2的检测结果图像

## 方法1：快速查看（推荐）⭐⭐⭐⭐⭐

最简单的方式，自动加载最新的运行结果：

```matlab
cd matlab
quick_view
```

这个脚本会：
1. 自动找到最新的`run_*`目录
2. 加载其中的结果文件
3. 显示所有可视化图形

## 方法2：查看特定结果文件

如果你想查看特定的`.mat`文件：

```matlab
cd matlab
view_results('run_20251003_180009/results/results_20250929_defect_01.mat')
```

## 方法3：手动选择文件

在MATLAB中运行：

```matlab
cd matlab
view_results  % 会弹出文件选择对话框
```

## 会显示哪些图像？

运行`view_results`或`quick_view`后，会生成以下5个图形窗口：

### 图1：陶瓷缺陷检测流程
显示完整的6步处理流程：
- 原始灰度图
- CLAHE增强
- 全局Otsu分割
- 局部Otsu分割（v2.2使用的方法）
- Canny边缘检测
- Sobel边缘检测

### 图2：霍夫直线检测
- 在原始图上叠加检测到的直线（青色）
- 标题显示直线数量

### 图3：圆形缺陷检测
- 在增强图上叠加检测到的圆形（红色）
- 标题显示圆形数量

### 图4：全局vs局部Otsu对比
- 并排显示全局和局部Otsu的效果
- 对比两种方法的缺陷覆盖率

### 图5：综合检测结果
- 在同一张图上叠加直线和圆形检测
- 显示完整的检测结果统计

## 查看的数据说明

### v2.2的检测结果位置

```
matlab/
└── run_20251003_180009/          ← v2.2的运行结果
    └── results/
        ├── results_20250929_defect_01.mat      ← 检测结果（包含所有图像）
        └── single_test_20251004_003143.csv     ← 数值统计
```

### `.mat`文件包含的内容

`results`结构体包含：
- `original` - 原始灰度图
- `enhanced` - CLAHE增强后的图像
- `binaryGlobal` - 全局Otsu分割结果
- `binaryLocal` - 局部Otsu分割结果（v2.2参数）
- `edgeMaps` - 边缘检测结果（Canny、Sobel、LoG）
- `houghLines` - 霍夫直线检测数据
- `circles` - 圆形检测数据

## 保存图像

在MATLAB图形窗口中：
1. 点击菜单栏的 **文件 → 另存为**
2. 选择格式（推荐PNG或JPEG）
3. 保存到你想要的位置

或者使用命令：
```matlab
% 保存当前图形
saveas(gcf, 'v2.2_result.png')

% 保存所有打开的图形
h = findall(0, 'type', 'figure');
for i = 1:length(h)
    saveas(h(i), sprintf('v2.2_fig%d.png', i));
end
```

## 对比不同版本的结果

如果你想对比v2.0、v2.1、v2.2的效果：

```matlab
cd matlab

% 加载v2.0结果（如果保存了）
view_results('run_20251002_045555/results/results_20250929_defect_01.mat')

% 加载v2.1结果
view_results('run_20251002_192907/results/results_20250929_defect_01.mat')

% 加载v2.2结果
view_results('run_20251003_180009/results/results_20250929_defect_01.mat')
```

## 常见问题

### Q: 如何查看全局Otsu的缺陷率？
A: 运行`view_results`时，控制台会打印：
```
缺陷覆盖率（全局Otsu）: XX.XX%
```

### Q: 如何放大图像查看细节？
A: 在MATLAB图形窗口中使用放大工具（工具栏的放大镜图标）

### Q: 如何查看具体的参数设置？
A: 查看文件：
```
versions/v2.2_continued_optimization/code/ceramic_default_options.m
```

### Q: 如何重新运行v2.2？
A: 
```matlab
cd matlab
auto_run  % 使用当前的v2.2参数
```

## 脚本说明

### `view_results.m`
- 功能：加载和可视化单个`.mat`结果文件
- 输入：`.mat`文件路径
- 输出：5个图形窗口 + 控制台统计信息

### `quick_view.m`
- 功能：自动找到最新的运行结果并显示
- 输入：无（自动检测）
- 输出：同`view_results.m`

## 技巧

1. **对比v2.1和v2.2**：同时运行两次`view_results`，分别加载两个版本的结果
2. **导出报告**：使用MATLAB的`publish`功能将可视化结果生成HTML报告
3. **批量查看**：修改`quick_view.m`循环显示所有结果文件

## 下一步

查看结果后，如果满意v2.2的效果：
1. 可以修改`auto_run.m`，将`processMode`改为`'all'`
2. 处理全部4张图片
3. 验证平均效果是否一致

