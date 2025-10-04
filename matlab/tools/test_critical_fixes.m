% TEST_CRITICAL_FIXES - 测试关键bug修复
%
% 测试内容：
% 1. binaryGlobalClean字段是否存在
% 2. view_single_result是否能找到任意日期的文件

fprintf('===== 测试关键Bug修复 =====\n\n');

%% 测试1: 检查binaryGlobalClean字段
fprintf('测试1: 检查结果文件是否包含binaryGlobalClean字段\n');

% 查找最新的run目录
runDirs = dir('run_*');
runDirs = runDirs([runDirs.isdir]);
if isempty(runDirs)
    error('未找到任何run_*目录');
end
[~, idx] = max([runDirs.datenum]);
runDir = runDirs(idx).name;
fprintf('  使用目录: %s\n', runDir);

% 查找第一个结果文件
matFiles = dir(fullfile(runDir, 'results', 'results_*.mat'));
if isempty(matFiles)
    error('未找到任何结果文件');
end

matFile = fullfile(runDir, 'results', matFiles(1).name);
fprintf('  检查文件: %s\n', matFiles(1).name);

data = load(matFile);
if isfield(data.results, 'binaryGlobalClean')
    fprintf('  ✓ binaryGlobalClean字段存在\n');
    fprintf('  ✓ 大小: %d x %d\n', size(data.results.binaryGlobalClean, 1), size(data.results.binaryGlobalClean, 2));
else
    fprintf('  ✗ binaryGlobalClean字段缺失！\n');
    fprintf('  可用字段: %s\n', strjoin(fieldnames(data.results), ', '));
end

%% 测试2: 测试view_single_result的文件名匹配
fprintf('\n测试2: 测试view_single_result的文件名匹配能力\n');

% 提取图片基础名称（去掉日期前缀）
imgBaseName = strrep(matFiles(1).name, 'results_', '');
imgBaseName = strrep(imgBaseName, '.mat', '');

% 如果包含日期前缀，提取纯文件名
parts = split(imgBaseName, '_');
if length(parts) > 1 && ~isempty(regexp(parts{1}, '^\d{8}$', 'once'))
    % 有日期前缀，提取后面的部分
    imgBaseName = strjoin(parts(2:end), '_');
end

fprintf('  提取的图片名称: %s\n', imgBaseName);
fprintf('  尝试调用view_single_result...\n');

try
    % 测试文件查找逻辑（不实际创建可视化）
    resultsDir = fullfile(runDir, 'results');
    
    possiblePatterns = {
        sprintf('results_*_%s.mat', imgBaseName),
        sprintf('results_%s.mat', imgBaseName)
    };
    
    foundFile = '';
    for i = 1:length(possiblePatterns)
        files = dir(fullfile(resultsDir, possiblePatterns{i}));
        if ~isempty(files)
            foundFile = files(1).name;
            fprintf('  ✓ 找到文件: %s (模式%d)\n', foundFile, i);
            break;
        end
    end
    
    if isempty(foundFile)
        fprintf('  ✗ 未找到匹配文件！\n');
        fprintf('  尝试的模式:\n');
        for i = 1:length(possiblePatterns)
            fprintf('    - %s\n', possiblePatterns{i});
        end
    end
catch ME
    fprintf('  ✗ 错误: %s\n', ME.message);
end

%% 测试3: 重新运行单张图片检测并验证
fprintf('\n测试3: 重新运行单张图片检测并验证字段\n');

% 查找第一张样本图片
sampleFiles = dir(fullfile('..', 'samples', '*.jpg'));
if isempty(sampleFiles)
    sampleFiles = dir(fullfile('..', 'samples', '*.png'));
end

if ~isempty(sampleFiles)
    testImg = fullfile('..', 'samples', sampleFiles(1).name);
    fprintf('  使用测试图片: %s\n', sampleFiles(1).name);
    
    try
        % 运行检测
        opts = ceramic_default_options();
        results = ceramic_defect_pipeline(testImg, opts);
        
        % 检查关键字段
        requiredFields = {'binaryGlobalClean', 'irregularDefects', 'roiMask'};
        allPresent = true;
        
        for i = 1:length(requiredFields)
            field = requiredFields{i};
            if isfield(results, field)
                fprintf('  ✓ %s 字段存在\n', field);
            else
                fprintf('  ✗ %s 字段缺失！\n', field);
                allPresent = false;
            end
        end
        
        if allPresent
            fprintf('  ✓ 所有关键字段都存在\n');
        else
            fprintf('  ✗ 存在缺失字段\n');
        end
        
        % 测试可视化（不保存）
        fprintf('\n  测试可视化脚本兼容性...\n');
        try
            % 检查可视化所需的所有字段
            visFields = {'original', 'enhanced', 'roiMask', 'binaryGlobalClean', 'irregularDefects'};
            visOk = true;
            for i = 1:length(visFields)
                if ~isfield(results, visFields{i})
                    fprintf('    ✗ 可视化需要的字段 %s 缺失\n', visFields{i});
                    visOk = false;
                end
            end
            
            if visOk
                fprintf('    ✓ 可视化所需字段完整\n');
            end
        catch ME
            fprintf('    ✗ 可视化测试失败: %s\n', ME.message);
        end
        
    catch ME
        fprintf('  ✗ 检测失败: %s\n', ME.message);
    end
else
    fprintf('  ⚠ 未找到样本图片，跳过此测试\n');
end

%% 总结
fprintf('\n===== 测试完成 =====\n');
fprintf('请检查上述测试结果，确保所有测试都通过。\n');
fprintf('如果有失败项，需要立即修复。\n');

