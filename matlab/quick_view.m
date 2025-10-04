%% 快速查看最新运行结果
% 自动找到最新的run_*目录并显示结果

fprintf('正在查找最新的运行结果...\n');

% 获取所有run_*目录
runDirs = dir('run_*');
runDirs = runDirs([runDirs.isdir]);

if isempty(runDirs)
    error('未找到任何运行结果目录（run_*）');
end

% 按日期排序，获取最新的
[~, idx] = sort([runDirs.datenum], 'descend');
latestRun = runDirs(idx(1)).name;

fprintf('找到最新运行: %s\n', latestRun);

% 查找该目录下的.mat文件
resultsDir = fullfile(latestRun, 'results');
matFiles = dir(fullfile(resultsDir, 'results_*.mat'));

if isempty(matFiles)
    error('在 %s 中未找到结果文件', resultsDir);
end

% 显示找到的结果文件
fprintf('找到 %d 个结果文件:\n', length(matFiles));
for i = 1:length(matFiles)
    fprintf('  %d. %s\n', i, matFiles(i).name);
end

% 默认显示第一个
matFile = fullfile(resultsDir, matFiles(1).name);
fprintf('\n正在显示: %s\n\n', matFiles(1).name);

% 调用view_results
view_results(matFile);

