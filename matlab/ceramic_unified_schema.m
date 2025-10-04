function unifiedData = ceramic_unified_schema(results, varargin)
%CERAMIC_UNIFIED_SCHEMA 统一的结果数据模式
%   将检测结果标准化为统一的数据结构，供CSV、Excel、报告等共用
%
%   UNIFIEDDATA = CERAMIC_UNIFIED_SCHEMA(RESULTS) 从检测结果生成统一schema
%   
%   可选参数：
%       'ImagePath' - 图像路径 (default: '')
%       'Parameters' - 使用的参数 (default: struct())
%       'ExperimentName' - 实验名称 (default: '')
%
%   返回的unifiedData包含标准化的字段：
%       - imageName: 图像名称
%       - qualityScore: 质量评分
%       - defectCoverageLocal: 局部缺陷覆盖率 (%)
%       - defectCoverageGlobal: 全局缺陷覆盖率 (%)
%       - lineCount: 检测到的直线数量
%       - circleCount: 检测到的圆形数量
%       - avgLineLength: 平均直线长度
%       - totalLineLength: 总直线长度
%       - avgCircleRadius: 平均圆形半径
%       - totalCircleArea: 圆形总面积
%       - enhancementContrast: 增强后对比度
%       - segmentationAccuracy: 分割准确度
%       - edgeStrength: 边缘强度

    % 解析输入参数
    p = inputParser;
    addRequired(p, 'results', @isstruct);
    addParameter(p, 'ImagePath', '', @ischar);
    addParameter(p, 'Parameters', struct(), @isstruct);
    addParameter(p, 'ExperimentName', '', @ischar);
    parse(p, results, varargin{:});
    
    % 提取图像名称
    if ~isempty(p.Results.ImagePath)
        [~, imageName, ext] = fileparts(p.Results.ImagePath);
        unifiedData.imageName = [imageName, ext];
    else
        unifiedData.imageName = p.Results.ExperimentName;
    end
    
    % 获取核心指标（复用现有函数）
    summary = ceramic_results_summary(results);
    performance = ceramic_performance_metrics(results);
    
    % ========== 核心质量指标 ==========
    unifiedData.qualityScore = performance.qualityScore;
    unifiedData.defectCoverageLocal = performance.defectCoverage.local;
    unifiedData.defectCoverageGlobal = performance.defectCoverage.global;
    
    % ========== 几何特征统计 ==========
    % 直线统计
    unifiedData.lineCount = summary.lineDetection.count;
    unifiedData.avgLineLength = summary.lineDetection.avgLength;
    unifiedData.totalLineLength = summary.lineDetection.totalLength;
    
    % 圆形统计
    unifiedData.circleCount = summary.circleDetection.count;
    unifiedData.avgCircleRadius = summary.circleDetection.avgRadius;
    unifiedData.totalCircleArea = summary.circleDetection.totalArea;
    
    % ========== 图像处理质量指标 ==========
    % 边缘检测统计（使用现有字段）
    unifiedData.cannyEdgePixels = summary.edgeDetection.cannyEdgePixels;
    unifiedData.sobelEdgePixels = summary.edgeDetection.sobelEdgePixels;
    unifiedData.logEdgePixels = summary.edgeDetection.logEdgePixels;
    
    % 区域统计
    unifiedData.defectRegionCountGlobal = summary.defectRegions.global.count;
    unifiedData.defectRegionCountLocal = summary.defectRegions.local.count;
    unifiedData.avgDefectAreaLocal = summary.defectRegions.local.avgArea;
    
    % ========== 参数记录 ==========
    % 只记录关键参数，避免冗余
    if ~isempty(fieldnames(p.Results.Parameters))
        params = p.Results.Parameters;
        if isfield(params, 'ClipLimit')
            unifiedData.paramClipLimit = params.ClipLimit;
        end
        if isfield(params, 'NumTiles')
            if iscell(params.NumTiles)
                unifiedData.paramNumTiles = params.NumTiles{1}(1);
            elseif length(params.NumTiles) > 0
                unifiedData.paramNumTiles = params.NumTiles(1);
            end
        end
        if isfield(params, 'LocalBlockSize')
            if iscell(params.LocalBlockSize)
                unifiedData.paramBlockSize = params.LocalBlockSize{1}(1);
            elseif length(params.LocalBlockSize) > 0
                unifiedData.paramBlockSize = params.LocalBlockSize(1);
            end
        end
        if isfield(params, 'LineMinLength')
            unifiedData.paramLineMinLength = params.LineMinLength;
        end
    end
    
    % ========== 时间戳 ==========
    unifiedData.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
end

