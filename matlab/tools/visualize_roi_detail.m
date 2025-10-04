%% ROI检测详细可视化工具
% 帮助你精确查看ROI是否正确覆盖所有管子

fprintf('===== ROI详细可视化 =====\n\n');

%% 加载测试图像
testImage = '../samples/20250929_defect_01.jpg';
fprintf('加载图像: %s\n', testImage);

I = imread(testImage);
if size(I, 3) == 3
    Igray = rgb2gray(I);
else
    Igray = I;
end
Igray = im2double(Igray);

[H, W] = size(Igray);
fprintf('图像尺寸: %d × %d\n\n', H, W);

%% 测试最优参数
fprintf('测试当前最优参数...\n');
roiMask = detect_ceramic_roi(Igray, ...
    'BrightnessThreshold', 0.15, ...
    'HeightRange', [0.1, 0.9], ...
    'KeepSeparateTubes', true);

%% 创建详细可视化

figure('Name', 'ROI详细分析 - 请仔细检查', 'Position', [50, 50, 1800, 1000]);

% 1. 原始图像
subplot(2,4,1);
imshow(Igray);
title('1. 原始灰度图', 'FontSize', 12, 'FontWeight', 'bold');

% 2. 亮度分布（查看哪些区域亮）
subplot(2,4,2);
imagesc(Igray); colormap(gca, 'gray'); colorbar;
title('2. 亮度分布', 'FontSize', 12);
xlabel('亮的区域=管子，暗的=背景');

% 3. ROI掩码（黑白）
subplot(2,4,3);
imshow(roiMask);
title(sprintf('3. ROI掩码\n覆盖率: %.1f%%', sum(roiMask(:))/numel(roiMask)*100), ...
      'FontSize', 12, 'FontWeight', 'bold');

% 4. ROI边界叠加
subplot(2,4,4);
imshow(Igray); hold on;
boundaries = bwboundaries(roiMask);
for k = 1:length(boundaries)
    boundary = boundaries{k};
    plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 2);
end
hold off;
title(sprintf('4. ROI边界（绿色）\n%d个区域', length(boundaries)), 'FontSize', 12);

% 5. 彩色叠加（红色=ROI内，原图可见）
subplot(2,4,5);
overlay = cat(3, Igray, Igray, Igray);
overlay(:,:,1) = overlay(:,:,1) + double(roiMask) * 0.3;  % 红色半透明
imshow(overlay);
title('5. ROI半透明叠加（红色）', 'FontSize', 12);
xlabel('红色区域 = ROI内');

% 6. 只显示ROI内的部分
subplot(2,4,6);
roiOnly = Igray .* double(roiMask);
imshow(roiOnly);
title('6. 只保留ROI内的图像', 'FontSize', 12);
xlabel('黑色区域会被排除');

% 7. 水平切片分析（中间一行）
subplot(2,4,7);
midRow = round(H/2);
plot(Igray(midRow, :), 'b-', 'LineWidth', 1.5); hold on;
plot(double(roiMask(midRow, :)) * max(Igray(midRow, :)), 'r-', 'LineWidth', 2);
hold off;
legend('原始亮度', 'ROI掩码（红色）', 'Location', 'best');
title(sprintf('7. 水平切片分析（第%d行）', midRow), 'FontSize', 12);
xlabel('列位置'); ylabel('亮度');
grid on;

% 8. 垂直切片分析（中间一列）
subplot(2,4,8);
midCol = round(W/2);
plot(1:H, Igray(:, midCol), 'b-', 'LineWidth', 1.5); hold on;
plot(1:H, double(roiMask(:, midCol)) * max(Igray(:, midCol)), 'r-', 'LineWidth', 2);
hold off;
legend('原始亮度', 'ROI掩码（红色）', 'Location', 'best');
title(sprintf('8. 垂直切片分析（第%d列）', midCol), 'FontSize', 12);
xlabel('行位置'); ylabel('亮度');
grid on;

