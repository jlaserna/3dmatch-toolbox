% Script to evaluate .log files for the geometric registration benchmarks,
% in the same spirit as Choi et al 2015. Please see:
%
% http://redwood-data.org/indoor/regbasic.html
% https://github.com/qianyizh/ElasticReconstruction/tree/master/Matlab_Toolbox

originalPath = pwd;

descriptorsNames = {'CliReg', 'CliRegMutual', 'TEASER3DMatch', 'RANSAC', 'FGR'};

% Locations of evaluation files
dataPath = '../../../../output/3DMatch/3DMatch';

% % Synthetic data benchmark
% sceneList = {'iclnuim-livingroom1-evaluation' ...
%              'iclnuim-livingroom2-evaluation' ...
%              'iclnuim-office1-evaluation' ...
%              'iclnuim-office2-evaluation'};
         
% Real data benchmark
sceneList = {'kitchen', ...
             'sun3d-home_at-home_at_scan1_2013_jan_1', ...
             'sun3d-home_md-home_md_scan9_2012_sep_30', ...
             'sun3d-hotel_uc-scan3', ...
             'sun3d-hotel_umd-maryland_hotel1', ...
             'sun3d-hotel_umd-maryland_hotel3', ...
             'sun3d-mit_76_studyroom-76-1studyroom2', ...
             'sun3d-mit_lab_hj-lab_hj_tea_nov_2_2012_scan1_erika'};

% For each scene in the datapath, execute the Python script to generate the auxiliary files with absolute paths
for sceneIdx = 1:length(sceneList)
    scenePath = fullfile(dataPath,sceneList{sceneIdx});
    % Copy the Python script to the scene path
    copyfile('process.py', scenePath);
    % Copy the gt.log and gt.info files to the scene path
    copyfile(fullfile('../../../../data/3DMatch/', sceneList{sceneIdx}, 'gt.log'), scenePath);
    copyfile(fullfile('../../../../data/3DMatch/', sceneList{sceneIdx}, 'gt.info'), scenePath);
    % Cd to the scene path
    cd(scenePath);
    for descriptorIdx = 1:length(descriptorsNames)
        descriptorName = descriptorsNames{descriptorIdx};
        system(['python3 process.py ' descriptorName '.log']);
    end
end

% Go back to the original path
cd(originalPath);
         
% Load Elastic Reconstruction toolbox
addpath(genpath('external'));

% Total recall and precision will store the recall and precision for each descriptor for each scene in a matrix
totalRecall = [];
totalPrecision = [];
totalTime = [];

% Compute precision and recall for each descriptor for each scene and average
for descriptorIdx = 1:length(descriptorsNames)
    descriptorName = descriptorsNames{descriptorIdx};
    
    for sceneIdx = 1:length(sceneList)
        scenePath = fullfile(dataPath,sceneList{sceneIdx});
        
        % Compute registration error
        gt = mrLoadLog(fullfile(scenePath,'gt.log'));
        gt_info = mrLoadInfo(fullfile(scenePath,'gt.info'));
        result = mrLoadLog(fullfile(scenePath,sprintf('_%s.log',descriptorName)));
        [recall,precision] = mrEvaluateRegistration(result,gt,gt_info);

        totalRecall(descriptorIdx,sceneIdx) = recall;
        totalPrecision(descriptorIdx,sceneIdx) = precision;

    end
end

% Append average recall and precision for each descriptor
totalRecall(:,end+1) = mean(totalRecall,2);
totalPrecision(:,end+1) = mean(totalPrecision,2);

