% CLEANUP_PROJECT_FINAL - 最终项目整理脚本
%
% 执行彻底的项目整理，包括：
% 1. 删除旧run目录
% 2. 移动测试脚本到tools/
% 3. 移动旧文档到versions/

function cleanup_project_final()
    fprintf('===== 项目最终整理 =====\n\n');
    
    %% 1. 删除旧run目录
    fprintf('1. 清理旧run目录...\n');
    oldRun = 'run_20251004_123723';
    if exist(oldRun, 'dir')
        fprintf('   删除: %s (缺少binaryGlobalClean字段)\n', oldRun);
        rmdir(oldRun, 's');
        fprintf('   ✓ 已删除\n');
    else
        fprintf('   ⚠ 目录不存在，跳过\n');
    end
    
    %% 2. 移动测试脚本到tools/
    fprintf('\n2. 整理测试脚本...\n');
    toolsDir = 'tools';
    if ~exist(toolsDir, 'dir')
        mkdir(toolsDir);
    end
    
    testScripts = {
        'test_critical_fixes.m',
        'wait_and_visualize.m'
    };
    
    for i = 1:length(testScripts)
        script = testScripts{i};
        if exist(script, 'file')
            targetPath = fullfile(toolsDir, script);
            movefile(script, targetPath);
            fprintf('   ✓ %s -> tools/\n', script);
        end
    end
    
    %% 3. 移动旧文档到versions/
    fprintf('\n3. 整理旧文档...\n');
    docsTarget = fullfile('..', 'versions', 'v3.0_roi_detection', 'docs');
    if ~exist(docsTarget, 'dir')
        mkdir(docsTarget);
    end
    
    oldDocs = {
        'CIRCLE_FIX_OPTIONS.md',
        'V3_FINAL_SOLUTION.md',
        'V3_OPTIMIZATION_LOG.md',
        'V3_PROBLEM_DIAGNOSIS.md'
    };
    
    for i = 1:length(oldDocs)
        doc = oldDocs{i};
        if exist(doc, 'file')
            targetPath = fullfile(docsTarget, doc);
            movefile(doc, targetPath);
            fprintf('   ✓ %s -> versions/v3.0_roi_detection/docs/\n', doc);
        end
    end
    
    fprintf('\n===== matlab目录整理完成 =====\n');
    fprintf('保留文件:\n');
    fprintf('  - 21个.m代码文件\n');
    fprintf('  - 1个run目录（run_20251004_201511）\n');
    fprintf('  - tools/目录（包含辅助工具）\n');
end

