%% replenish TIRadar heatmap to ourDataset/v1.0
clear all; close all; clc;


dataset_process_folder = '/media/ourDataset/preprocess';
dataset_group = '20211025_1';
replenish_root = fullfile('/home/aify/Desktop/ourDataset/v1.0', dataset_group, "Dataset");
replenish_groups = dir(replenish_root);
for i = 3:length(replenish_groups)
    replenish_folder_path = fullfile(replenish_root, replenish_groups(i).name);
    TIRadar_folder_path = fullfile(replenish_folder_path, 'TIRadar');
    TIRadar_timestamp = dir(fullfile(TIRadar_folder_path, "*.pcd"));
    TIRadar_timestamp = TIRadar_timestamp(1).name;
    TIRadar_timestamp = replace(TIRadar_timestamp, '.pcd', '');
    
    dst_path = fullfile(TIRadar_folder_path, strcat(TIRadar_timestamp, ".heatmap.bin"));
    if exist(dst_path, "file")
        fprintf("% s exist.\n", dst_path);
        continue;
    end

    src_path = fullfile(dataset_process_folder, dataset_group, "TIRadar", strcat(TIRadar_timestamp, ".heatmap.bin"));
    if ~exist(src_path, "file")
        fprintf("#ERROR % s do not exist.\n", src_path);
        break;
    end

    copyfile(src_path, dst_path);
    fprintf("% s ok!\n", dst_path);
end


%% replenish TIRadar heatmap to ourDataset/v1.0_label
clear all; close all; clc;


dataset_process_folder = '/media/ourDataset/preprocess';
query_group = '20211025_1';
replenish_root = '/home/aify/Desktop/ourDataset/v1.0_label';
replenish_groups = dir(replenish_root);
for i = 3:length(replenish_groups)
    if replenish_groups(i).name == "vedio"
        disp("vedio folder skip.");
        continue;
    end

    dataset_group = replenish_groups(i).name;
    dataset_group = split(dataset_group, '_group');
    dataset_group = dataset_group{1};
    if strcmp(dataset_group, query_group) ~= 1
        fprintf("%s folder skip.\n", replenish_groups(i).name);
        continue;
    end

    replenish_group_path = fullfile(replenish_root, replenish_groups(i).name);
    replenish_frames = dir(replenish_group_path);

    for j = 3:length(replenish_frames)       

        replenish_folder_path = fullfile(replenish_root, replenish_groups(i).name, replenish_frames(j).name);
        TIRadar_folder_path = fullfile(replenish_folder_path, 'TIRadar');
        TIRadar_timestamp = dir(fullfile(TIRadar_folder_path, "*.pcd"));
        TIRadar_timestamp = TIRadar_timestamp(1).name;
        TIRadar_timestamp = replace(TIRadar_timestamp, '.pcd', '');

        dst_path = fullfile(TIRadar_folder_path, strcat(TIRadar_timestamp, ".heatmap.bin"));
        if exist(dst_path, "file")
            fprintf("% s exist.\n", dst_path);
            continue;
        end
    
        src_path = fullfile(dataset_process_folder, dataset_group, "TIRadar", strcat(TIRadar_timestamp, ".heatmap.bin"));
        if ~exist(src_path, "file")
            fprintf("#ERROR % s do not exist.\n", src_path);
            break;
        end
    
        copyfile(src_path, dst_path);
        fprintf("% s ok!\n", dst_path);

    end
    
end