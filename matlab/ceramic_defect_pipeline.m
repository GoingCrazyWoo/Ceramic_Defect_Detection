function results = ceramic_defect_pipeline(imagePath, opts)
%CERAMIC_DEFECT_PIPELINE Complete classical pipeline for ceramic defect detection.
%   RESULTS = CERAMIC_DEFECT_PIPELINE(IMAGEPATH) reads the image located at
%   IMAGEPATH and runs CLAHE-based preprocessing, global and local Otsu
%   thresholding, edge detection, and Hough-based geometric analysis. The
%   function returns a struct with intermediate data and measurements that can
%   be plotted or exported to support a ceramic defect detection study.
%   中文：该函数实现导师建议的传统陶瓷缺陷检测流程，包括CLAHE增强、Otsu分割、边缘检测与霍夫分析。
%
%   v3.0新增：ROI检测，确保只在陶瓷管区域内检测缺陷
%
%   RESULTS = CERAMIC_DEFECT_PIPELINE(IMAGEPATH, OPTS) accepts a struct with the
%   optional fields listed below to tweak the pipeline without touching the
%   code:
%       - ClipLimit:       CLAHE clip limit (default 0.015)
%       - NumTiles:        CLAHE tiling as [rows cols] (default [8 8])
%       - LocalBlockSize:  Block size for local Otsu thresholding (default [64 64])
%       - LocalOverlap:    Overlap for local Otsu as [row col] pixels (default [16 16])
%       - MorphOpenRadius: Radius of the post-segmentation morphological opening
%                           disk (default 2)
%       - CannyThreshold:  Two-element threshold vector for edge('Canny')
%                           (default [])
%       - CannySigma:      Sigma for Canny detector smoothing (default 1.0)
%       - SobelThreshold:  Threshold for edge('Sobel') (default 0.02)
%       - LineFillGap:     Gap filling (pixels) for extracted Hough lines
%                           (default 10)
%       - LineMinLength:   Minimum line length in pixels (default 30)
%       - CircleRadius:    Two-element radius range for imfindcircles (default [5 40])
%       - CircleSensitivity: Sensitivity for imfindcircles (default 0.9)
%       - CircleEdgeThreshold: Edge threshold for imfindcircles (default 0.1)
%       - EnableROI:       是否启用ROI检测（default true，v3.0新增）
%       - ROIBrightnessThreshold: ROI检测亮度阈值（default 0.20）
%       - ROIHeightRange:  ROI检测垂直范围（default [0.25, 0.75]）
%   中文：通过opts结构体可以快速调整各个步骤的参数，便于不同陶瓷样本的实验。
%
%   Example:
%       results = ceramic_defect_pipeline('samples/cracked_tile.png');
%       figure; montage({results.original, results.enhanced});
%
%   See also ADAPTHISTEQ, GRAYTHRESH, IMBINARIZE, EDGE, HOUGH, IMFINDCIRCLES.

arguments
    imagePath (1,:) char
    opts struct = struct()
end

if ~isfile(imagePath)
    error('ceramic_defect_pipeline:FileNotFound', ...
        'Could not find image file: %s', imagePath);
end

opts = fillDefaultOptions(opts);

I = imread(imagePath);
if size(I, 3) == 3
    Igray = rgb2gray(I); % 将RGB转换为灰度，方便后续处理
else
    Igray = I;
end
Igray = im2double(Igray); % 归一化到[0,1]，保证算法稳定

%% v3.0新增：ROI检测
if opts.EnableROI
    fprintf('>> 启用ROI检测（v3.0）\n');
    roiMask = detect_ceramic_roi(Igray, ...
        'BrightnessThreshold', opts.ROIBrightnessThreshold, ...
        'HeightRange', opts.ROIHeightRange, ...
        'KeepSeparateTubes', opts.ROIKeepSeparate);
else
    % 兼容v2.x：不启用ROI，处理整张图
    roiMask = true(size(Igray));
end

enhanced = applyClahe(Igray, opts); % CLAHE增强并轻度双边滤波

%% Global thresholding - v3.0-R4: 使用固定低阈值检测暗色缺陷
% 原因：Otsu阈值(0.498)太高，误判了正常区域
% 改进：使用固定阈值0.25，只检测明显的黑色缺陷（裂纹、污渍）
if opts.EnableROI
    % ROI模式：使用固定低阈值（真实缺陷通常很暗）
    fixedThreshold = 0.25;
    binaryGlobal = enhanced < fixedThreshold;
    levelGlobal = fixedThreshold;
    fprintf('  >> 使用固定阈值%.2f检测暗色缺陷\n', fixedThreshold);
else
    % 整图模式：仍使用Otsu
    levelGlobal = graythresh(enhanced);
    binaryGlobal = imbinarize(enhanced, levelGlobal);
