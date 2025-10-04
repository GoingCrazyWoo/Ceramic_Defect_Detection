function summary = ceramic_results_summary(results)
%CERAMIC_RESULTS_SUMMARY Aggregate structural metrics from pipeline results.
%   SUMMARY = CERAMIC_RESULTS_SUMMARY(RESULTS) computes region counts, sizes,
%   line and circle statistics, and edge pixel totals shared across logging and
%   reporting utilities.

    summary = struct();

    summary.imageSize = size(results.original);
    summary.otsuGlobalThreshold = results.otsuGlobalLevel;

    % Connected component statistics for global and local masks
    cc_global = bwconncomp(results.binaryGlobal);
    cc_local = bwconncomp(results.binaryLocal);

    summary.defectRegions.global = buildRegionStats(cc_global);
    summary.defectRegions.local = buildRegionStats(cc_local);

    % Line statistics from Hough detection
    summary.lineDetection = buildLineStats(results);

    % Circular defect statistics
    summary.circleDetection = buildCircleStats(results);

    % Edge pixel counts for reference
    summary.edgeDetection = struct();
    summary.edgeDetection.cannyEdgePixels = sum(results.edgeMaps.canny(:));
    summary.edgeDetection.sobelEdgePixels = sum(results.edgeMaps.sobel(:));
    summary.edgeDetection.logEdgePixels = sum(results.edgeMaps.log(:));
end

function stats = buildRegionStats(cc)
    stats = struct('count', cc.NumObjects, 'totalArea', 0, 'avgArea', 0, 'maxArea', 0);
    if cc.NumObjects > 0
        areas = cellfun(@numel, cc.PixelIdxList);
        stats.totalArea = sum(areas);
        stats.avgArea = mean(areas);
        stats.maxArea = max(areas);
    end
end

function lineStats = buildLineStats(results)
    lineStats = struct('count', numel(results.houghLines.lines), ...
        'totalLength', 0, 'avgLength', 0, 'maxLength', 0);
    if lineStats.count > 0
        lengths = zeros(1, lineStats.count);
        for i = 1:lineStats.count
            p1 = results.houghLines.lines(i).point1;
            p2 = results.houghLines.lines(i).point2;
            lengths(i) = norm(p2 - p1);
        end
        lineStats.totalLength = sum(lengths);
        lineStats.avgLength = mean(lengths);
        lineStats.maxLength = max(lengths);
    end
end

function circleStats = buildCircleStats(results)
    circleStats = struct('count', numel(results.circles.radii), ...
        'avgRadius', 0, 'minRadius', 0, 'maxRadius', 0, 'totalArea', 0);
    if circleStats.count > 0
        circleStats.avgRadius = mean(results.circles.radii);
        circleStats.minRadius = min(results.circles.radii);  % 添加minRadius字段
        circleStats.maxRadius = max(results.circles.radii);
        circleStats.totalArea = sum(pi * results.circles.radii.^2);
    end
end
