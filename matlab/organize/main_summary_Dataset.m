clear all; close all; clc;

dataset_process_folder = '/media/ourDataset/preprocess';

LeopardCamera1_timestamps_folder = './filted_LeopardCamera1_timestamps';
VelodyneLidar_timestamps_folder = './VelodyneLidar_timestamps';
OCULiiRadar_timestamps_folder = './OCULiiRadar_timestamps';
TIRadar_timestamps_folder = './TIRadar_timestamps';

max_synchro_error = 0.1; % s
LeopardCamera1_timestamps_offset = -0.5; % s
VelodyneLidar_timestamps_offset = 0; % s
OCULiiRadar_timestamps_offset = -3.0; % s
TIRadar_timestamps_offset = 0; % s

load('./calib_results/LeopardCamera1_IntrinsicMatrix.mat');
load('./calib_results/VelodyneLidar_to_LeopardCamera1_TransformMatrix.mat');
load('./calib_results/OCULiiRadar_to_LeopardCamera1_TransformMatrix.mat');
load('./calib_results/TIRadar_to_LeopardCamera1_TransformMatrix.mat');

dataset_groups = dir(dataset_process_folder);

summary_info = struct();
for k = 3:length(dataset_groups)
    dataset_group = dataset_groups(k).name;
    disp('========================================================');
    
    LeopardCamera1_timestamps_filepath = fullfile(LeopardCamera1_timestamps_folder, strcat(dataset_group, '.mat'));
    if exist(LeopardCamera1_timestamps_filepath, 'file')
        load(LeopardCamera1_timestamps_filepath);
    else        
        fprintf('%s can not be found.\n', LeopardCamera1_timestamps_filepath);
        continue;
    end
    LeopardCamera1_timestamps = LeopardCamera1_timestamps + LeopardCamera1_timestamps_offset;
    load(fullfile(VelodyneLidar_timestamps_folder, strcat(dataset_group, '.mat')));
    VelodyneLidar_timestamps = VelodyneLidar_timestamps + VelodyneLidar_timestamps_offset;
    load(fullfile(OCULiiRadar_timestamps_folder, strcat(dataset_group, '.mat')));
    OCULiiRadar_timestamps = OCULiiRadar_timestamps + OCULiiRadar_timestamps_offset;
    load(fullfile(TIRadar_timestamps_folder, strcat(dataset_group, '.mat')));
    TIRadar_timestamps = TIRadar_timestamps + TIRadar_timestamps_offset;
    
    match_results = match_sensers_timestamps(max_synchro_error, LeopardCamera1_timestamps, VelodyneLidar_timestamps, OCULiiRadar_timestamps, TIRadar_timestamps);
    frame_len_min = 50;
    match_results = select_match_results(match_results, frame_len_min);
    
    temp = 0;
    for i = 1 : length(match_results)
        summary_info(match_results(i).groupId+1).groupId = match_results(i).groupId;
        eval(sprintf('summary_info(match_results(%d).groupId+1).day%s = length(match_results(%d).group);', i, dataset_group, i));
        fprintf('group%04d  %3d\n', match_results(i).groupId, length(match_results(i).group))
        temp = temp + length(match_results(i).group);
    end
    fprintf('%s has %d groups, %d frames.\n', dataset_group, length(match_results), temp);

end


%%
function match_results_selected = select_match_results(match_results, frame_len_min)
    groupId_selected = -1;
    match_results_selected = struct();

    for i = 1:length(match_results)
        group = match_results(i).group;

        if length(group) >= frame_len_min
            groupId_selected = groupId_selected + 1;
            match_results_selected(groupId_selected+1).groupId = groupId_selected;
            match_results_selected(groupId_selected+1).group = group;
        end
    end
end


function match_results = match_sensers_timestamps(max_synchro_error, LeopardCamera1_timestamps, VelodyneLidar_timestamps, OCULiiRadar_timestamps, TIRadar_timestamps)
    match_results = struct();
    groupId = -1;
    frameId = -1;
    isRecordANewGroup = false;
    TIRadar_timestamp_old = 0;

    for i_TIRadar = 1:length(TIRadar_timestamps)        
        TIRadar_timestamp = TIRadar_timestamps(i_TIRadar);
        
        [min_value, min_index] = min(abs(LeopardCamera1_timestamps - TIRadar_timestamp));
        if min_value > max_synchro_error
            if isRecordANewGroup
                match_results(groupId+1).groupId = groupId;
                match_results(groupId+1).group = group;
                isRecordANewGroup = false;
                fprintf('End: i_TIRadar = %d, TIRadar_timestamp = %.3f\n', i_TIRadar-1, TIRadar_timestamps(i_TIRadar-1));
            end
            continue;
        else
            LeopardCamera1_timestamp = LeopardCamera1_timestamps(min_index);
        end

        [min_value, min_index] = min(abs(VelodyneLidar_timestamps - TIRadar_timestamp));
        if min_value > max_synchro_error
            if isRecordANewGroup
                match_results(groupId+1).groupId = groupId;
                match_results(groupId+1).group = group;
                isRecordANewGroup = false;
                fprintf('End: i_TIRadar = %d, TIRadar_timestamp = %.3f\n', i_TIRadar-1, TIRadar_timestamps(i_TIRadar-1));
            end
            continue;
        else
            VelodyneLidar_timestamp = VelodyneLidar_timestamps(min_index);
        end

        [min_value, min_index] = min(abs(OCULiiRadar_timestamps - TIRadar_timestamp));
        if min_value > max_synchro_error
            if isRecordANewGroup
                match_results(groupId+1).groupId = groupId;
                match_results(groupId+1).group = group;
                isRecordANewGroup = false;
                fprintf('End: i_TIRadar = %d, TIRadar_timestamp = %.3f\n', i_TIRadar-1, TIRadar_timestamps(i_TIRadar-1));
            end
            continue;
        else
            OCULiiRadar_timestamp = OCULiiRadar_timestamps(min_index);
        end

        % if find frame in all sensors
        if (TIRadar_timestamp - TIRadar_timestamp_old)>0.15
            if isRecordANewGroup
                match_results(groupId+1).groupId = groupId;
                match_results(groupId+1).group = group;
                isRecordANewGroup = false;
                fprintf('End: i_TIRadar = %d, TIRadar_timestamp = %.3f\n', i_TIRadar-1, TIRadar_timestamps(i_TIRadar-1));
            end

            groupId = groupId + 1;
            frameId = -1;
            disp('===========================================================');
            fprintf('groupId = %d\n', groupId);
            fprintf('Start: i_TIRadar = %d, TIRadar_timestamp = %.3f\n', i_TIRadar, TIRadar_timestamp);
            isRecordANewGroup = true;
            group = struct();
        end
        frameId = frameId + 1;
        group(frameId+1).frameId = frameId;
        group(frameId+1).LeopardCamera1_timestamp = LeopardCamera1_timestamp;
        group(frameId+1).VelodyneLidar_timestamp = VelodyneLidar_timestamp;
        group(frameId+1).OCULiiRadar_timestamp = OCULiiRadar_timestamp;
        group(frameId+1).TIRadar_timestamp = TIRadar_timestamp;
        TIRadar_timestamp_old = TIRadar_timestamp;
    end

end

