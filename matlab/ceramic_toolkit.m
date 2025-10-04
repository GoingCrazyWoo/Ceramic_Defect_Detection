function toolkit = ceramic_toolkit()
%CERAMIC_TOOLKIT 陶瓷缺陷检测工具包
%   TOOLKIT = CERAMIC_TOOLKIT() 返回包含基础功能的工具包
%   
%   可用功能模块：
%       - runDemo(): 可视化演示工具
%       - batchProcess(): 批量处理图像
%
%   使用示例：
%       % 创建工具包
%       toolkit = ceramic_toolkit();
%       
%       % 运行演示
%       toolkit.runDemo('samples/test.jpg');
%       
%       % 批量处理
%       toolkit.batchProcess('*.jpg');

% 创建工具包结构体
toolkit = struct();

% 演示和批处理工具
toolkit.runDemo = @runDemo;
toolkit.batchProcess = @batchProcess;

% 显示工具包信息
fprintf('陶瓷缺陷检测工具包已初始化\n');
fprintf('可用功能: runDemo, batchProcess\n');

end

%% ========================================================================
%% 可视化演示功能
%% ========================================================================

function runDemo(imagePath)
%RUNDEMO 可视化演示工具
%   RUNDEMO(IMAGEPATH) 使用指定图像路径运行演示
%   RUNDEMO() 弹出文件选择框让用户挑选图像

    if nargin < 1 || isempty(imagePath)
        [fileName, folder] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tiff', 'Image Files'}, ...
            '请选择陶瓷样本图像');
        if isequal(fileName, 0)
            fprintf('已取消演示。\n');
            return;
        end
        imagePath = fullfile(folder, fileName);
    else
        if ~isfile(imagePath)
            error('ceramic_toolkit:FileNotFound', ...
                '无法找到指定图像: %s', imagePath);
        end
    end

    results = ceramic_defect_pipeline(imagePath);

    % 创建主要流程图
    figure('Name', 'Ceramic Defect Pipeline');
    subplot(2,3,1); imshow(results.original); title('Original Grayscale');
    subplot(2,3,2); imshow(results.enhanced); title('CLAHE + Bilateral');
    subplot(2,3,3); imshow(results.binaryGlobal); title('Global Otsu');
    subplot(2,3,4); imshow(results.binaryLocal); title('Local Otsu');
    subplot(2,3,5); imshow(results.edgeMaps.canny); title('Canny Edges');
    subplot(2,3,6); imshow(results.edgeMaps.sobel); title('Sobel Edges');

    % 霍夫直线检测结果
    figure('Name', 'Hough Line Detections');
    imshow(results.edgeMaps.canny); hold on;
    for k = 1:numel(results.houghLines.lines)
        xy = [results.houghLines.lines(k).point1; results.houghLines.lines(k).point2];
        plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', 'cyan');
    end
    hold off;

    % 圆形检测结果
    if ~isempty(results.circles.centers)
        figure('Name', 'Circular Defects');
        imshow(results.enhanced); hold on;
        viscircles(results.circles.centers, results.circles.radii, 'Color', 'r');
        hold off;
    end
end

%% ========================================================================
%% 批量处理功能
%% ========================================================================

