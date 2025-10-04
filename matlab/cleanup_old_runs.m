% CLEANUP_OLD_RUNS - 清理旧的run_*目录，保留最新的
%
% 用法:
%   cleanup_old_runs()      % 保留最新1个run目录
%   cleanup_old_runs(2)     % 保留最新2个run目录

function cleanup_old_runs(keepCount)
    if nargin < 1
        keepCount = 1;  % 默认保留最新1个
    end
    
    fprintf('===== 清理旧的run_*目录 =====\n\n');
    
    % 查找所有run_*目录
    runDirs = dir('run_*');
    runDirs = runDirs([runDirs.isdir]);
    
    if isempty(runDirs)
        fprintf('未找到任何run_*目录\n');
        return;
    end
    
    fprintf('找到 %d 个run_*目录\n', length(runDirs));
    
    % 按时间排序（最新的在前）
    [~, idx] = sort([runDirs.datenum], 'descend');
    runDirs = runDirs(idx);
    
    % 显示所有目录
    fprintf('\n目录列表（按时间排序）：\n');
    totalSize = 0;
    for i = 1:length(runDirs)
        dirPath = runDirs(i).name;
        dirSize = getDirSize(dirPath);
        totalSize = totalSize + dirSize;
        
        if i <= keepCount
            fprintf('  [保留] %s (%.1f MB)\n', dirPath, dirSize);
        else
            fprintf('  [删除] %s (%.1f MB)\n', dirPath, dirSize);
        end
    end
    fprintf('\n总大小: %.1f MB\n\n', totalSize);
    
    % 删除旧目录
    if length(runDirs) <= keepCount
        fprintf('所有目录都将保留，无需删除。\n');
        return;
    end
    
    deleteCount = length(runDirs) - keepCount;
    deletedSize = 0;
    
    fprintf('开始删除 %d 个旧目录...\n\n', deleteCount);
    
    for i = (keepCount+1):length(runDirs)
        dirPath = runDirs(i).name;
        dirSize = getDirSize(dirPath);
        
        fprintf('删除: %s (%.1f MB)... ', dirPath, dirSize);
        try
            rmdir(dirPath, 's');
            deletedSize = deletedSize + dirSize;
            fprintf('✓\n');
        catch ME
            fprintf('✗ 失败: %s\n', ME.message);
        end
    end
    
    fprintf('\n===== 清理完成 =====\n');
    fprintf('删除了 %d 个目录\n', deleteCount);
    fprintf('释放空间: %.1f MB\n', deletedSize);
    fprintf('保留目录: %s\n', runDirs(1).name);
end

function size_mb = getDirSize(dirPath)
    % 递归计算目录大小（MB）
    files = dir(fullfile(dirPath, '**', '*.*'));
    files = files(~[files.isdir]);
    totalBytes = sum([files.bytes]);
    size_mb = totalBytes / (1024 * 1024);
end