% Plot recall and precision for each descriptor and average
figure;
bar([totalRecall; totalPrecision]');
set(gca,'XTickLabel',[sceneList {'Average'}]);
legend([cellfun(@(x) sprintf('Recall %s',x),descriptorsNames,'UniformOutput',false) ...
        cellfun(@(x) sprintf('Precision %s',x),descriptorsNames,'UniformOutput',false)]);
ylabel('Recall/Precision');
title('Recall and Precision for different descriptors');

% Save the plot
% saveas(gcf,'recPrec.png');

% Compute the average execution time for each descriptor
for descriptorIdx = 1:length(descriptorsNames)
    descriptorName = descriptorsNames{descriptorIdx};
    
    for sceneIdx = 1:length(sceneList)
        scenePath = fullfile(dataPath,sceneList{sceneIdx});
        
        % Compute execution time
        time = mrLoadLogTime(fullfile(scenePath,sprintf('%s.log',descriptorName)));
        totalTime(descriptorIdx,sceneIdx) = time;

    end
end

% Append average execution time for each descriptor
totalTime(:,end+1) = mean(totalTime,2);

% Plot execution time for each descriptor and average
figure;
bar(totalTime');
set(gca,'XTickLabel',[sceneList {'Average'}]);
legend(cellfun(@(x) sprintf('Time %s',x),descriptorsNames,'UniformOutput',false));
ylabel('Time (s)');
title('Execution time for different descriptors');

% Save the plot
% saveas(gcf,'resultsTime.png');

% Save the results
save('results.mat','totalRecall','totalPrecision','totalTime')

% Descriptor names and scene list as specified in the given script
descriptorsNames = {'CliReg', 'CliRegMutual', 'Teaser', 'Ransac', 'FGR'};
sceneList = {'Kitchen', 'Home 1', 'Home 2', 'Hotel 1', 'Hotel 2', 'Hotel 3', 'Study', 'MIT Lab', 'Avg.'};
metricSuffix = '(\%)';
timeMetric = 'Avg. Runtime [s]';

% Open a file to write the LaTeX table
fid = fopen('results_table.tex', 'w');

% Write the LaTeX document preamble and table header
fprintf(fid, '\\documentclass{article}\n');
fprintf(fid, '\\usepackage{makecell}\n');
fprintf(fid, '\\usepackage{rotating}\n');
fprintf(fid, '\\usepackage{booktabs}\n');
fprintf(fid, '\\begin{document}\n');
fprintf(fid, '%%***********************************************************************************************\n');
fprintf(fid, '\\begin{table*}\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\caption{Percentage of correct registration results and average runtime of the different algorithms on the \\textit{3DMatch} \\cite{zeng20163dmatch} dataset.}\n');
fprintf(fid, '\\begin{tabular}{lccccccccccc}\n');
fprintf(fid, '\\toprule\n');
fprintf(fid, '& \\multicolumn{8}{c}{Scenes} & & & \\\\\n');
fprintf(fid, '\\cmidrule(lr){2-9}\n');
fprintf(fid, ' & \\makecell{\\rotatebox{90}{%s}}', [sceneList{1}, ' ', metricSuffix]);
for sceneIdx = 2:length(sceneList)-1 % Excluding Avg
    fprintf(fid, ' & \\makecell{\\rotatebox{90}{%s}}', [sceneList{sceneIdx}, ' ', metricSuffix]);
end
fprintf(fid, ' & \\makecell{\\rotatebox{90}{%s}} & \\makecell{\\rotatebox{90}{%s}} \\\\\n', [sceneList{end}, ' ', metricSuffix], timeMetric);
fprintf(fid, '\\cmidrule(lr){1-1}\n');
fprintf(fid, '\\cmidrule(lr){2-9}\n');
fprintf(fid, '\\cmidrule(lr){10-11}\n');

% Write the table content
for descriptorIdx = 1:length(descriptorsNames)
    fprintf(fid, '%s', descriptorsNames{descriptorIdx});
    for sceneIdx = 1:length(sceneList)-1 % Excluding Avg
        if totalRecall(descriptorIdx, sceneIdx) == max(totalRecall(:, sceneIdx))
            fprintf(fid, ' & \\textbf{%.3f}', totalRecall(descriptorIdx, sceneIdx));
        else
            fprintf(fid, ' & %.3f', totalRecall(descriptorIdx, sceneIdx));
        end
    end
    if totalRecall(descriptorIdx, end) == max(totalRecall(:, end))
        fprintf(fid, ' & \\textbf{%.3f}', totalRecall(descriptorIdx, end));
    else
        fprintf(fid, ' & %.3f', totalRecall(descriptorIdx, end));
    end
    if totalTime(descriptorIdx, end) == min(totalTime(:, end))
        fprintf(fid, ' & \\textbf{%.3f} \\\\\n', totalTime(descriptorIdx, end));
    else
        fprintf(fid, ' & %.3f \\\\\n', totalTime(descriptorIdx, end));
    end
end

% Write the LaTeX table footer
fprintf(fid, '\\bottomrule\n');
fprintf(fid, '\\end{tabular}\n');
fprintf(fid, '\\label{tab:scanMatching}\n');
fprintf(fid, '\\end{table*}\n');
fprintf(fid, '%%***********************************************************************************************\n');
fprintf(fid, '\\end{document}\n');

% Close the file
fclose(fid);

% Display a message indicating the table has been created
disp('LaTeX table created successfully.');