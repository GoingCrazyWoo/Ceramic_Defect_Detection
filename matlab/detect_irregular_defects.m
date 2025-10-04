function irregularStats = detect_irregular_defects(binaryDefect, opts)
%DETECT_IRREGULAR_DEFECTS 检测不规则缺陷（污渍、裂纹等）
%   对缺陷二值图进行连通域分析，识别不规则形状
%
%   输入：
%   binaryDefect - 二值缺陷图（logical）
%   opts - 参数结构体
%
%   输出：
%   irregularStats - 不规则缺陷统计信息
%       .count - 缺陷数量
%       .totalArea - 总面积
%       .avgArea - 平均面积
%       .maxArea - 最大面积
%       .regions - 每个缺陷的详细信息
%           .Area - 面积
%           .Centroid - 中心点
%           .BoundingBox - 边界框
%           .Perimeter - 周长
%           .Circularity - 圆形度（4π*Area/Perimeter^2）
%           .Eccentricity - 离心率
%           .Solidity - 实心度

arguments
    binaryDefect logical
    opts struct = struct()
end

% 设置默认参数
if ~isfield(opts, 'MinDefectArea')
    opts.MinDefectArea = 50;  % 最小缺陷面积（像素）
end
if ~isfield(opts, 'MaxDefectArea')
    opts.MaxDefectArea = 10000;  % 最大缺陷面积（像素）
end

%% 连通域分析
cc = bwconncomp(binaryDefect);

if cc.NumObjects == 0
    % 没有检测到缺陷
    irregularStats = struct();
    irregularStats.count = 0;
    irregularStats.totalArea = 0;
    irregularStats.avgArea = 0;
    irregularStats.maxArea = 0;
    irregularStats.regions = [];
    return;
end

%% 提取区域属性（包含边界信息用于可视化）
stats = regionprops(cc, 'Area', 'Centroid', 'BoundingBox', ...
                    'Perimeter', 'Eccentricity', 'Solidity', ...
                    'MajorAxisLength', 'MinorAxisLength');

% 提取边界信息（用于可视化）
boundaries = cell(length(stats), 1);
for i = 1:cc.NumObjects
    mask = false(size(binaryDefect));
    mask(cc.PixelIdxList{i}) = true;
    B = bwboundaries(mask, 'noholes');
    if ~isempty(B)
        boundaries{i} = B{1};  % 取外边界
    else
        boundaries{i} = [];
    end
end

%% 过滤：保留符合大小要求的区域
validIdx = [];
for i = 1:length(stats)
    area = stats(i).Area;
    if area >= opts.MinDefectArea && area <= opts.MaxDefectArea
        validIdx = [validIdx; i];
    end
end

if isempty(validIdx)
    % 没有符合大小要求的缺陷
    irregularStats = struct();
    irregularStats.count = 0;
    irregularStats.totalArea = 0;
    irregularStats.avgArea = 0;
    irregularStats.maxArea = 0;
    irregularStats.regions = [];
    return;
end

stats = stats(validIdx);
boundaries = boundaries(validIdx);

%% 计算额外的形状特征
for i = 1:length(stats)
    % 添加边界信息
    stats(i).boundary = boundaries{i};
    % 圆形度：4π*Area/Perimeter^2，圆形接近1
    if stats(i).Perimeter > 0
        stats(i).Circularity = 4 * pi * stats(i).Area / (stats(i).Perimeter^2);
    else
        stats(i).Circularity = 0;
    end
    
    % 长宽比
    if stats(i).MinorAxisLength > 0
        stats(i).AspectRatio = stats(i).MajorAxisLength / stats(i).MinorAxisLength;
    else
        stats(i).AspectRatio = Inf;
    end
end

%% 分类缺陷类型（可选）
for i = 1:length(stats)
    circ = stats(i).Circularity;
    aspect = stats(i).AspectRatio;
    solid = stats(i).Solidity;
    
    if circ > 0.7 && aspect < 2
        stats(i).type = 'circular';      % 圆形孔洞（小写type）
    elseif aspect > 3
        stats(i).type = 'linear';        % 线状裂纹
    elseif solid < 0.8
        stats(i).type = 'hollow';        % 空心/复杂形状
    else
        stats(i).type = 'irregular';     % 不规则污渍
    end
    
    % 添加centroid字段用于可视化（从Centroid复制）
    stats(i).centroid = stats(i).Centroid;
    stats(i).area = stats(i).Area;  % 添加小写area字段
end

%% 汇总统计
irregularStats = struct();
irregularStats.count = length(stats);
irregularStats.totalArea = sum([stats.Area]);
irregularStats.avgArea = mean([stats.Area]);
irregularStats.maxArea = max([stats.Area]);

% 分类统计（使用小写type）
types = {stats.type};
irregularStats.circularCount = sum(strcmp(types, 'circular'));
irregularStats.linearCount = sum(strcmp(types, 'linear'));
irregularStats.hollowCount = sum(strcmp(types, 'hollow'));
irregularStats.irregularCount = sum(strcmp(types, 'irregular'));

% 保存详细缺陷列表（用于可视化）
irregularStats.defects = stats;
irregularStats.regions = stats;  % 保持向后兼容

end

