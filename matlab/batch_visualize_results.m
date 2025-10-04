% BATCH_VISUALIZE_RESULTS - 批量生成检测结果可视化图片
%
% 用法: 
%   1. 直接运行此脚本（处理最新的run_*目录）
%   2. 或指定目录: batch_visualize_results('run_20251004_121634')
%
% v3.0-R6 专用

function batch_visualize_results(runDir)
    fprintf('===== 批量生成可视化图片 =====\n\n');
    
    %% 确定运行目录
    if nargin < 1 || isempty(runDir)
        % 自动找最新的run_*目录
        runDirs = dir('run_*');
        runDirs = runDirs([runDirs.isdir]);
        if isempty(runDirs)
            error('未找到任何run_*目录');
        end
        % 按时间排序，取最新的
        [~, idx] = max([runDirs.datenum]);
        runDir = runDirs(idx).name;
        fprintf('自动选择最新目录: %s\n\n', runDir);
    end
    
    %% 检查目录
    resultsDir = fullfile(runDir, 'results');
    if ~exist(resultsDir, 'dir')
        error('结果目录不存在: %s', resultsDir);
    end
    
    %% 创建可视化输出目录
    visDir = fullfile(runDir, 'visualizations');
    if ~exist(visDir, 'dir')
        mkdir(visDir);
        fprintf('创建可视化目录: %s\n', visDir);
    end
    
    %% 查找所有.mat结果文件
    matFiles = dir(fullfile(resultsDir, 'results_*.mat'));
    fprintf('找到 %d 个结果文件\n\n', length(matFiles));
    
    if isempty(matFiles)
        error('未找到任何results_*.mat文件');
    end
    
    %% 批量处理
    for i = 1:length(matFiles)
        matFile = matFiles(i).name;
        fprintf('处理 %d/%d: %s\n', i, length(matFiles), matFile);
        
        % 提取图片文件名（去掉results_前缀和.mat后缀）
        imgBaseName = strrep(matFile, 'results_', '');
        imgBaseName = strrep(imgBaseName, '.mat', '');
        
        % 查找原始图片
        imgPath = fullfile('..', 'samples', [imgBaseName '.jpg']);
        if ~exist(imgPath, 'file')
            imgPath = fullfile('..', 'samples', [imgBaseName '.png']);
            if ~exist(imgPath, 'file')
                fprintf('  ⚠ 跳过: 找不到原始图片 %s\n', imgBaseName);
                continue;
            end
        end
        
        % 加载结果
        matPath = fullfile(resultsDir, matFile);
        data = load(matPath);
        results = data.results;
        
        % 生成可视化
        visPath = fullfile(visDir, [imgBaseName '_visualization.png']);
        try
            visualize_irregular_defects(imgPath, results, visPath);
            fprintf('  ✓ 已生成: %s\n', visPath);
        catch ME
            fprintf('  ✗ 失败: %s\n', ME.message);
        end
        fprintf('\n');
    end
    
    %% 完成
    fprintf('===== 批量可视化完成 =====\n');
    fprintf('输出目录: %s\n', visDir);
    fprintf('生成图片: %d张\n', length(dir(fullfile(visDir, '*_visualization.png'))));
    
    % 自动打开目录（Windows）
    if ispc
        winopen(visDir);
    end
end

