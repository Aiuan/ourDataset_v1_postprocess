clear all; close all; clc;

output_folder = './filted_VelodyneLidar_fixed_timestamps';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    fprintf('%s is created.\n', output_folder);
end

input_folder = './VelodyneLidar_fixed_timestamps';
OVERWRITE_ON = 0;
dataset_process_path = '/media/ourDataset/preprocess';

% dataset_group = '20211025_1';
% process_single(output_folder, input_folder, dataset_group, dataset_process_path, OVERWRITE_ON);

process(output_folder, input_folder, dataset_process_path, OVERWRITE_ON);

%%
function process(output_folder, input_folder, dataset_process_path, OVERWRITE_ON)
    temp = dir(fullfile(input_folder, '*.mat'));
    for i = 1:length(temp)
        dataset_group = replace(temp(i).name, '.mat', '');
        process_single(output_folder, input_folder, dataset_group, dataset_process_path, OVERWRITE_ON);
    end
end

function process_single(output_folder, input_folder, dataset_group, dataset_process_path, OVERWRITE_ON)
    disp('===========================================================');
    tic;
    fprintf('%s\n', dataset_group);
    file_save_path = fullfile(output_folder, strcat(dataset_group, '.mat'));
    if ~exist(file_save_path, 'file') || OVERWRITE_ON
        input_path = fullfile(input_folder, strcat(dataset_group, '.mat'));
        load(input_path);
        
        mask = ~logical(VelodyneLidar_timestamps);
        fixLogs_path = fullfile(dataset_process_path, dataset_group, 'VelodyneLidar_fixed','logs');
        if exist(fixLogs_path, 'dir')
            parfor i = 1 : length(VelodyneLidar_timestamps)
                fixLog_filename = sprintf('%.3f.txt', VelodyneLidar_timestamps(i));
                fixLog = readmatrix(fullfile(fixLogs_path, fixLog_filename));
                if fixLog(1) == 0
                    mask(i) = true;
                end
            end
            VelodyneLidar_timestamps = VelodyneLidar_timestamps(mask,:);        
            if ~isempty(VelodyneLidar_timestamps)
                save(file_save_path, 'VelodyneLidar_timestamps');
            end
            fprintf('datagroup efficiency = %.2f %% (%d/%d)\n', length(VelodyneLidar_timestamps)/length(mask)*100, length(VelodyneLidar_timestamps), length(mask));
        else
            fprintf('%s does not exist.\n', fixLogs_path);
        end
    else
        input_path = fullfile(input_folder, strcat(dataset_group, '.mat'));
        load(input_path);
        all = length(VelodyneLidar_timestamps);
        load(file_save_path);
        use = length(VelodyneLidar_timestamps);
        fprintf('datagroup efficiency = %.2f %% (%d/%d)\n', use/all*100, use, all);
        
        fprintf('%s has already been generated.\n', file_save_path);
    end
    fprintf('Done.\n');
    toc;
end

