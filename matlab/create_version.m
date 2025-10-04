function create_version(versionName, description)
%CREATE_VERSION 创建新的版本快照
%   CREATE_VERSION(VERSIONNAME, DESCRIPTION) 保存当前代码和结果到版本历史
%
%   使用示例：
%       create_version('v2.2_edge_optimization', '优化边缘检测参数');
%
%   自动保存：
%   - 当前参数配置文件
%   - 最新的运行结果
%   - 版本说明文档

    if nargin < 2
        description = '版本更新';
    end
    
    % 创建版本目录
    versionDir = fullfile('..', 'versions', versionName);
    if ~isfolder(versionDir)
        mkdir(versionDir);
        mkdir(fullfile(versionDir, 'code'));
        mkdir(fullfile(versionDir, 'run_results'));
    else
        warning('版本 %s 已存在，将覆盖', versionName);
    end
    
    % 保存代码文件
    fprintf('保存代码文件...\n');
    copyfile('ceramic_default_options.m', fullfile(versionDir, 'code', 'ceramic_default_options.m'));
    
    % 查找最新的运行结果
    runDirs = dir('run_*');
    runDirs = runDirs([runDirs.isdir]);
    if ~isempty(runDirs)
        [~, idx] = max([runDirs.datenum]);
        latestRun = runDirs(idx).name;
        
        % 复制CSV结果
        csvFiles = dir(fullfile(latestRun, 'results', '*.csv'));
        if ~isempty(csvFiles)
            copyfile(fullfile(latestRun, 'results', csvFiles(1).name), ...
                fullfile(versionDir, 'run_results', 'batch_summary.csv'));
            fprintf('保存运行结果: %s\n', csvFiles(1).name);
        end
    end
    
    % 创建版本信息文档
    fprintf('生成版本信息...\n');
    versionFile = fullfile(versionDir, 'VERSION_INFO.md');
    fid = fopen(versionFile, 'w', 'n', 'UTF-8');
    
    fprintf(fid, '# %s\n\n', versionName);
    fprintf(fid, '**日期**：%s\n', datestr(now, 'yyyy-mm-dd HH:MM'));
    fprintf(fid, '**描述**：%s\n\n', description);
    fprintf(fid, '## 参数配置\n\n');
    fprintf(fid, '参数文件保存在：`code/ceramic_default_options.m`\n\n');
    fprintf(fid, '## 运行结果\n\n');
    fprintf(fid, '检测结果保存在：`run_results/batch_summary.csv`\n\n');
    fprintf(fid, '## 备注\n\n');
    fprintf(fid, '请在此添加详细的优化说明和结果分析。\n');
    
    fclose(fid);
    
    fprintf('\n✅ 版本 %s 创建完成！\n', versionName);
    fprintf('位置：%s\n', versionDir);
    fprintf('\n下一步：\n');
    fprintf('1. 编辑 %s\n', versionFile);
    fprintf('2. 添加详细的优化说明和结果对比\n');
end

