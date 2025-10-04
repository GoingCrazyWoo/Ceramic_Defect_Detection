%% 测试ROI检测效果
% 用于验证detect_ceramic_roi是否能检测到所有白色管子

fprintf('===== 测试陶瓷管ROI检测 =====\n\n');

%% 加载测试图像
testImage = '../samples/20250929_defect_01.jpg';
fprintf('加载测试图像: %s\n', testImage);

I = imread(testImage);
if size(I, 3) == 3
    Igray = rgb2gray(I);
else
    Igray = I;
end
Igray = im2double(Igray);

fprintf('图像尺寸: %d × %d\n\n', size(Igray, 1), size(Igray, 2));

%% 测试不同的参数组合

fprintf('【测试1】新策略 - 保持独立管子（推荐）\n');
roiMask1 = detect_ceramic_roi(Igray);

fprintf('\n【测试2】更大的垂直范围 + 独立管子\n');
roiMask2 = detect_ceramic_roi(Igray, ...
    'HeightRange', [0.1, 0.9], ...
    'KeepSeparateTubes', true);

fprintf('\n【测试3】更低亮度阈值 + 独立管子\n');
roiMask3 = detect_ceramic_roi(Igray, ...
    'BrightnessThreshold', 0.15, ...
    'HeightRange', [0.1, 0.9], ...
    'KeepSeparateTubes', true);

fprintf('\n【测试4】旧策略 - 连接所有管子（对比用）\n');
roiMask4 = detect_ceramic_roi(Igray, ...
    'KeepSeparateTubes', false, ...
    'MorphCloseRadius', 40);

%% 可视化对比

figure('Name', 'ROI检测效果对比', 'Position', [100, 100, 1600, 1000]);

% 原始图像
subplot(2,3,1);
imshow(Igray);
title('原始图像', 'FontSize', 14);

% 测试1
subplot(2,3,2);
imshow(roiMask1);
title(sprintf('测试1: 默认参数\nROI覆盖: %.1f%%', sum(roiMask1(:))/numel(roiMask1)*100), 'FontSize', 12);

% 测试2
subplot(2,3,3);
imshow(roiMask2);
title(sprintf('测试2: 大范围[0.1,0.9]\nROI覆盖: %.1f%%', sum(roiMask2(:))/numel(roiMask2)*100), 'FontSize', 12);

% 测试3
subplot(2,3,4);
imshow(roiMask3);
title(sprintf('测试3: 低阈值(0.15)+大范围\nROI覆盖: %.1f%%', sum(roiMask3(:))/numel(roiMask3)*100), 'FontSize', 12);

% 测试4
subplot(2,3,5);
imshow(roiMask4);
title(sprintf('测试4: 旧策略（连通）\nROI覆盖: %.1f%%', sum(roiMask4(:))/numel(roiMask4)*100), 'FontSize', 12);

% ROI叠加在原图上
subplot(2,3,6);
imshow(Igray); hold on;
% 绘制ROI边界（使用测试3的结果 - 最全面的）
boundaries = bwboundaries(roiMask3);
for k = 1:length(boundaries)
    boundary = boundaries{k};
    plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 2);
end
hold off;
title(sprintf('ROI叠加（绿色边界）\n%d个独立区域', length(boundaries)), 'FontSize', 12);

%% 详细分析：是否覆盖所有管子

fprintf('\n===== ROI覆盖率分析 =====\n');
fprintf('测试1（默认）：%.1f%%\n', sum(roiMask1(:))/numel(roiMask1)*100);
fprintf('测试2（低阈值）：%.1f%%\n', sum(roiMask2(:))/numel(roiMask2)*100);
fprintf('测试3（大范围）：%.1f%%\n', sum(roiMask3(:))/numel(roiMask3)*100);
fprintf('测试4（去遮挡）：%.1f%%\n', sum(roiMask4(:))/numel(roiMask4)*100);

fprintf('\n推荐：');
if sum(roiMask3(:))/numel(roiMask3) > 0.3 && sum(roiMask3(:))/numel(roiMask3) < 0.7
    fprintf('测试3效果最好（低阈值0.15 + 大范围[0.1,0.9]）✅\n');
    fprintf('覆盖率在合理范围内，应该能覆盖所有管子\n');
    fprintf('注意：管子之间有缝隙是正常的，不需要连接\n');
elseif sum(roiMask2(:))/numel(roiMask2) > 0.3 && sum(roiMask2(:))/numel(roiMask2) < 0.7
    fprintf('测试2效果较好（大范围[0.1,0.9]）✅\n');
    fprintf('如果还有管子未覆盖，使用测试3的参数\n');
else
    fprintf('需要根据可视化结果手动调整参数\n');
end

fprintf('\n请查看图形窗口，确认ROI是否覆盖了所有白色管子！\n');
fprintf('如果有管子未被覆盖，请调整参数并重新运行\n');