%% 详细统计分析

fprintf('\n===== 详细统计分析 =====\n');

% 连通区域分析
cc = bwconncomp(roiMask);
fprintf('检测到的独立区域数: %d\n', cc.NumObjects);

if cc.NumObjects > 0
    areas = cellfun(@numel, cc.PixelIdxList);
    [sortedAreas, ~] = sort(areas, 'descend');
    
    fprintf('\n各区域面积（从大到小）:\n');
    for i = 1:min(15, length(sortedAreas))
        areaRatio = sortedAreas(i) / (H*W) * 100;
        fprintf('  区域%2d: %.2f%% (%.0f像素)\n', i, areaRatio, sortedAreas(i));
    end
    
    if length(sortedAreas) > 15
        fprintf('  ... 还有%d个更小的区域\n', length(sortedAreas) - 15);
    end
end

% ROI覆盖率分析
roiCoverage = sum(roiMask(:)) / numel(roiMask) * 100;
fprintf('\n总ROI覆盖率: %.1f%%\n', roiCoverage);

% 亮度分析
brightPixels = sum(Igray(:) > 0.15);
brightRatio = brightPixels / numel(Igray) * 100;
fprintf('亮度>0.15的像素: %.1f%%\n', brightRatio);

%% 诊断和建议

fprintf('\n===== 诊断和建议 =====\n');

% 判断问题
if roiCoverage > 65
    fprintf('⚠️ 问题：ROI覆盖率过高（%.1f%%）\n', roiCoverage);
    fprintf('\n可能原因：\n');
    fprintf('  1. 亮度阈值太低，包含了管子之间的缝隙\n');
    fprintf('  2. 形态学处理连接了不应该连接的区域\n');
    fprintf('  3. 位置范围太大\n');
    
    fprintf('\n建议方案：\n');
    fprintf('  方案A: 提高亮度阈值\n');
    fprintf('    roiMask = detect_ceramic_roi(Igray, ...\n');
    fprintf('        ''BrightnessThreshold'', 0.25, ...  %% 从0.15提高\n');
    fprintf('        ''HeightRange'', [0.1, 0.9], ...\n');
    fprintf('        ''KeepSeparateTubes'', true);\n\n');
    
    fprintf('  方案B: 更严格的形态学处理\n');
    fprintf('    roiMask = detect_ceramic_roi(Igray, ...\n');
    fprintf('        ''BrightnessThreshold'', 0.20, ...\n');
    fprintf('        ''MorphOpenRadius'', 20, ...  %% 增大去噪半径\n');
    fprintf('        ''MinAreaRatio'', 0.08);\n\n');
    
elseif roiCoverage < 30
    fprintf('⚠️ 问题：ROI覆盖率过低（%.1f%%）\n', roiCoverage);
    fprintf('可能漏检了部分管子\n');
    fprintf('\n建议：降低亮度阈值或扩大垂直范围\n');
    
else
    fprintf('✅ ROI覆盖率合理（%.1f%%）\n', roiCoverage);
    fprintf('\n请查看可视化窗口确认：\n');
    fprintf('  1. 子图4: 绿色边界是否覆盖所有白色管子？\n');
    fprintf('  2. 子图5: 红色区域是否只包含管子？\n');
    fprintf('  3. 子图6: 黑色区域（背景）是否正确排除？\n');
end

fprintf('\n===== 检查清单 =====\n');
fprintf('请在可视化窗口中确认：\n');
fprintf('  □ 所有白色管子都被绿色边界包围（子图4）\n');
fprintf('  □ 管子之间的黑色缝隙没有被包含（子图6）\n');
fprintf('  □ 深色背景区域被排除在外（子图6）\n');
fprintf('  □ ROI区域数量合理（约10-15个，对应管子数量）\n');

fprintf('\n提示：如果管子之间的缝隙被包含，说明亮度阈值太低\n');
fprintf('      建议从0.15提高到0.20或0.25重新测试\n');