end

%% v3.0优化：ROI内使用全局Otsu，不用局部Otsu
% 原因：管子区域相对均匀，局部Otsu会把正常的光照变化误判为缺陷
% 实测：局部Otsu导致缺陷率72.80%（过高），全局Otsu更准确
if opts.EnableROI
    % ROI内直接使用全局Otsu结果（更准确，更快）
    fprintf('  >> ROI模式：使用全局Otsu（适合均匀的管子区域）\n');
    binaryLocal = binaryGlobal & roiMask;  % 全局Otsu + ROI约束
else
    % v2.x兼容：整张图需要局部Otsu（背景和管子差异大）
    fprintf('  >> 整图模式：使用局部Otsu（适应不同区域）\n');
    binaryLocal = localOtsuThreshold(enhanced, opts);
end

%% Mild morphological opening to suppress isolated pixels
% 形态学开运算降低噪点，突出真实缺陷
se = strel('disk', opts.MorphOpenRadius);
binaryGlobalClean = imopen(binaryGlobal, se);
binaryLocalClean = imopen(binaryLocal, se);

% v3.0：再次应用ROI约束
if opts.EnableROI
    binaryGlobalClean = binaryGlobalClean & roiMask;
    binaryLocalClean = binaryLocalClean & roiMask;
end

%% Edge detection - v3.0：只在ROI内
if opts.EnableROI
    enhancedForEdge = enhanced .* double(roiMask);
    edgeMaps = computeEdges(enhancedForEdge, opts);
    % 确保边缘只在ROI内
    edgeMaps.canny = edgeMaps.canny & roiMask;
    edgeMaps.sobel = edgeMaps.sobel & roiMask;
    edgeMaps.log = edgeMaps.log & roiMask;
else
    edgeMaps = computeEdges(enhanced, opts);
end

%% Line detection - v3.0：只在ROI内的边缘
lineData = detectLineFeatures(edgeMaps.canny, opts);

% v3.0：过滤不在ROI内的直线
if opts.EnableROI && ~isempty(lineData.lines)
    validLines = [];
    for k = 1:numel(lineData.lines)
        line = lineData.lines(k);
        % 检查直线的两个端点是否在ROI内
        p1 = round(line.point1);
        p2 = round(line.point2);
        % 确保坐标在范围内
        p1(1) = max(1, min(p1(1), size(roiMask, 2)));
        p1(2) = max(1, min(p1(2), size(roiMask, 1)));
        p2(1) = max(1, min(p2(1), size(roiMask, 2)));
        p2(2) = max(1, min(p2(2), size(roiMask, 1)));
        
        % 如果至少一个端点在ROI内，保留这条直线
        if roiMask(p1(2), p1(1)) || roiMask(p2(2), p2(1))
            validLines = [validLines; line];
        end
    end
    lineData.lines = validLines;
end

%% Irregular defect detection - v3.0-R6：检测管子上的不规则缺陷
% 改进：不检测圆形，而是分析所有不规则缺陷（污渍、裂纹等）
fprintf('  >> 检测不规则缺陷（污渍、裂纹、孔洞等）\n');

% 使用缺陷二值图进行连通域分析
irregularStats = detect_irregular_defects(binaryGlobalClean, opts);

fprintf('     检测到%d个不规则缺陷\n', irregularStats.count);
if irregularStats.count > 0
    fprintf('     - 圆形孔洞: %d个\n', irregularStats.circularCount);
    fprintf('     - 线状裂纹: %d个\n', irregularStats.linearCount);
    fprintf('     - 空心缺陷: %d个\n', irregularStats.hollowCount);
    fprintf('     - 不规则污渍: %d个\n', irregularStats.irregularCount);
    fprintf('     - 总面积: %d像素\n', round(irregularStats.totalArea));
    fprintf('     - 平均面积: %.1f像素\n', irregularStats.avgArea);
end

% 为了保持兼容性，创建一个空的circleData
circleData = struct();
circleData.centers = [];
circleData.radii = [];

%% 构建结果结构体
results = struct();
results.original = Igray;
results.enhanced = enhanced;
results.otsuGlobalLevel = levelGlobal;
results.binaryGlobal = binaryGlobalClean;
results.binaryLocal = binaryLocalClean;
results.edgeMaps = edgeMaps;
results.houghLines = lineData;
results.circles = circleData;  % 保持兼容性（已废弃）
results.irregularDefects = irregularStats;  % v3.0-R6: 新增不规则缺陷检测

% v3.0新增：ROI信息
if opts.EnableROI
    results.roiMask = roiMask;
    results.roiEnabled = true;
else
    results.roiMask = [];
    results.roiEnabled = false;
end

end

