function defaults = ceramic_default_options()
%CERAMIC_DEFAULT_OPTIONS 陶瓷缺陷检测的默认参数配置
%   DEFAULTS = CERAMIC_DEFAULT_OPTIONS() 返回默认的参数结构体
%
%   v2.1 - 已根据6000x8000大图像检测结果优化参数：
%   - LocalBlockSize: [64 64] → [256 256] (解决57%缺陷覆盖率过高问题)
%   - CircleSensitivity: 0.9 → 0.85 (解决350+圆形误检过多问题)
%   - ClipLimit: 0.015 → 0.02 (改善-24%对比度问题)
%   - CircleRadius: [6 40] → [8 30] (聚焦真实缺陷尺寸)

    defaults = struct( ...
        'ClipLimit', 0.02, ...          % CLAHE对比度限制（从0.015提高，改善对比度）
        'NumTiles', [16 16], ...        % CLAHE分块数量（从[8 8]增加，更精细）
        'LocalBlockSize', [256 256], ...% 局部Otsu块大小（从[64 64]增大，适配6000x8000大图）
        'LocalOverlap', [64 64], ...    % 局部Otsu重叠（从[16 16]增大）
        'MorphOpenRadius', 3, ...       % 形态学开运算半径（从2增大，更好去噪）
        'CannyThreshold', [], ...       % Canny边缘阈值（自动）
        'CannySigma', 1.0, ...          % Canny高斯模糊
        'SobelThreshold', 0.02, ...     % Sobel边缘阈值
        'LineFillGap', 15, ...          % 霍夫直线间隙填充（从10增大）
        'LineMinLength', 50, ...        % 最小直线长度（从30提高，减少误检）
        'CircleRadius', [8 30], ...     % 圆形半径范围（从[6 40]缩小，聚焦真实缺陷）
        'CircleSensitivity', 0.85, ...  % 圆形检测灵敏度（从0.9降低，减少误检）
        'CircleEdgeThreshold', 0.15 ... % 圆形边缘阈值（从0.1提高，过滤弱边缘）
    );
end
