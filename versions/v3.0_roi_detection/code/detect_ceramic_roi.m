function roiMask = detect_ceramic_roi(grayImage, opts)
%DETECT_CERAMIC_ROI 检测图像中的陶瓷管区域（ROI）
%   ROIMASK = DETECT_CERAMIC_ROI(GRAYIMAGE) 返回陶瓷管区域的二值掩码
%   
%   核心目标：确保检测到所有白色陶瓷管
%   
%   算法策略：
%   1. 基于亮度 - 陶瓷管比背景亮（白色/灰色 vs 深色背景）
%   2. 基于位置 - 陶瓷管在图像中间的水平带状区域
%   3. 形态学处理 - 连接所有管子，去除噪声
%   4. 保守策略 - 宁可多检测，不能漏检
%
%   参数：
%       - BrightnessThreshold: 亮度阈值（默认：0.25，宽松以确保全覆盖）
%       - HeightRange: 垂直位置范围（默认：[0.25, 0.75]，图像中间50%）
%       - MorphCloseRadius: 形态学闭运算半径（默认：40，连接管子）
%       - MorphOpenRadius: 形态学开运算半径（默认：15，去小噪声）
%       - MinAreaRatio: 最小区域面积比例（默认：0.2，至少20%图像）

arguments
    grayImage double
    opts.BrightnessThreshold (1,1) double = 0.30
    opts.HeightRange (1,2) double = [0.15, 0.85]
    opts.MorphCloseRadius (1,1) double = 15
    opts.MorphOpenRadius (1,1) double = 15
    opts.MinAreaRatio (1,1) double = 0.03
    opts.KeepSeparateTubes (1,1) logical = true
    opts.RemoveForeground (1,1) logical = false
end

[H, W] = size(grayImage);

fprintf('  >> 开始检测陶瓷管ROI...\n');

%% 步骤1：基于亮度的初步分割
% 策略：陶瓷管是白色/浅灰色，背景是深色
% 使用较低的阈值确保不漏检

brightMask = grayImage > opts.BrightnessThreshold;
fprintf('     - 亮度阈值 %.2f: %.1f%% 像素通过\n', ...
    opts.BrightnessThreshold, sum(brightMask(:))/numel(brightMask)*100);

%% 步骤2：基于位置的约束
% 策略：陶瓷管通常在图像中间的水平带状区域

heightStart = round(H * opts.HeightRange(1));
heightEnd = round(H * opts.HeightRange(2));
positionMask = false(H, W);
positionMask(heightStart:heightEnd, :) = true;

fprintf('     - 位置约束: 第%d-%d行（图像中间%.0f%%）\n', ...
    heightStart, heightEnd, (opts.HeightRange(2) - opts.HeightRange(1)) * 100);

%% 步骤3：结合亮度和位置
ceramicRough = brightMask & positionMask;

%% 步骤4：形态学处理 - 根据策略选择
if opts.KeepSeparateTubes
    % 新策略：保持管子独立，不连接
    fprintf('     - 策略：保持独立管子（不连接）\n');
    
    % 使用较小的闭运算，只填充单根管子内部的小孔
    seClose = strel('disk', opts.MorphCloseRadius);
    ceramicConnected = imclose(ceramicRough, seClose);
    
    % 填充每根管子内部的孔洞
    ceramicFilled = imfill(ceramicConnected, 'holes');
    
    % 使用较小的开运算去除噪声
    seOpen = strel('disk', opts.MorphOpenRadius);
    ceramicClean = imopen(ceramicFilled, seOpen);
    
    %% 步骤5：保留所有管子区域（不只是最大的）
    cc = bwconncomp(ceramicClean);
    if cc.NumObjects == 0
        warning('未检测到陶瓷管区域！返回空掩码');
        roiMask = false(H, W);
        return;
    end
    
    % 计算每个连通区域的面积
    areas = cellfun(@numel, cc.PixelIdxList);
    
    % 保留所有足够大的区域（每根管子都保留）
    minArea = H * W * opts.MinAreaRatio;  % 降低到5%
    validRegions = areas >= minArea;
    
    if sum(validRegions) == 0
        warning('未找到足够大的区域！');
        roiMask = false(H, W);
        return;
    end
    
    % 保留所有有效管子
    roiMask = false(H, W);
    for i = find(validRegions)
        roiMask(cc.PixelIdxList{i}) = true;
    end
    
    fprintf('     - 保留%d根独立管子\n', sum(validRegions));
    
else
    % 旧策略：连接所有管子成一个大区域
    fprintf('     - 策略：连接所有管子（旧方法）\n');
    seClose = strel('disk', opts.MorphCloseRadius);
    ceramicConnected = imclose(ceramicRough, seClose);
    
    ceramicFilled = imfill(ceramicConnected, 'holes');
    fprintf('     - 填充内部孔洞\n');
    
    seOpen = strel('disk', opts.MorphOpenRadius);
    ceramicClean = imopen(ceramicFilled, seOpen);
    
    %% 保留最大连通区域
    cc = bwconncomp(ceramicClean);
    if cc.NumObjects == 0
        warning('未检测到陶瓷管区域！返回空掩码');
        roiMask = false(H, W);
        return;
    end
    
    areas = cellfun(@numel, cc.PixelIdxList);
    [~, idx] = max(areas);
    roiMask = false(H, W);
    roiMask(cc.PixelIdxList{idx}) = true;
    fprintf('     - 保留最大区域\n');
end

%% 步骤6：可选 - 去除前景遮挡（垂直支撑杆）
if opts.RemoveForeground
    fprintf('     - 检测并移除前景垂直遮挡...\n');
    
    % 检测垂直结构（支撑杆）
    % 使用线性结构元素检测垂直线
    verticalSE = strel('line', 100, 90);  % 90度 = 垂直
    verticalStructures = imopen(brightMask, verticalSE);
    
    % 扩展垂直结构以完全覆盖
    verticalExpanded = imdilate(verticalStructures, strel('disk', 10));
    
    % 从ROI中移除
    roiMask = roiMask & ~verticalExpanded;
    
    % 再次填充可能产生的孔洞
    roiMask = imfill(roiMask, 'holes');
    
    removedRatio = sum(verticalExpanded(:)) / numel(verticalExpanded) * 100;
    fprintf('     - 移除前景遮挡：%.2f%%\n', removedRatio);
end

%% 步骤7：最终验证和统计
roiRatio = sum(roiMask(:)) / numel(roiMask) * 100;
fprintf('     ✓ ROI检测完成：覆盖%.1f%%图像区域\n', roiRatio);

% 检查ROI是否合理（应该在20%-70%之间）
if roiRatio < 15
    warning('ROI覆盖率过低（%.1f%%），可能漏检了管子！', roiRatio);
    fprintf('     建议：降低BrightnessThreshold或扩大HeightRange\n');
elseif roiRatio > 75
    warning('ROI覆盖率过高（%.1f%%），可能包含了太多背景！', roiRatio);
    fprintf('     建议：提高BrightnessThreshold或缩小HeightRange\n');
end

end

