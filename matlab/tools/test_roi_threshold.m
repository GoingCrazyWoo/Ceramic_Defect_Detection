%% 测试不同亮度阈值的效果
% 帮助找到最优的亮度阈值，确保只包含管子

fprintf('===== 测试不同亮度阈值 =====\n\n');

%% 加载图像
testImage = '../samples/20250929_defect_01.jpg';
I = imread(testImage);
if size(I, 3) == 3
    Igray = rgb2gray(I);
else
    Igray = I;
end
Igray = im2double(Igray);

%% 测试一系列阈值
thresholds = [0.10, 0.15, 0.20, 0.25, 0.30, 0.35];
roiMasks = cell(length(thresholds), 1);
coverages = zeros(length(thresholds), 1);
numRegions = zeros(length(thresholds), 1);

fprintf('测试阈值范围: %.2f - %.2f\n\n', min(thresholds), max(thresholds));

for i = 1:length(thresholds)
    thresh = thresholds(i);
    fprintf('测试阈值 %.2f...\n', thresh);
    
    roiMasks{i} = detect_ceramic_roi(Igray, ...
        'BrightnessThreshold', thresh, ...
        'HeightRange', [0.1, 0.9], ...
        'KeepSeparateTubes', true, ...
        'MinAreaRatio', 0.05);
    
    coverages(i) = sum(roiMasks{i}(:)) / numel(roiMasks{i}) * 100;
    cc = bwconncomp(roiMasks{i});
    numRegions(i) = cc.NumObjects;
    
    fprintf('  → 覆盖率: %.1f%%, 区域数: %d\n\n', coverages(i), numRegions(i));
end

%% 可视化对比

figure('Name', '亮度阈值对比 - 找到最优值', 'Position', [50, 50, 1800, 1000]);

% 绘制所有结果
for i = 1:length(thresholds)
    subplot(2, length(thresholds), i);
    imshow(roiMasks{i});
    title(sprintf('阈值=%.2f\n覆盖%.1f%%', thresholds(i), coverages(i)), 'FontSize', 11);
    
    subplot(2, length(thresholds), i + length(thresholds));
    imshow(Igray); hold on;
    boundaries = bwboundaries(roiMasks{i});
    for k = 1:length(boundaries)
        boundary = boundaries{k};
        plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 1.5);
    end
    hold off;
    title(sprintf('%d个区域', numRegions(i)), 'FontSize', 11);
end

%% 绘制趋势图

figure('Name', '阈值选择指导', 'Position', [100, 100, 1200, 500]);

subplot(1,2,1);
plot(thresholds, coverages, 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
hold on;
% 理想范围
yline(40, 'g--', '理想下限40%', 'LineWidth', 1.5);
yline(55, 'r--', '理想上限55%', 'LineWidth', 1.5);
hold off;
xlabel('亮度阈值', 'FontSize', 12);
ylabel('ROI覆盖率 (%)', 'FontSize', 12);
title('ROI覆盖率 vs 亮度阈值', 'FontSize', 14);
grid on;
legend('实际覆盖率', '理想下限', '理想上限', 'Location', 'best');

subplot(1,2,2);
plot(thresholds, numRegions, 'r-s', 'LineWidth', 2, 'MarkerSize', 8);
hold on;
yline(10, 'g--', '预期管子数下限', 'LineWidth', 1.5);
yline(15, 'r--', '预期管子数上限', 'LineWidth', 1.5);
hold off;
xlabel('亮度阈值', 'FontSize', 12);
ylabel('检测到的区域数', 'FontSize', 12);
title('区域数量 vs 亮度阈值', 'FontSize', 14);
grid on;
legend('检测区域数', '预期下限', '预期上限', 'Location', 'best');

%% 推荐最优阈值

fprintf('\n===== 推荐结果 =====\n\n');

% 找到覆盖率在40%-55%之间的阈值
idealIdx = find(coverages >= 40 & coverages <= 55);

if ~isempty(idealIdx)
    bestIdx = idealIdx(1);  % 选择第一个满足的
    fprintf('✅ 推荐阈值: %.2f\n', thresholds(bestIdx));
    fprintf('   - ROI覆盖率: %.1f%%（理想范围）\n', coverages(bestIdx));
    fprintf('   - 检测区域数: %d\n', numRegions(bestIdx));
    fprintf('\n使用方法：\n');
    fprintf('roiMask = detect_ceramic_roi(Igray, ...\n');
    fprintf('    ''BrightnessThreshold'', %.2f, ...\n', thresholds(bestIdx));
    fprintf('    ''HeightRange'', [0.1, 0.9], ...\n');
    fprintf('    ''KeepSeparateTubes'', true);\n');
else
    % 找到最接近理想范围的
    [~, bestIdx] = min(abs(coverages - 47.5));  % 47.5是40-55的中点
    fprintf('⚠️ 没有完全理想的阈值，推荐最接近的:\n');
    fprintf('   阈值: %.2f\n', thresholds(bestIdx));
    fprintf('   - ROI覆盖率: %.1f%%\n', coverages(bestIdx));
    fprintf('   - 检测区域数: %d\n', numRegions(bestIdx));
    
    if coverages(bestIdx) > 55
        fprintf('\n   注意：覆盖率偏高，可能包含了管子之间的缝隙\n');
        fprintf('   建议：进一步提高阈值或增大MorphOpenRadius\n');
    elseif coverages(bestIdx) < 40
        fprintf('\n   注意：覆盖率偏低，可能漏检了部分管子\n');
        fprintf('   建议：降低阈值或检查HeightRange设置\n');
    end
end

fprintf('\n对比表：\n');
fprintf('阈值    覆盖率    区域数    评价\n');
fprintf('----------------------------------------\n');
for i = 1:length(thresholds)
    if coverages(i) >= 40 && coverages(i) <= 55
        status = '✅ 理想';
    elseif coverages(i) > 55
        status = '⚠️ 偏高';
    else
        status = '⚠️ 偏低';
    end
    fprintf('%.2f     %.1f%%     %2d        %s\n', ...
        thresholds(i), coverages(i), numRegions(i), status);
end

fprintf('\n请查看可视化窗口，选择看起来最准确的阈值！\n');

