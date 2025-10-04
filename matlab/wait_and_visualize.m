% WAIT_AND_VISUALIZE - 等待批量检测完成并自动生成可视化
%
% 用法: wait_and_visualize()

function wait_and_visualize()
    fprintf('===== 等待批量检测完成 =====\n\n');
    
    % 查找最新的run目录
    runDirs = dir('run_*');
    runDirs = runDirs([runDirs.isdir]);
    [~, idx] = max([runDirs.datenum]);
    latestRun = runDirs(idx).name;
    
    fprintf('监控目录: %s\n', latestRun);
    fprintf('等待4个MAT文件生成...\n\n');
    
    % 等待检测完成
    maxWaitTime = 300;  % 最多等待5分钟
    startTime = tic;
    lastCount = 0;
    
    while toc(startTime) < maxWaitTime
        % 检查MAT文件数量
        matFiles = dir(fullfile(latestRun, 'results', 'results_*.mat'));
        currentCount = length(matFiles);
        
        if currentCount ~= lastCount
            fprintf('[%s] 进度: %d/4 个文件完成\n', datestr(now, 'HH:MM:SS'), currentCount);
            lastCount = currentCount;
        end
        
        if currentCount >= 4
            fprintf('\n✓ 批量检测完成！\n\n');
            break;
        end
        
        pause(2);  % 每2秒检查一次
    end
    
    if lastCount < 4
        fprintf('\n⚠ 超时：%d分钟内未完成\n', maxWaitTime/60);
        fprintf('当前进度: %d/4\n', lastCount);
        return;
    end
    
    % 验证字段
    fprintf('===== 验证结果字段 =====\n');
    matFile = fullfile(latestRun, 'results', matFiles(1).name);
    data = load(matFile);
    
    requiredFields = {'binaryGlobalClean', 'irregularDefects', 'roiMask'};
    allPresent = true;
    
    for i = 1:length(requiredFields)
        if isfield(data.results, requiredFields{i})
            fprintf('  ✓ %s 字段存在\n', requiredFields{i});
        else
            fprintf('  ✗ %s 字段缺失\n', requiredFields{i});
            allPresent = false;
        end
    end
    
    if ~allPresent
        fprintf('\n⚠ 字段验证失败，可能需要重新检测\n');
        return;
    end
    
    % 生成可视化
    fprintf('\n===== 生成可视化图片 =====\n');
    try
        batch_visualize_results(latestRun);
        fprintf('\n✓ 可视化完成！\n');
        
        % 打开可视化目录
        visDir = fullfile(latestRun, 'visualizations');
        if exist(visDir, 'dir')
            fprintf('\n打开可视化目录...\n');
            if ispc
                winopen(visDir);
            end
        end
    catch ME
        fprintf('\n✗ 可视化失败: %s\n', ME.message);
    end
    
    fprintf('\n===== 全部完成 =====\n');
end

