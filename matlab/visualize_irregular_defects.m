function visualize_irregular_defects(imagePath, results, savePath)
% VISUALIZE_IRREGULAR_DEFECTS 可视化不规则缺陷检测结果
%
% 输入参数:
%   imagePath - 原始图像路径
%   results   - ceramic_defect_pipeline的结果结构体
%   savePath  - 可视化图片保存路径（可选）
%
% v3.0-R6 专用可视化

    %% 读取原始图像
    if ischar(imagePath)
        img = imread(imagePath);
    else
        img = imagePath;
    end
    
    % 转为灰度图（如果是彩色）
    if size(img, 3) == 3
        grayImg = rgb2gray(img);
    else
        grayImg = img;
    end
    
    %% 创建可视化图形
    fig = figure('Position', [100, 100, 1800, 900], 'Visible', 'off');
    
    % 设置中文字体支持
    set(groot, 'defaultAxesFontName', 'Microsoft YaHei');
    set(groot, 'defaultTextFontName', 'Microsoft YaHei');
    
    % 定义颜色方案
    colors = struct(...
        'circular', [0, 1, 0], ...      % 绿色 - 圆形孔洞
        'linear', [1, 0, 0], ...        % 红色 - 线状裂纹
        'hollow', [1, 1, 0], ...        % 黄色 - 空心缺陷
        'irregular', [1, 0, 1]);        % 洋红 - 不规则污渍
    
    %% 子图1: 原始图像 + ROI
    subplot(2, 3, 1);
    imshow(img);
    title('原始图像', 'FontSize', 12, 'FontName', 'Microsoft YaHei');
    if isfield(results, 'roiMask') && ~isempty(results.roiMask)
        hold on;
        % 绘制ROI边界
        boundaries = bwboundaries(results.roiMask);
        for k = 1:length(boundaries)
            boundary = boundaries{k};
            plot(boundary(:,2), boundary(:,1), 'c-', 'LineWidth', 2);
        end
        hold off;
    end
    
    %% 子图2: 增强图像
    subplot(2, 3, 2);
    imshow(results.enhanced);
    title('CLAHE增强', 'FontSize', 12, 'FontName', 'Microsoft YaHei');
    
    %% 子图3: ROI区域
    subplot(2, 3, 3);
    if isfield(results, 'roiMask') && ~isempty(results.roiMask)
        roiOverlay = imoverlay(mat2gray(grayImg), results.roiMask, [0, 1, 1]);
        imshow(roiOverlay);
        title(sprintf('ROI检测 (%.1f%%)', sum(results.roiMask(:))/numel(results.roiMask)*100), 'FontSize', 12, 'FontName', 'Microsoft YaHei');
    else
        imshow(grayImg);
        title('无ROI', 'FontSize', 12, 'FontName', 'Microsoft YaHei');
    end
    
    %% 子图4: 缺陷掩码
    subplot(2, 3, 4);
    if isfield(results, 'binaryGlobalClean') && ~isempty(results.binaryGlobalClean)
        imshow(results.binaryGlobalClean);
        title('缺陷掩码（二值化）', 'FontSize', 12, 'FontName', 'Microsoft YaHei');
    else
        imshow(grayImg);
        title('无缺陷掩码', 'FontSize', 12, 'FontName', 'Microsoft YaHei');
    end
    
    %% 子图5: 不规则缺陷分类标注（彩色）
    subplot(2, 3, 5);
    imshow(img);
    title('缺陷分类标注', 'FontSize', 12, 'FontName', 'Microsoft YaHei');
    hold on;
    
    if isfield(results, 'irregularDefects') && results.irregularDefects.count > 0
        defects = results.irregularDefects.defects;
        for i = 1:length(defects)
            d = defects(i);
            color = colors.(d.type);
            
            % 绘制边界
            plot(d.boundary(:,2), d.boundary(:,1), 'Color', color, 'LineWidth', 2);
            
            % 标注编号
            text(d.centroid(1), d.centroid(2), sprintf('%d', i), ...
                'Color', 'white', 'FontSize', 10, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'BackgroundColor', [0 0 0 0.5]);
        end
    end
    hold off;
    
    % 添加图例
    legend_entries = {};
    if isfield(results, 'irregularDefects')
        if results.irregularDefects.circularCount > 0
            legend_entries{end+1} = sprintf('圆形孔洞 (%d)', results.irregularDefects.circularCount);
        end
        if results.irregularDefects.linearCount > 0
            legend_entries{end+1} = sprintf('线状裂纹 (%d)', results.irregularDefects.linearCount);
        end
        if results.irregularDefects.hollowCount > 0
            legend_entries{end+1} = sprintf('空心缺陷 (%d)', results.irregularDefects.hollowCount);
        end
        if results.irregularDefects.irregularCount > 0
            legend_entries{end+1} = sprintf('不规则污渍 (%d)', results.irregularDefects.irregularCount);
        end
    end
    if ~isempty(legend_entries)
        legend(legend_entries, 'Location', 'northeast', 'FontSize', 9, 'FontName', 'Microsoft YaHei');
    end
    
    %% 子图6: 统计信息
    subplot(2, 3, 6);
    axis off;
    
    % 准备统计文本
    statsText = {};
    statsText{end+1} = '=== 检测统计 ===';
    statsText{end+1} = '';
    
    if isfield(results, 'irregularDefects')
        d = results.irregularDefects;
        statsText{end+1} = sprintf('总缺陷数: %d个', d.count);
        statsText{end+1} = '';
        statsText{end+1} = '【分类统计】';
        statsText{end+1} = sprintf('  圆形孔洞: %d个', d.circularCount);
        statsText{end+1} = sprintf('  线状裂纹: %d个', d.linearCount);
        statsText{end+1} = sprintf('  空心缺陷: %d个', d.hollowCount);
        statsText{end+1} = sprintf('  不规则污渍: %d个', d.irregularCount);
        statsText{end+1} = '';
        statsText{end+1} = '【面积统计】';
        statsText{end+1} = sprintf('  总面积: %d像素', round(d.totalArea));
        statsText{end+1} = sprintf('  平均面积: %.1f像素', d.avgArea);
        
        if d.count > 0
            statsText{end+1} = '';
            statsText{end+1} = '【前5大缺陷】';
            for i = 1:min(5, length(d.defects))
                df = d.defects(i);
                statsText{end+1} = sprintf('%d. %d像素 [%s]', i, round(df.area), df.type);
            end
        end
    else
        statsText{end+1} = '未检测到不规则缺陷';
    end
    
    if isfield(results, 'metrics')
        statsText{end+1} = '';
        statsText{end+1} = '【质量指标】';
        statsText{end+1} = sprintf('  缺陷率: %.2f%%', results.metrics.defectCoverage * 100);
        statsText{end+1} = sprintf('  质量分: %.1f', results.metrics.qualityScore);
    end
    
    % 显示文本
    text(0.1, 0.95, strjoin(statsText, '\n'), ...
        'FontSize', 10, 'FontName', 'Microsoft YaHei', ...
        'VerticalAlignment', 'top', 'Interpreter', 'none');
    
    %% 保存图片
    if nargin >= 3 && ~isempty(savePath)
        % 确保目录存在
        [saveDir, ~, ~] = fileparts(savePath);
        if ~isempty(saveDir) && ~exist(saveDir, 'dir')
            mkdir(saveDir);
        end
        
        % 保存为高分辨率PNG
        print(fig, savePath, '-dpng', '-r150');
        fprintf('已保存可视化图片: %s\n', savePath);
    end
    
    % 关闭图形（如果不需要显示）
    close(fig);
end

