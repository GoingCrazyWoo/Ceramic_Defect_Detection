%% 陶瓷缺陷检测 - 一键自动运行脚本
% 自动处理所有samples目录下的测试图片，并自动生成报告

fprintf('===== 陶瓷缺陷检测系统 - 自动运行 =====\n\n');
fprintf('将执行流程：\n');
fprintf('  1. 收集样本\n');
fprintf('  2. 初始化工具包\n');
fprintf('  3. 处理图片\n\n');
fprintf('[提示] 当前模式：单张测试\n');
fprintf('        修改模式：编辑 auto_run.m 第46行\n');
fprintf('        processMode = ''single''  %% 单张测试\n');
fprintf('        processMode = ''all''     %% 全部处理\n\n');

%% 0. 为当前运行创建专属文件夹
runTimestamp = datestr(now, 'yyyymmdd_HHMMSS');
runDir = sprintf('run_%s', runTimestamp);
resultsDir = fullfile(runDir, 'results');

fprintf('0. 创建运行目录: %s\n', runDir);
if ~isfolder(runDir)
    mkdir(runDir);
end
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end
fprintf('   ✓ 运行目录已创建\n');

%% 1. 收集样本
fprintf('\n1. 收集样本...\n');

% 使用独立的函数收集样本（避免与toolkit内部同名实现冲突）
try
    [allImages, sampleDir] = collect_sample_images();
    fprintf('   ✓ 找到 %d 个图片文件\n', length(allImages));
catch ME
    error('收集样本失败: %s', ME.message);
end

%% 2. 初始化工具包
fprintf('\n2. 初始化工具包...\n');
toolkit = ceramic_toolkit();
fprintf('   ✓ 工具包已加载\n');

%% 3. 选择处理模式
fprintf('\n3. 选择处理模式...\n');

% 配置：选择处理模式
processMode = 'all';  % 'single' = 单张测试, 'all' = 全部处理

if strcmp(processMode, 'single')
    % 单张图片测试模式
    fprintf('   模式：单张图片测试\n');
    if length(allImages) > 0
        testImage = allImages(1).name;  % 选择第一张图片
        fprintf('   测试图片：%s\n', testImage);
        fprintf('   开始处理...\n');
        
        % 处理单张图片
        imagePath = fullfile(sampleDir, testImage);
        results = ceramic_defect_pipeline(imagePath);
        
        % 保存结果
        [~, baseName, ~] = fileparts(testImage);
        saveName = sprintf('results_%s.mat', baseName);
        save(fullfile(resultsDir, saveName), 'results');
        
        % 生成简单汇总
        summary = ceramic_results_summary(results);
        perf = ceramic_performance_metrics(results);
        
        fprintf('\n   ✓ 处理完成！\n');
        fprintf('   检测结果：\n');
        fprintf('     - 缺陷覆盖率：%.2f%%\n', perf.defectCoverage.local);
        fprintf('     - 检测直线数：%d\n', summary.lineDetection.count);
        fprintf('     - 检测圆形数：%d\n', summary.circleDetection.count);
        fprintf('     - 质量评分：%.1f/100\n', perf.qualityScore);
        
        % 保存CSV（单条记录）
        csvFile = fullfile(resultsDir, sprintf('single_test_%s.csv', datestr(now, 'yyyymmdd_HHMMSS')));
        fid = fopen(csvFile, 'w');
        fprintf(fid, 'file,defect_ratio,line_count,circle_count,quality_score\n');
        fprintf(fid, '%s,%.6f,%d,%d,%.6f\n', testImage, ...
            perf.defectCoverage.local/100, summary.lineDetection.count, ...
            summary.circleDetection.count, perf.qualityScore);
        fclose(fid);
        fprintf('     - CSV报告：%s\n', csvFile);
    else
        error('未找到测试图片');
    end
else
    % 批量处理所有图片
    fprintf('   模式：批量处理所有图片\n');
    fprintf('   开始处理...\n');
    
    toolkit.batchProcess('*.jpg', ...
        'SampleDir', sampleDir, ...
        'ResultsDir', resultsDir, ...
        'SaveResults', true, ...
        'GenerateCSV', true);
    
    fprintf('   ✓ 批量处理完成\n');
end

%% 4. 显示完成摘要
fprintf('\n===== 运行完成 =====\n');
fprintf('本次运行的所有结果已保存至: %s\n\n', runDir);

fprintf('输出文件位置:\n');
fprintf('  - 运行目录: %s/\n', runDir);
fprintf('  - 检测结果: %s/\n', resultsDir);

if isfolder(resultsDir)
    csvFiles = dir(fullfile(resultsDir, '*.csv'));
    if ~isempty(csvFiles)
        fprintf('  - CSV报告: %s/%s\n', resultsDir, csvFiles(end).name);
    end
    matFiles = dir(fullfile(resultsDir, '*.mat'));
    if ~isempty(matFiles)
        fprintf('  - MAT文件: %d个\n', length(matFiles));
    end
end

if strcmp(processMode, 'single')
    fprintf('\n[提示] 当前为单张测试模式\n');
    fprintf('       如需处理所有图片，修改 auto_run.m 第46行为：\n');
    fprintf('       processMode = ''all'';\n');
end

fprintf('\n全部完成！\n');
