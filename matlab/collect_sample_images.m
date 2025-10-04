function [allImages, sampleDir] = collect_sample_images()
%COLLECT_SAMPLE_IMAGES 收集样本图像文件（独立工具函数）
%   [ALLIMAGES, SAMPLEDIR] = COLLECT_SAMPLE_IMAGES() 自动查找并返回所有样本图像
%   支持从 samples/ 或 ../samples/ 目录查找
%   
%   这是一个独立的工具函数，可被任何脚本调用，避免代码重复

    % 检查samples文件夹（支持相对路径）
    sampleDir = 'samples';
    if ~isfolder(sampleDir)
        sampleDir = '../samples';
        if ~isfolder(sampleDir)
            error('请先创建samples文件夹并放入测试图片');
        end
    end

    % 获取测试图片列表
    imageExts = {'*.png', '*.jpg', '*.jpeg', '*.bmp', '*.tiff'};
    allImages = [];
    for i = 1:length(imageExts)
        images = dir(fullfile(sampleDir, imageExts{i}));
        % 过滤掉 . 和 .. 目录
        images = images(~ismember({images.name}, {'.', '..'}));
        allImages = [allImages; images];
    end

    if isempty(allImages)
        error('samples文件夹中没有找到测试图片，请添加陶瓷缺陷图片');
    end
end
