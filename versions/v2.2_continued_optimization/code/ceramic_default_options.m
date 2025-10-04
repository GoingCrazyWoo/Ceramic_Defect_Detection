function defaults = ceramic_default_options()
%CERAMIC_DEFAULT_OPTIONS 陶瓷缺陷检测的默认参数配置
%   DEFAULTS = CERAMIC_DEFAULT_OPTIONS() 返回默认的参数结构体
%
%   v2.2 - 持续优化（基于v2.1测试结果）：
%   - LocalBlockSize: [256 256] → [384 384] (继续降低缺陷率53.9%)
%   - MorphOpenRadius: 3 → 5 (加强形态学去噪)
%   - ClipLimit: 0.02 → 0.025 (进一步提升对比度和质量分)
%   - 保持v2.1的圆形检测优势（36个，↓90%）

    defaults = struct( ...
        'ClipLimit', 0.025, ...         % CLAHE对比度限制（v2.2: 从0.02提高到0.025）
        'NumTiles', [16 16], ...        % CLAHE分块数量（保持）
        'LocalBlockSize', [384 384], ...% 局部Otsu块大小（v2.2: 从[256 256]增大到[384 384]）
        'LocalOverlap', [96 96], ...    % 局部Otsu重叠（v2.2: 从[64 64]增大到[96 96]）
        'MorphOpenRadius', 5, ...       % 形态学开运算半径（v2.2: 从3增大到5）
        'CannyThreshold', [], ...       % Canny边缘阈值（自动）
        'CannySigma', 1.0, ...          % Canny高斯模糊
        'SobelThreshold', 0.02, ...     % Sobel边缘阈值
        'LineFillGap', 15, ...          % 霍夫直线间隙填充
        'LineMinLength', 50, ...        % 最小直线长度
        'CircleRadius', [8 30], ...     % 圆形半径范围（保持v2.1设置）
        'CircleSensitivity', 0.85, ...  % 圆形检测灵敏度（保持v2.1设置）
        'CircleEdgeThreshold', 0.15 ... % 圆形边缘阈值（保持v2.1设置）
    );
end
