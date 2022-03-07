clear all; close all; clc;

output_folder = './VelodyneLidar_timestamps';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    fprintf('%s is created.\n', output_folder);
end
dataset_origin_path = '/mnt/DATASET';
dataset_process_path = '/media/ourDataset/preprocess';
OVERWRITE_ON = 0;

% dataset_group = '20211025_1';
% process_single(output_folder, dataset_process_path, dataset_group, OVERWRITE_ON);

process(output_folder, dataset_process_path, OVERWRITE_ON);

%%
function process(output_folder, dataset_process_path, OVERWRITE_ON)
    temp = dir(dataset_process_path);
    for i = 3:length(temp)
        dataset_group = temp(i).name;
        process_single(output_folder, dataset_process_path, dataset_group, OVERWRITE_ON);
    end
end

function process_single(output_folder, dataset_process_path, dataset_group, OVERWRITE_ON)
    disp('===========================================================');
    fprintf('%s\n', dataset_group);
    file_save_path = fullfile(output_folder, strcat(dataset_group, '.mat'));
    if ~exist(file_save_path, 'file') || OVERWRITE_ON
        [VelodyneLidar_timestamps, VelodyneLidar_timestamps_str] = get_VelodyneLidar_timestamps(fullfile(dataset_process_path, dataset_group));
        if ~isempty(VelodyneLidar_timestamps)
            save(file_save_path, 'VelodyneLidar_timestamps', 'VelodyneLidar_timestamps_str');
        end
    else
        fprintf('%s has already been generated.\n', file_save_path);
    end
    fprintf('Done.\n');
end

function [VelodyneLidar_timestamps, VelodyneLidar_timestamps_str] = get_VelodyneLidar_timestamps(dataset_group_path)
    VelodyneLidar_timestamps = [];
    VelodyneLidar_timestamps_str = [];
    
    if exist(fullfile(dataset_group_path, 'VelodyneLidar'))
        temp = dir(fullfile(dataset_group_path, 'VelodyneLidar', '*.pcd'));
    else
        temp = [];
    end
    
    for i = 1:length(temp)
        timestamp = str2double(replace(temp(i).name, '.pcd', ''));        
        VelodyneLidar_timestamps = [VelodyneLidar_timestamps; timestamp];
        timestamp_str = replace(temp(i).name, '.pcd', '');
        VelodyneLidar_timestamps_str = [VelodyneLidar_timestamps_str; timestamp_str];
    end
end