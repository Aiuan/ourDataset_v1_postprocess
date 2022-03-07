clear all; close all; clc;

output_folder = './filted_LeopardCamera1_timestamps';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    fprintf('%s is created.\n', output_folder);
end

input_folder = './LeopardCamera1_timestamps';
dataset_select_path = './select_by_419';
OVERWRITE_ON = 0;

% dataset_group = '20211025_1';
% process_single(output_folder, input_folder, dataset_group, dataset_select_path, OVERWRITE_ON);

process(output_folder, input_folder, dataset_select_path, OVERWRITE_ON)

%%
function process(output_folder, input_folder, dataset_select_path, OVERWRITE_ON)
    temp = dir(fullfile(input_folder, '*.mat'));
    for i = 1:length(temp)
        dataset_group = replace(temp(i).name, '.mat', '');
        process_single(output_folder, input_folder, dataset_group, dataset_select_path, OVERWRITE_ON);
    end
end

function process_single(output_folder, input_folder, dataset_group, dataset_select_path, OVERWRITE_ON)
    disp('===========================================================');
    fprintf('%s\n', dataset_group);
    file_save_path = fullfile(output_folder, strcat(dataset_group, '.mat'));
    if ~exist(file_save_path, 'file') || OVERWRITE_ON
        input_path = fullfile(input_folder, strcat(dataset_group, '.mat'));
        load(input_path);
        dataset_group_select_path = getSelectPath(dataset_select_path, dataset_group);
        if ~isempty(dataset_group_select_path)
            interest_ranges = readmatrix(dataset_group_select_path, 'Range', 'A:B');
            interest_ranges = interest_ranges(2:end, :);
            mask = ~logical(LeopardCamera1_timestamps);
            for i = 1:size(interest_ranges, 1)
                mask = mask | (LeopardCamera1_timestamps(:,1) >= interest_ranges(i,1) & LeopardCamera1_timestamps(:,1) <= interest_ranges(i,2));
            end
            LeopardCamera1_timestamps = LeopardCamera1_timestamps(mask,:);        
            if ~isempty(LeopardCamera1_timestamps)
                save(file_save_path, 'LeopardCamera1_timestamps');
            end
        end
    else
        fprintf('%s has already been generated.\n', file_save_path);
    end
    fprintf('Done.\n');
end


function dataset_group_select_path = getSelectPath(dataset_select_path, dataset_group)
    temp = dir(fullfile(dataset_select_path, strcat('*',dataset_group,'.xlsx')));
    if ~isempty(temp)
        dataset_group_select_path = fullfile(dataset_select_path, temp.name);
    else
        temp = dir(fullfile(dataset_select_path, strcat('*',dataset_group,'.xls')));
        if ~isempty(temp)
            dataset_group_select_path = fullfile(dataset_select_path, temp.name);
        else
            dataset_group_select_path = '';
            fprintf('Can not find select_path for %s\n', dataset_group);
        end
    end
end