function batchProcess(samplePattern, varargin)
%BATCHPROCESS 批量处理陶瓷样本图像
%   BATCHPROCESS(SAMPLEPATTERN) 批量处理匹配模式的图像文件
%   
%   可选参数：
%       'SampleDir' - 样本目录路径 (default: '../samples')
%       'ResultsDir' - 结果保存目录 (default: '../results')
%       'SaveResults' - 是否保存详细结果 (default: true)
%       'GenerateCSV' - 是否生成CSV汇总 (default: true)
%       'Options' - 检测算法参数 (default: struct())

    % 解析输入参数
    p = inputParser;
    addRequired(p, 'samplePattern', @ischar);
    addParameter(p, 'SampleDir', fullfile('..', 'samples'), @ischar);
    addParameter(p, 'ResultsDir', fullfile('..', 'results'), @ischar);
    addParameter(p, 'SaveResults', true, @islogical);
    addParameter(p, 'GenerateCSV', true, @islogical);
    addParameter(p, 'Options', struct(), @isstruct);
    parse(p, samplePattern, varargin{:});

    sampleDir = p.Results.SampleDir;
    resultsDir = p.Results.ResultsDir;

    % 创建结果目录
    if ~isfolder(resultsDir)
        mkdir(resultsDir);
    end

    % 查找匹配的图像文件
    imageFiles = dir(fullfile(sampleDir, samplePattern));
    
    % 过滤掉 . 和 .. 目录
    imageFiles = imageFiles(~ismember({imageFiles.name}, {'.', '..'}));
    
    if isempty(imageFiles)
        warning('ceramic_toolkit:NoFiles', '未找到匹配模式 "%s" 的图像文件', samplePattern);
        return;
    end

    fprintf('找到 %d 个匹配的图像文件\n', length(imageFiles));

    % 预分配记录数组（增加质量评分列）
    records = cell(length(imageFiles), 5);
    validCount = 0;

    % 批量处理图像
    for k = 1:length(imageFiles)
        fileName = imageFiles(k).name;
        imagePath = fullfile(sampleDir, fileName);
        
        fprintf('处理 %d/%d: %s ...\n', k, length(imageFiles), fileName);
        
        try
            % 运行检测流程
            results = ceramic_defect_pipeline(imagePath, p.Results.Options);
            
            % 保存详细结果
            resultsMatFile = '';
            if p.Results.SaveResults
                [~, baseName, ~] = fileparts(fileName);
                saveName = sprintf('results_%s.mat', baseName);
                resultsMatFile = fullfile(resultsDir, saveName);
                save(resultsMatFile, 'results');
            end
            
            % 使用统一schema提取指标
            unifiedData = ceramic_unified_schema(results, ...
                'ImagePath', imagePath, ...
                'Parameters', p.Results.Options);
            
            % 记录指标（基于统一schema）
            validCount = validCount + 1;
            records{validCount, 1} = fileName;
            records{validCount, 2} = unifiedData.defectCoverageLocal / 100;
            records{validCount, 3} = unifiedData.lineCount;
            records{validCount, 4} = unifiedData.circleCount;
            records{validCount, 5} = unifiedData.qualityScore;  % 新增质量评分
            
        catch ME
            warning('ceramic_toolkit:ProcessingError', ...
                '处理文件 %s 时出错: %s', fileName, ME.message);
            continue;
        end
    end

    % 生成CSV汇总（基于统一schema）
    if p.Results.GenerateCSV && validCount > 0
        validRecords = records(1:validCount, :);
        
        t = cell2table(validRecords, 'VariableNames', ...
            {'file', 'defect_ratio', 'line_count', 'circle_count', 'quality_score'});
        
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        csvName = sprintf('batch_summary_%s.csv', timestamp);
        summaryPath = fullfile(resultsDir, csvName);
        
        writetable(t, summaryPath);
        
        fprintf('批量处理完成！\n');
        fprintf('- 成功处理: %d/%d 个文件\n', validCount, length(imageFiles));
        fprintf('- 汇总文件: %s\n', summaryPath);
        
        if validCount > 0
            avgDefectRatio = mean([validRecords{:,2}]);
            totalLines = sum([validRecords{:,3}]);
            totalCircles = sum([validRecords{:,4}]);
            
            fprintf('- 平均缺陷比例: %.2f%%\n', avgDefectRatio * 100);
            fprintf('- 总检测直线: %d 条\n', totalLines);
            fprintf('- 总检测圆形: %d 个\n', totalCircles);
        end
    else
        fprintf('批量处理完成，但没有成功处理的文件。\n');
    end
end
