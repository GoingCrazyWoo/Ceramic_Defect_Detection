%% 查看检测结果的可视化脚本
% 用于加载和显示保存的.mat结果文件

function view_results(resultsMatFile)
%VIEW_RESULTS 可视化保存的检测结果
%   VIEW_RESULTS(RESULTSMATFILE) 加载.mat文件并显示所有检测结果
%
%   示例：
%       view_results('matlab/run_20251003_180009/results/results_20250929_defect_01.mat')
%
%   或者在MATLAB中：
%       cd matlab
%       view_results('run_20251003_180009/results/results_20250929_defect_01.mat')

    if nargin < 1
        % 如果没有提供文件，让用户选择
        [fileName, folder] = uigetfile('*.mat', '请选择结果文件');
        if isequal(fileName, 0)
            fprintf('已取消。\n');
            return;
        end
        resultsMatFile = fullfile(folder, fileName);
    end
    
    % 加载结果
    fprintf('加载结果文件: %s\n', resultsMatFile);
    data = load(resultsMatFile);
    results = data.results;
    
    % 生成统计摘要
    summary = ceramic_results_summary(results);
    perf = ceramic_performance_metrics(results);
    
    % 打印统计信息
    fprintf('\n========== 检测结果统计 ==========\n');
    fprintf('图像尺寸: %d × %d\n', summary.imageSize(1), summary.imageSize(2));
    fprintf('缺陷覆盖率（局部Otsu）: %.2f%%\n', perf.defectCoverage.local);
    fprintf('缺陷覆盖率（全局Otsu）: %.2f%%\n', perf.defectCoverage.global);
    fprintf('检测直线数: %d\n', summary.lineDetection.count);
    fprintf('检测圆形数: %d\n', summary.circleDetection.count);
    fprintf('质量评分: %.2f/100\n', perf.qualityScore);
    fprintf('对比度改善: %.2f%%\n', perf.contrastImprovement);
    fprintf('==================================\n\n');
    
    % 创建可视化图形窗口
    
    % 图1：主要处理流程
    figure('Name', '陶瓷缺陷检测流程 - v2.2结果', 'Position', [100, 100, 1400, 800]);
    
    subplot(2,3,1);
    imshow(results.original);
    title('1. 原始灰度图', 'FontSize', 12);
    
    subplot(2,3,2);
    imshow(results.enhanced);
    title('2. CLAHE增强', 'FontSize', 12);
    
    subplot(2,3,3);
    imshow(results.binaryGlobal);
    title(sprintf('3. 全局Otsu (%.2f%%)', perf.defectCoverage.global), 'FontSize', 12);
    
    subplot(2,3,4);
    imshow(results.binaryLocal);
    title(sprintf('4. 局部Otsu (%.2f%%)', perf.defectCoverage.local), 'FontSize', 12);
    
    subplot(2,3,5);
    imshow(results.edgeMaps.canny);
    title('5. Canny边缘检测', 'FontSize', 12);
    
    subplot(2,3,6);
    imshow(results.edgeMaps.sobel);
    title('6. Sobel边缘检测', 'FontSize', 12);
    
    % 图2：霍夫直线检测结果
    if ~isempty(results.houghLines.lines)
        figure('Name', sprintf('霍夫直线检测 - 共%d条', summary.lineDetection.count), ...
               'Position', [150, 150, 800, 600]);
        imshow(results.original); hold on;
        
        % 绘制所有检测到的直线
        for k = 1:numel(results.houghLines.lines)
            xy = [results.houghLines.lines(k).point1; 
                  results.houghLines.lines(k).point2];
            plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', 'cyan');
        end
        hold off;
        title(sprintf('检测到 %d 条直线（青色）', summary.lineDetection.count), 'FontSize', 14);
    else
        fprintf('未检测到直线\n');
    end
    
    % 图3：圆形检测结果
    if ~isempty(results.circles.centers)
        figure('Name', sprintf('圆形缺陷检测 - 共%d个', summary.circleDetection.count), ...
               'Position', [200, 200, 800, 600]);
        imshow(results.enhanced); hold on;
        
        % 绘制所有检测到的圆形
        viscircles(results.circles.centers, results.circles.radii, ...
                   'Color', 'r', 'LineWidth', 1.5);
        hold off;
        title(sprintf('检测到 %d 个圆形（红色）', summary.circleDetection.count), 'FontSize', 14);
        
        % 显示圆形统计
        fprintf('圆形统计:\n');
        fprintf('  - 平均半径: %.1f px\n', summary.circleDetection.avgRadius);
        fprintf('  - 半径范围: %.1f - %.1f px\n', ...
                summary.circleDetection.minRadius, summary.circleDetection.maxRadius);
    else
        fprintf('未检测到圆形\n');
    end
    
    % 图4：对比图（全局 vs 局部 Otsu）
    figure('Name', '全局Otsu vs 局部Otsu对比', 'Position', [250, 250, 1200, 400]);
    
    subplot(1,3,1);
    imshow(results.original);
    title('原始图像', 'FontSize', 12);
    
    subplot(1,3,2);
    imshow(results.binaryGlobal);
    title(sprintf('全局Otsu\n缺陷率: %.2f%%', perf.defectCoverage.global), 'FontSize', 12);
    xlabel(sprintf('缺陷区域数: %d', summary.defectRegions.global.count), 'FontSize', 10);
    
    subplot(1,3,3);
    imshow(results.binaryLocal);
    title(sprintf('局部Otsu (v2.2)\n缺陷率: %.2f%%', perf.defectCoverage.local), 'FontSize', 12);
    xlabel(sprintf('缺陷区域数: %d', summary.defectRegions.local.count), 'FontSize', 10);
    
    % 图5：综合检测结果叠加
    figure('Name', '综合检测结果 - v2.2', 'Position', [300, 300, 900, 700]);
    imshow(results.enhanced); hold on;
    
    % 叠加直线检测
    if ~isempty(results.houghLines.lines)
        for k = 1:numel(results.houghLines.lines)
            xy = [results.houghLines.lines(k).point1; 
                  results.houghLines.lines(k).point2];
            plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', 'cyan');
        end
    end
    
    % 叠加圆形检测
    if ~isempty(results.circles.centers)
        viscircles(results.circles.centers, results.circles.radii, ...
                   'Color', 'r', 'LineWidth', 1.5);
    end
    
    hold off;
    title(sprintf('综合检测结果\n直线: %d条 | 圆形: %d个 | 质量分: %.1f', ...
                  summary.lineDetection.count, summary.circleDetection.count, ...
                  perf.qualityScore), 'FontSize', 14);
    
    fprintf('\n已生成所有可视化图形！\n');
    fprintf('提示：你可以使用MATLAB的图形工具栏保存图片\n');
end

