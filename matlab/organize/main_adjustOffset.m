% uncomplete

clear all; close all; clc;

PROJECT_ON = true;

dataset_process_folder = '/media/ourDataset/preprocess';
dataset_group = '20211025_1';
LeopardCamera1_timestamps_folder = './filted_LeopardCamera1_timestamps';
VelodyneLidar_timestamps_folder = './VelodyneLidar_timestamps';
OCULiiRadar_timestamps_folder = './OCULiiRadar_timestamps';
TIRadar_timestamps_folder = './TIRadar_timestamps';

load('./calib_results/LeopardCamera1_IntrinsicMatrix.mat');
load('./calib_results/VelodyneLidar_to_LeopardCamera1_TransformMatrix.mat');
load('./calib_results/OCULiiRadar_to_LeopardCamera1_TransformMatrix.mat');
load('./calib_results/TIRadar_to_LeopardCamera1_TransformMatrix.mat');

load(fullfile(LeopardCamera1_timestamps_folder, strcat(dataset_group, '.mat')));
load(fullfile(VelodyneLidar_timestamps_folder, strcat(dataset_group, '.mat')));
load(fullfile(OCULiiRadar_timestamps_folder, strcat(dataset_group, '.mat')));
load(fullfile(TIRadar_timestamps_folder, strcat(dataset_group, '.mat')));

% initial
max_synchro_error = 0.1; % s
LeopardCamera1_timestamps_offset = 0; % s
VelodyneLidar_timestamps_offset = 0; % s
OCULiiRadar_timestamps_offset = -4.5; % s
TIRadar_timestamps_offset = 0; % s

match_results = match_sensers_timestamps(max_synchro_error,...
    LeopardCamera1_timestamps, LeopardCamera1_timestamps_offset,...
    VelodyneLidar_timestamps, VelodyneLidar_timestamps_offset,...
    OCULiiRadar_timestamps, OCULiiRadar_timestamps_offset,...
    TIRadar_timestamps, TIRadar_timestamps_offset);

for i = 1:length(match_results)
    groupId = match_results(i).groupId;
    for j = 1:length(match_results(i).group)
        
        
    end
end





function match_results = match_sensers_timestamps(max_synchro_error,...
    LeopardCamera1_timestamps, LeopardCamera1_timestamps_offset,...
    VelodyneLidar_timestamps, VelodyneLidar_timestamps_offset,...
    OCULiiRadar_timestamps, OCULiiRadar_timestamps_offset,...
    TIRadar_timestamps, TIRadar_timestamps_offset)
    
    LeopardCamera1_timestamps = LeopardCamera1_timestamps + LeopardCamera1_timestamps_offset;
    VelodyneLidar_timestamps = VelodyneLidar_timestamps + VelodyneLidar_timestamps_offset;
    OCULiiRadar_timestamps = OCULiiRadar_timestamps + OCULiiRadar_timestamps_offset;
    TIRadar_timestamps = TIRadar_timestamps + TIRadar_timestamps_offset;

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