function opts = fillDefaultOptions(opts)
    defaults = ceramic_default_options();

    fields = fieldnames(defaults);
    for i = 1:numel(fields)
        name = fields{i};
        if ~isfield(opts, name)
            opts.(name) = defaults.(name); % 若用户未指定则使用默认值
        end
    end
    
    % v3.0新增默认值
    if ~isfield(opts, 'EnableROI')
        opts.EnableROI = true;  % 默认启用ROI检测
    end
    if ~isfield(opts, 'ROIBrightnessThreshold')
        opts.ROIBrightnessThreshold = 0.50;  % v3.0-R4: 大幅提高，只保留真正的白色管子本体
    end
    if ~isfield(opts, 'ROIHeightRange')
        opts.ROIHeightRange = [0.1, 0.9];  % 更大范围80%以覆盖完整管子
    end
    if ~isfield(opts, 'ROIKeepSeparate')
        opts.ROIKeepSeparate = true;  % 保持管子独立，不连接
    end
end

function enhanced = applyClahe(I, opts)
    enhanced = adapthisteq(I, ...
        'NumTiles', opts.NumTiles, ...
        'ClipLimit', opts.ClipLimit, ...
        'Distribution', 'rayleigh');
    % CLAHE自适应提升局部对比度
    enhanced = imbilatfilt(enhanced, 0.1, 5);
    % 双边滤波抑制噪声并保留缺陷边缘
end

function binaryLocal = localOtsuThreshold(I, opts)
    blockSize = opts.LocalBlockSize;
    overlap = opts.LocalOverlap;
    
    fprintf('  >> 局部Otsu: 块大小%dx%d, 重叠%dx%d, 图像%dx%d\n', ...
            blockSize(1), blockSize(2), overlap(1), overlap(2), size(I,1), size(I,2));
    tic;

    % blockproc不支持Overlap参数！使用BorderSize来模拟重叠效果
    % BorderSize会在每个块周围添加边界，处理后去除边界，达到平滑过渡的效果
    borderSize = min([overlap(1), overlap(2), blockSize(1)-1, blockSize(2)-1]);
    
    fprintf('     使用blockproc（BorderSize=%d用于平滑过渡）...\n', borderSize);
    
    threshMap = blockproc(I, blockSize, ...
        @(blockStruct) repmat(graythresh(blockStruct.data), size(blockStruct.data)), ...
        'BorderSize', [borderSize, borderSize], ...
        'TrimBorder', true, ...
        'PadPartialBlocks', true);
    
    fprintf('     ✓ blockproc完成，耗时: %.1f秒\n', toc);
    
    % 检查threshMap大小是否匹配
    if ~isequal(size(threshMap), size(I))
        fprintf('     ⚠ 尺寸不匹配：threshMap=%dx%d, I=%dx%d\n', ...
                size(threshMap,1), size(threshMap,2), size(I,1), size(I,2));
        % 调整threshMap大小以匹配I
        threshMap = imresize(threshMap, size(I), 'nearest');
        fprintf('     ✓ 已调整threshMap大小\n');
    end

    binaryLocal = imbinarize(I, threshMap);
end

function edgeMaps = computeEdges(I, opts)
    edgeMaps = struct();
    edgeMaps.sobel = edge(I, 'sobel', opts.SobelThreshold); % Sobel突出方向梯度
    if isempty(opts.CannyThreshold)
        edgeMaps.canny = edge(I, 'canny', [], opts.CannySigma);
    else
        edgeMaps.canny = edge(I, 'canny', opts.CannyThreshold, opts.CannySigma);
    end
    edgeMaps.log = edge(I, 'log'); % Laplacian of Gaussian 提升纹理细节
end

function lineData = detectLineFeatures(edgeImage, opts)
    [H, theta, rho] = hough(edgeImage);
    peaks = houghpeaks(H, 10, 'Threshold', 0.3 * max(H(:)));
    lines = houghlines(edgeImage, theta, rho, peaks, ...
        'FillGap', opts.LineFillGap, ...
        'MinLength', opts.LineMinLength);

    lineData = struct();
    lineData.houghMatrix = H;
    lineData.theta = theta;
    lineData.rho = rho;
    lineData.peaks = peaks;
    lineData.lines = lines;
end

function circleData = detectCircularFeatures(I, opts)
    try
        [centers, radii] = imfindcircles(I, opts.CircleRadius, ...
            'Sensitivity', opts.CircleSensitivity, ...
            'EdgeThreshold', opts.CircleEdgeThreshold);
    catch ME
        warning('imfindcircles failed: %s. Returning empty result.', ME.message);
        centers = [];
        radii = [];
    end

    circleData = struct();
    circleData.centers = centers;
    circleData.radii = radii;
end
