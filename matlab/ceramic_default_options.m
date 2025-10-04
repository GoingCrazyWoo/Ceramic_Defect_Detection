function defaults = ceramic_default_options()
%CERAMIC_DEFAULT_OPTIONS 陶瓷缺陷检测的默认参数配置
%   DEFAULTS = CERAMIC_DEFAULT_OPTIONS() 返回默认的参数结构体
%
%   v3.0-R4 - 最终优化方案（严格ROI + 固定阈值）：
%   - ROIBrightnessThreshold: 0.30 → 0.50 (只保留白色管子本体)
%   - 固定阈值: 0.25 (替代Otsu，只检测明显黑色缺陷)
%   - MorphOpenRadius: 3 → 8 (强化去噪)
%   - 预期效果：缺陷率67.88% → 10-20%，质量分47.5 → 75-85

    defaults = struct( ...
        'ClipLimit', 0.015, ...         % CLAHE对比度限制（v3.0: 降低以减少过度检测）
        'NumTiles', [16 16], ...        % CLAHE分块数量
        'LocalBlockSize', [128 128], ...% v3.0优化: 增大到128（平衡速度和质量）
        'LocalOverlap', [32 32], ...    % v3.0优化: 配合块大小调整
        'MorphOpenRadius', 8, ...       % v3.0-R4: 增大到8，去除更多噪点
        'CannyThreshold', [], ...       % Canny边缘阈值（自动）
        'CannySigma', 1.0, ...          % Canny高斯模糊
        'SobelThreshold', 0.02, ...     % Sobel边缘阈值
        'LineFillGap', 15, ...          % 霍夫直线间隙填充
        'LineMinLength', 50, ...        % 最小直线长度
        'CircleRadius', [6 20], ...     % 保留（已废弃，用于兼容）
        'CircleSensitivity', 0.90, ...  % 保留（已废弃，用于兼容）
        'CircleEdgeThreshold', 0.10, ...% 保留（已废弃，用于兼容）
        'MinDefectArea', 50, ...        % v3.0-R6: 最小缺陷面积（像素）
        'MaxDefectArea', 10000 ...      % v3.0-R6: 最大缺陷面积（像素）
    );
end
