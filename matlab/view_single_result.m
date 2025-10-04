% VIEW_SINGLE_RESULT - 查看单张图片的检测结果
% 用法：view_single_result('defect_01')

function view_single_result(imageName)
    if nargin < 1
        imageName = 'defect_01';
    end
    
    fprintf('===== 查看检测结果: %s =====\n\n', imageName);
    
    % 查找最新的run目录
    runDirs = dir('run_*');
    runDirs = runDirs([runDirs.isdir]);
    [~, idx] = max([runDirs.datenum]);
    runDir = runDirs(idx).name;
    fprintf('使用目录: %s\n', runDir);
    
    % 加载结果 - 自动查找匹配的文件
    % 支持多种文件名格式：results_YYYYMMDD_imageName.mat 或 results_imageName.mat
    resultsDir = fullfile(runDir, 'results');
    
    % 尝试多种文件名模式
    possiblePatterns = {
        sprintf('results_*_%s.mat', imageName),  % results_20250929_defect_01.mat
        sprintf('results_%s.mat', imageName)      % results_defect_01.mat
    };
    
    matFile = '';
    for i = 1:length(possiblePatterns)
        files = dir(fullfile(resultsDir, possiblePatterns{i}));
        if ~isempty(files)
            % 如果有多个匹配，取最新的
            if length(files) > 1
                [~, idx] = max([files.datenum]);
                matFile = fullfile(resultsDir, files(idx).name);
            else
                matFile = fullfile(resultsDir, files(1).name);
            end
            break;
        end
    end
    
    if isempty(matFile)
        error('找不到结果文件，尝试的模式: %s', strjoin(possiblePatterns, ', '));
    end
    
    load(matFile);
    fprintf('已加载结果文件\n\n');
    
    % 显示基本信息
    fprintf('【基本信息】\n');
    fprintf('  ROI覆盖率: %.1f%%\n', sum(results.roiMask(:))/numel(results.roiMask)*100);
    
    if isfield(results, 'irregularDefects')
        d = results.irregularDefects;
        fprintf('  检测到%d个不规则缺陷\n', d.count);
        if isfield(d, 'defects') && ~isempty(d.defects)
            fprintf('    - 圆形孔洞: %d个\n', d.circularCount);
            fprintf('    - 线状裂纹: %d个\n', d.linearCount);
            fprintf('    - 空心缺陷: %d个\n', d.hollowCount);
            fprintf('    - 不规则污渍: %d个\n', d.irregularCount);
            fprintf('    - 总面积: %d像素\n', round(d.totalArea));
            fprintf('    - 平均面积: %.1f像素\n\n', d.avgArea);
            
            fprintf('【前10大缺陷】\n');
            defects = d.defects;
            for i = 1:min(10, length(defects))
                df = defects(i);
                fprintf('  %2d. 面积=%5d 类型=%-10s 圆形度=%.2f 实心度=%.2f\n', ...
                    i, round(df.area), df.type, df.Circularity, df.Solidity);
            end
        else
            fprintf('  ⚠ 结果文件缺少defects字段，请重新运行检测\n');
        end
    else
        fprintf('  ⚠ 未找到irregularDefects字段\n');
    end
    
    % 创建可视化
    fprintf('\n【生成可视化】\n');
    
    % 自动查找原始图片 - 支持多种文件名格式
    samplesDir = fullfile('..', 'samples');
    possibleImgPatterns = {
        sprintf('*_%s.jpg', imageName),      % 20250929_defect_01.jpg
        sprintf('*_%s.png', imageName),      % 20250929_defect_01.png
        sprintf('%s.jpg', imageName),        % defect_01.jpg
        sprintf('%s.png', imageName)         % defect_01.png
    };
    
    imgPath = '';
    for i = 1:length(possibleImgPatterns)
        files = dir(fullfile(samplesDir, possibleImgPatterns{i}));
        if ~isempty(files)
            imgPath = fullfile(samplesDir, files(1).name);
            break;
        end
    end
    
    if ~exist(imgPath, 'file')
        fprintf('  ⚠ 找不到原始图片: %s\n', imgPath);
        return;
    end
    
    img = imread(imgPath);
    
    % 创建图形窗口
    figure('Name', sprintf('检测结果: %s', imageName), 'Position', [100, 100, 1600, 900]);
    
    % 子图1: 原始图像+ROI
    subplot(2, 3, 1);
    imshow(img);
    title('原始图像+ROI边界', 'FontSize', 12);
    hold on;
    boundaries = bwboundaries(results.roiMask);
    for k = 1:length(boundaries)
        boundary = boundaries{k};
        plot(boundary(:,2), boundary(:,1), 'c-', 'LineWidth', 2);
    end
    hold off;
    
    % 子图2: 增强图像
    subplot(2, 3, 2);
    imshow(results.enhanced);
    title('CLAHE增强', 'FontSize', 12);
    
    % 子图3: ROI区域
    subplot(2, 3, 3);
    roiOverlay = imoverlay(mat2gray(rgb2gray(img)), results.roiMask, [0, 1, 1]);
    imshow(roiOverlay);
    title(sprintf('ROI检测 (%.1f%%)', sum(results.roiMask(:))/numel(results.roiMask)*100), 'FontSize', 12);
    
    % 子图4: 缺陷掩码
    subplot(2, 3, 4);
    if isfield(results, 'binaryGlobalClean')
        imshow(results.binaryGlobalClean);
        title('缺陷掩码', 'FontSize', 12);
    end
    
    % 子图5: 缺陷标注
    subplot(2, 3, 5);
    imshow(img);
    title('缺陷分类标注', 'FontSize', 12);
    hold on;
    
    if isfield(results, 'irregularDefects') && isfield(results.irregularDefects, 'defects')
        defects = results.irregularDefects.defects;
        colors = struct('circular', [0, 1, 0], 'linear', [1, 0, 0], ...
            'hollow', [1, 1, 0], 'irregular', [1, 0, 1]);
        
        for i = 1:length(defects)
            d = defects(i);
            color = colors.(d.type);
            plot(d.boundary(:,2), d.boundary(:,1), 'Color', color, 'LineWidth', 2);
            text(d.centroid(1), d.centroid(2), sprintf('%d', i), ...
                'Color', 'white', 'FontSize', 10, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'BackgroundColor', [0 0 0 0.5]);
        end
        
        legend({sprintf('圆形(%d)', d.circularCount), sprintf('线状(%d)', d.linearCount), ...
            sprintf('空心(%d)', d.hollowCount), sprintf('不规则(%d)', d.irregularCount)}, ...
            'Location', 'northeast');
    end
    hold off;
    
    % 子图6: 统计信息
    subplot(2, 3, 6);
    axis off;
    if isfield(results, 'irregularDefects') && isfield(results.irregularDefects, 'defects')
        d = results.irregularDefects;
        statsText = sprintf(['=== 检测统计 ===\n\n' ...
            '总缺陷数: %d个\n\n' ...
            '【分类统计】\n' ...
            '  圆形孔洞: %d个\n' ...
            '  线状裂纹: %d个\n' ...
            '  空心缺陷: %d个\n' ...
            '  不规则污渍: %d个\n\n' ...
            '【面积统计】\n' ...
            '  总面积: %d像素\n' ...
            '  平均面积: %.1f像素\n' ...
            '  最大面积: %d像素'], ...
            d.count, d.circularCount, d.linearCount, d.hollowCount, d.irregularCount, ...
            round(d.totalArea), d.avgArea, round(d.maxArea));
        
        text(0.1, 0.95, statsText, 'FontSize', 10, 'FontName', 'Courier New', ...
            'VerticalAlignment', 'top');
    end
    
    fprintf('  ✓ 可视化完成\n');
end

