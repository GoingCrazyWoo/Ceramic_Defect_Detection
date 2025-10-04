function performance = ceramic_performance_metrics(results)
%CERAMIC_PERFORMANCE_METRICS Compute scalar performance indicators.
%   PERFORMANCE = CERAMIC_PERFORMANCE_METRICS(RESULTS) derives coverage,
%   contrast improvement, edge densities and an aggregate quality score to
%   support experiment logging and reports.
%
%   v3.0新增：支持ROI约束的指标计算

    performance = struct();

    imageSize = numel(results.original);
    
    % v3.0：如果启用了ROI，计算相对于ROI的缺陷覆盖率
    if isfield(results, 'roiMask') && ~isempty(results.roiMask)
        roiSize = sum(results.roiMask(:));
        if roiSize > 0
            % 相对于ROI的缺陷率（这是真实的缺陷率）
            performance.defectCoverage.global = sum(results.binaryGlobal(:)) / roiSize * 100;
            performance.defectCoverage.local = sum(results.binaryLocal(:)) / roiSize * 100;
            % 记录ROI覆盖率
            performance.roiCoverage = roiSize / imageSize * 100;
        else
            % ROI为空的情况
            performance.defectCoverage.global = 0;
            performance.defectCoverage.local = 0;
            performance.roiCoverage = 0;
        end
    else
        % v2.x兼容：相对于整张图的缺陷率
        performance.defectCoverage.global = sum(results.binaryGlobal(:)) / imageSize * 100;
        performance.defectCoverage.local = sum(results.binaryLocal(:)) / imageSize * 100;
        performance.roiCoverage = 100;  % 整张图都是ROI
    end

    % v3.0修复：边缘密度应相对于ROI计算，避免ROI很窄时被低估
    performance.edgeDensity = struct();
    if isfield(results, 'roiMask') && ~isempty(results.roiMask)
        roiSize = sum(results.roiMask(:));
        if roiSize > 0
            % 相对于ROI的边缘密度（更准确）
            performance.edgeDensity.canny = sum(results.edgeMaps.canny(:)) / roiSize * 100;
            performance.edgeDensity.sobel = sum(results.edgeMaps.sobel(:)) / roiSize * 100;
            performance.edgeDensity.log = sum(results.edgeMaps.log(:)) / roiSize * 100;
        else
            performance.edgeDensity.canny = 0;
            performance.edgeDensity.sobel = 0;
            performance.edgeDensity.log = 0;
        end
    else
        % v2.x兼容：相对于整张图
        performance.edgeDensity.canny = sum(results.edgeMaps.canny(:)) / imageSize * 100;
        performance.edgeDensity.sobel = sum(results.edgeMaps.sobel(:)) / imageSize * 100;
        performance.edgeDensity.log = sum(results.edgeMaps.log(:)) / imageSize * 100;
    end

    originalContrast = std(results.original(:));
    enhancedContrast = std(results.enhanced(:));
    performance.contrastImprovement = (enhancedContrast - originalContrast) / max(originalContrast, eps) * 100;

    globalLocalConsistency = 100 - abs(performance.defectCoverage.global - performance.defectCoverage.local);
    edgeQuality = min(performance.edgeDensity.canny * 10, 100);
    performance.qualityScore = max(0, min(100, globalLocalConsistency * 0.4 + edgeQuality * 0.6));
end
