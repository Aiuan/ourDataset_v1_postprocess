clear all; close all; clc;

WAITKEY_ON = false;
PROJECT_ON = true;
GenPic_ON = true;
GenDataset_ON = true;
VISIBLE_ON = false;
OVERWRITE_ON = 0;

dataset_process_folder = '/media/ourDataset/preprocess';

dataset_group = '20211031_3';

output_folder = fullfile('/home/aify/Desktop/ourDataset/v1.0', strcat(dataset_group));
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    fprintf('%s is created.\n', output_folder);
end
output_Pic_folder = fullfile(output_folder, 'Pic');
if ~exist(output_Pic_folder, 'dir') && GenPic_ON
    mkdir(output_Pic_folder);
    fprintf('%s is created.\n', output_Pic_folder);
end
output_Pic_Sensors_folder = fullfile(output_Pic_folder, 'Sensors');
if ~exist(output_Pic_Sensors_folder, 'dir') && GenPic_ON 
    mkdir(output_Pic_Sensors_folder);
    fprintf('%s is created.\n', output_Pic_Sensors_folder);
end
output_Pic_Projections_folder = fullfile(output_Pic_folder, 'Projections');
if ~exist(output_Pic_Projections_folder, 'dir') && GenPic_ON && PROJECT_ON
    mkdir(output_Pic_Projections_folder);
    fprintf('%s is created.\n', output_Pic_Projections_folder);
end
output_Dataset_folder = fullfile(output_folder, 'Dataset');
if ~exist(output_Dataset_folder, 'dir') && GenDataset_ON
    mkdir(output_Dataset_folder);
    fprintf('%s is created.\n', output_Dataset_folder);
end

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


%%
load(fullfile(LeopardCamera1_timestamps_folder, strcat(dataset_group, '.mat')));
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
    fprintf('group%04d  %3d\n', match_results(i).groupId, length(match_results(i).group))
    temp = temp + length(match_results(i).group);
end
fprintf('%s has %d groups, %d frames.\n', dataset_group, length(match_results), temp);



parfor i = 1:length(match_results)
    groupId = match_results(i).groupId;
    for j = 1:length(match_results(i).group)
        frameId = match_results(i).group(j).frameId;
        
        disp('===========================================================');
        fprintf('Show groupId%04d_frameId%04d\n', groupId, frameId);
        
        if ~OVERWRITE_ON
            cnt = 0;
            if PROJECT_ON
                if exist(fullfile(output_Pic_Projections_folder, sprintf('groupId%04d_frameId%04d.jpg', groupId, frameId)), 'file') 
                    cnt = cnt + 1;
                end
            end
            if GenPic_ON
                if exist(fullfile(output_Pic_Sensors_folder, sprintf('groupId%04d_frameId%04d.jpg', groupId, frameId)), 'file')
                    cnt = cnt + 1;
                end
            end
            if GenDataset_ON
                if exist(fullfile(output_Dataset_folder, sprintf('group%04d_frame%04d', groupId, frameId)), 'dir')
                    cnt = cnt + 1;
                end
            end
            if cnt == (PROJECT_ON+GenPic_ON+GenDataset_ON)
                fprintf('groupId%04d_frameId%04d has already been generated.\n', groupId, frameId);
                continue;
            end
        end

        tic;
        LeopardCamera1_timestamp = match_results(i).group(j).LeopardCamera1_timestamp - LeopardCamera1_timestamps_offset;
        LeopardCamera1_png_path = fullfile(dataset_process_folder, dataset_group, 'LeopardCamera1', sprintf('%.3f.png', LeopardCamera1_timestamp));

        VelodyneLidar_timestamp = match_results(i).group(j).VelodyneLidar_timestamp - VelodyneLidar_timestamps_offset;
        % double can not fit %.9f 
        VelodyneLidar_timestamp_str = VelodyneLidar_timestamps_str(find(VelodyneLidar_timestamp == VelodyneLidar_timestamps), :);
        VelodyneLidar_pcd_path = fullfile(dataset_process_folder, dataset_group, 'VelodyneLidar', sprintf('%s.pcd', VelodyneLidar_timestamp_str));

        OCULiiRadar_timestamp = match_results(i).group(j).OCULiiRadar_timestamp - OCULiiRadar_timestamps_offset;
        OCULiiRadar_pcd_path = fullfile(dataset_process_folder, dataset_group, 'OCULiiRadar', sprintf('%.3f.pcd', OCULiiRadar_timestamp));

        TIRadar_timestamp = match_results(i).group(j).TIRadar_timestamp - TIRadar_timestamps_offset;
        TIRadar_pcd_path = fullfile(dataset_process_folder, dataset_group, 'TIRadar', sprintf('%.3f.pcd', TIRadar_timestamp));
        TIRadar_heatmap_path = fullfile(dataset_process_folder, dataset_group, 'TIRadar', sprintf('%.3f.heatmap.bin', TIRadar_timestamp));
        if GenDataset_ON
            createDatasetFolders(OVERWRITE_ON, output_Dataset_folder, groupId, frameId,...
                LeopardCamera1_png_path, VelodyneLidar_pcd_path, OCULiiRadar_pcd_path, TIRadar_pcd_path, TIRadar_heatmap_path,...
                LeopardCamera1_IntrinsicMatrix, VelodyneLidar_to_LeopardCamera1_TransformMatrix, OCULiiRadar_to_LeopardCamera1_TransformMatrix, TIRadar_to_LeopardCamera1_TransformMatrix);
        end


        if GenPic_ON
            showScence(PROJECT_ON, VISIBLE_ON, output_Pic_Sensors_folder, output_Pic_Projections_folder, groupId, frameId,...
                LeopardCamera1_png_path, VelodyneLidar_pcd_path, OCULiiRadar_pcd_path, TIRadar_pcd_path,...
                LeopardCamera1_IntrinsicMatrix, VelodyneLidar_to_LeopardCamera1_TransformMatrix, OCULiiRadar_to_LeopardCamera1_TransformMatrix, TIRadar_to_LeopardCamera1_TransformMatrix);
        end
        
        toc;

        if GenPic_ON && WAITKEY_ON
            key = waitforbuttonpress;
            while(key==0)
                key = waitforbuttonpress;
            end        
        end
    end

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

function showScence(PROJECT_ON, VISIBLE_ON, output_Pic_Sensors_folder, output_Pic_Projections_folder, groupId, frameId,...
    LeopardCamera1_png_path, VelodyneLidar_pcd_path, OCULiiRadar_pcd_path, TIRadar_pcd_path,...
    LeopardCamera1_IntrinsicMatrix, VelodyneLidar_to_LeopardCamera1_TransformMatrix, OCULiiRadar_to_LeopardCamera1_TransformMatrix, TIRadar_to_LeopardCamera1_TransformMatrix)

    forward_ranges = [0, 40];
    left_right_ranges = [-40, 40];

    LeopardCamera1_png = imread(LeopardCamera1_png_path);
    LeopardCamera1_timestamp = getTimestampFromPath(LeopardCamera1_png_path);
    
    [VelodyneLidar_pcd, ~] = readVelodynePcd(VelodyneLidar_pcd_path);
%     [VelodyneLidar_pcd, ~] = readPcd(VelodyneLidar_pcd_path);
    VelodyneLidar_timestamp = getTimestampFromPath(VelodyneLidar_pcd_path);
    VelodyneLidar_x_ranges = [forward_ranges(1), forward_ranges(2)];
    VelodyneLidar_y_ranges = [left_right_ranges(1), left_right_ranges(2)];
    VelodyneLidar_z_ranges = [-inf, inf];
    VelodyneLidar_mask = VelodyneLidar_pcd(:,1)>=VelodyneLidar_x_ranges(1)...
        & VelodyneLidar_pcd(:,1)<=VelodyneLidar_x_ranges(2)...
        & VelodyneLidar_pcd(:,2)>=VelodyneLidar_y_ranges(1)...
        & VelodyneLidar_pcd(:,2)<=VelodyneLidar_y_ranges(2)...
        & VelodyneLidar_pcd(:,3)>=VelodyneLidar_z_ranges(1)...
        & VelodyneLidar_pcd(:,3)<=VelodyneLidar_z_ranges(2);  
    VelodyneLidar_pcd_struct = getPcdStruct('VelodyneLidar', VelodyneLidar_pcd, VelodyneLidar_mask, VelodyneLidar_to_LeopardCamera1_TransformMatrix, PROJECT_ON);

    
    [OCULiiRadar_pcd, ~] = readPcd(OCULiiRadar_pcd_path);
    OCULiiRadar_timestamp = getTimestampFromPath(OCULiiRadar_pcd_path);    
    OCULiiRadar_x_ranges = [left_right_ranges(1), left_right_ranges(2)];
    OCULiiRadar_y_ranges = [-inf, inf];
    OCULiiRadar_z_ranges = [forward_ranges(1), forward_ranges(2)];
    OCULiiRadar_mask = OCULiiRadar_pcd(:,1)>=OCULiiRadar_x_ranges(1)...
        & OCULiiRadar_pcd(:,1)<=OCULiiRadar_x_ranges(2)...
        & OCULiiRadar_pcd(:,2)>=OCULiiRadar_y_ranges(1)...
        & OCULiiRadar_pcd(:,2)<=OCULiiRadar_y_ranges(2)...  
        & OCULiiRadar_pcd(:,3)>=OCULiiRadar_z_ranges(1)...
        & OCULiiRadar_pcd(:,3)<=OCULiiRadar_z_ranges(2);     
    OCULiiRadar_pcd_struct = getPcdStruct('OCULiiRadar', OCULiiRadar_pcd, OCULiiRadar_mask, OCULiiRadar_to_LeopardCamera1_TransformMatrix, PROJECT_ON);
  

    [TIRadar_pcd, ~] = readPcd(TIRadar_pcd_path);
    TIRadar_timestamp = getTimestampFromPath(TIRadar_pcd_path);    
    TIRadar_x_ranges = [left_right_ranges(1), left_right_ranges(2)];
    TIRadar_y_ranges = [forward_ranges(1), forward_ranges(2)];
    TIRadar_z_ranges = [-inf, inf];
    TIRadar_mask = TIRadar_pcd(:,1)>=TIRadar_x_ranges(1)...
        & TIRadar_pcd(:,1)<=TIRadar_x_ranges(2)...
        & TIRadar_pcd(:,2)>=TIRadar_y_ranges(1)...
        & TIRadar_pcd(:,2)<=TIRadar_y_ranges(2)...  
        & TIRadar_pcd(:,3)>=TIRadar_z_ranges(1)...
        & TIRadar_pcd(:,3)<=TIRadar_z_ranges(2);     
    TIRadar_pcd_struct = getPcdStruct('TIRadar', TIRadar_pcd, TIRadar_mask, TIRadar_to_LeopardCamera1_TransformMatrix, PROJECT_ON);
  
    if VISIBLE_ON
        fig = figure('Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
    else
        fig = figure('visible', 'off', 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
    end
    t1_ax1 = axes(fig, 'Units', 'normalized', 'OuterPosition', [0, 0.5, 0.5, 0.5]);
    imshow(LeopardCamera1_png);
    title(sprintf('LeopardCamera1: %s s (diff=%.3f s)', LeopardCamera1_timestamp, str2double(LeopardCamera1_timestamp)-str2double(VelodyneLidar_timestamp)));
    t1_ax2 = axes(fig, 'Units', 'normalized', 'OuterPosition', [0.5, 0.5, 0.5, 0.5]);
    scatter3(t1_ax2, [VelodyneLidar_pcd_struct.x],...
        [VelodyneLidar_pcd_struct.y],...
        [VelodyneLidar_pcd_struct.z],...
        2,...
        [VelodyneLidar_pcd_struct.intensity],...
        'filled')
    xlabel('x(m)');
    ylabel('y(m)');
    zlabel('z(m)');
    axis([VelodyneLidar_x_ranges(1), VelodyneLidar_x_ranges(2), VelodyneLidar_y_ranges(1), VelodyneLidar_y_ranges(2), VelodyneLidar_z_ranges(1), VelodyneLidar_z_ranges(2)]);
    title(sprintf('VelodyneLidar: %s s (diff=%.3f s)', VelodyneLidar_timestamp, str2double(VelodyneLidar_timestamp)-str2double(VelodyneLidar_timestamp)));
    set(t1_ax2, 'View', [-90, 90]);
    colormap("jet");
    colorbar;
    t1_ax3 = axes(fig, 'Units', 'normalized', 'OuterPosition', [0, 0, 0.5, 0.5]);
    scatter3(t1_ax3, [OCULiiRadar_pcd_struct.x],...
        [OCULiiRadar_pcd_struct.y],...
        [OCULiiRadar_pcd_struct.z],...
        2,...
        [OCULiiRadar_pcd_struct.velocity],...
        'filled')
    xlabel('x(m)');
    ylabel('y(m)');
    zlabel('z(m)');
    axis([OCULiiRadar_x_ranges(1), OCULiiRadar_x_ranges(2), OCULiiRadar_y_ranges(1), OCULiiRadar_y_ranges(2), OCULiiRadar_z_ranges(1), OCULiiRadar_z_ranges(2)]);
    title(sprintf('OCULiiRadar: %s s (diff=%.3f s)', OCULiiRadar_timestamp, str2double(OCULiiRadar_timestamp)-str2double(VelodyneLidar_timestamp)));
    set(t1_ax3, 'View', [0, 0]);
    colormap("jet");
    colorbar;
    t1_ax4 = axes(fig, 'Units', 'normalized', 'OuterPosition', [0.5, 0, 0.5, 0.5]);
    scatter3(t1_ax4, [TIRadar_pcd_struct.x],...
        [TIRadar_pcd_struct.y],...
        [TIRadar_pcd_struct.z],...
        2,...
        [TIRadar_pcd_struct.velocity],...
        'filled')
    xlabel('x(m)');
    ylabel('y(m)');
    zlabel('z(m)');
    axis([TIRadar_x_ranges(1), TIRadar_x_ranges(2), TIRadar_y_ranges(1), TIRadar_y_ranges(2), TIRadar_z_ranges(1), TIRadar_z_ranges(2)]);
    title(sprintf('TIRadar: %s s (diff=%.3f s)', TIRadar_timestamp, str2double(TIRadar_timestamp)-str2double(VelodyneLidar_timestamp)));
    set(t1_ax4, 'View', [0, 90]);
    colormap("jet");
    colorbar; 
    pause(0.1);
    saveas(fig, fullfile(output_Pic_Sensors_folder, sprintf('groupId%04d_frameId%04d.jpg', groupId, frameId)));
    close(fig);

    if PROJECT_ON
        if VISIBLE_ON
            fig = figure('Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
        else
            fig = figure('visible', 'off', 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
        end
        t2_ax1 = axes(fig, 'Units', 'normalized', 'OuterPosition', [0, 0.5, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('LeopardCamera1: %s s (diff=%.3f s)', LeopardCamera1_timestamp, str2double(LeopardCamera1_timestamp)-str2double(VelodyneLidar_timestamp)));
        t2_ax2 = axes(fig, 'Units', 'normalized', 'OuterPosition', [0.5, 0.5, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('VelodyneLidar: %s s (diff=%.3f s)', VelodyneLidar_timestamp, str2double(VelodyneLidar_timestamp)-str2double(VelodyneLidar_timestamp)));
        hold on;
        scatter(t2_ax2, [VelodyneLidar_pcd_struct.u],...
            [VelodyneLidar_pcd_struct.v],...
            2,...
            [VelodyneLidar_pcd_struct.intensity],...
            'filled');
        colormap("jet");
        hold off;
        t2_ax3 = axes(fig, 'Units', 'normalized', 'OuterPosition', [0, 0, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('OCULiiRadar: %s s (diff=%.3f s)', OCULiiRadar_timestamp, str2double(OCULiiRadar_timestamp)-str2double(VelodyneLidar_timestamp)));
        hold on;
        scatter(t2_ax3, [OCULiiRadar_pcd_struct.u],...
            [OCULiiRadar_pcd_struct.v],...
            2,...
            [OCULiiRadar_pcd_struct.velocity],...
            'filled');
        colormap("jet");
        hold off;
        t2_ax4 = axes(fig, 'Units', 'normalized', 'OuterPosition', [0.5, 0, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('TIRadar: %s s (diff=%.3f s)', TIRadar_timestamp, str2double(TIRadar_timestamp)-str2double(VelodyneLidar_timestamp)));
        hold on;
        scatter(t2_ax4, [TIRadar_pcd_struct.u],...
            [TIRadar_pcd_struct.v],...
            2,...
            [TIRadar_pcd_struct.velocity],...
            'filled');
        colormap("jet");
        hold off;
        pause(0.1);
        saveas(fig, fullfile(output_Pic_Projections_folder, sprintf('groupId%04d_frameId%04d.jpg', groupId, frameId)));
        close(fig);
    end

    
    
end

function pcd_struct = getPcdStruct(type, pcd, mask, transformMatrix, PROJECT_ON)
    
    xyz = [pcd(mask,1), pcd(mask,2), pcd(mask, 3)];

    if PROJECT_ON
        uv = project_3Dpoint_to_pixel(xyz, transformMatrix);
    
        if strcmp(type, 'VelodyneLidar')
            pcd_struct = struct('u', num2cell(uv(:,1)),...
                'v', num2cell(uv(:,2)),...
                'x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'intensity', num2cell(pcd(mask, 4)),...
                'ring', num2cell(pcd(mask, 5)));
        elseif strcmp(type, 'OCULiiRadar')
            pcd_struct = struct('u', num2cell(uv(:,1)),...
                'v', num2cell(uv(:,2)),...
                'x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'velocity', num2cell(pcd(mask, 4)),...
                'intensity', num2cell(pcd(mask, 5)));
        elseif strcmp(type, 'TIRadar') 
            pcd_struct = struct('u', num2cell(uv(:,1)),...
                'v', num2cell(uv(:,2)),...
                'x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'velocity', num2cell(pcd(mask, 4)),...
                'SNR', num2cell(pcd(mask, 5)));
        else
            pcd_struct = struct();
        end
    else
        if strcmp(type, 'VelodyneLidar')
            pcd_struct = struct('x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'intensity', num2cell(pcd(mask, 4)),...
                'ring', num2cell(pcd(mask, 5)));
        elseif strcmp(type, 'OCULiiRadar')
            pcd_struct = struct('x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'velocity', num2cell(pcd(mask, 4)),...
                'intensity', num2cell(pcd(mask, 5)));
        elseif strcmp(type, 'TIRadar') 
            pcd_struct = struct('x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'velocity', num2cell(pcd(mask, 4)),...
                'SNR', num2cell(pcd(mask, 5)));
        else
            pcd_struct = struct();
        end
    end
end

function uv = project_3Dpoint_to_pixel(xyz, transformMatrix)
    xyz1 = [xyz'; ones(1, size(xyz,1))];
    uv1=transformMatrix * xyz1;
    uv1(1, :) = uv1(1, :) ./ uv1(3, :);
    uv1(2, :) = uv1(2, :) ./ uv1(3, :);
    uv=uv1(1:2, :);
    uv = round(uv);
    uv = uv';
end


function timestamp = getTimestampFromPath(path)
    temp = split(path, filesep);
    temp = temp{end};
    temp = split(temp, '.');
    timestamp = strcat(temp{1}, '.', temp{2});    
end

function [pcd, colInfo] = readPcd(pcd_path)
    fid = fopen(pcd_path, 'r');
    fgetl(fid);
    temp1 = fgetl(fid);
    fgetl(fid);
    temp2 = fgetl(fid);
    temp1 = split(temp1);
    temp2 = split(temp2);
    colInfo = struct();
    for i = 2:length(temp1)
        if temp2{i} == 'F'
            eval(sprintf('colInfo.%s = "float32";', temp1{i}));
        end
    end
    fgetl(fid);
    fgetl(fid);
    fgetl(fid);
    fgetl(fid);
    fgetl(fid);
    fgetl(fid);
    formatSpec = '';
    for i = 2:length(temp1)
        if i ~= length(temp1)
            formatSpec = strcat(formatSpec, '%f', {32});
        else
            formatSpec = strcat(formatSpec, '%f');
        end
    end
    formatSpec = formatSpec{1};

    pcd = fscanf(fid, formatSpec, [length(temp1)-1, Inf]);
    pcd = pcd';

    fclose(fid);
    
end


function [pcd, colInfo] = readVelodynePcd(pcd_path)
    % for bin type VelodynePcd

    fid = fopen(pcd_path);
    fgetl(fid);
    fgetl(fid);
    temp1 = fgetl(fid);
    fgetl(fid);
    temp2 = fgetl(fid);
    temp1 = split(temp1);
    temp2 = split(temp2);
    colInfo = struct();
    for i = 2:length(temp1)
        if temp2{i} == 'F'
            eval(sprintf('colInfo.%s = "float32";', temp1{i}));
        elseif temp2{i} == 'U'
            eval(sprintf('colInfo.%s = "uint16";', temp1{i}));
        end
    end

    % read x_y_z_intensity
    fseek(fid,212,'bof');
    x_y_z_intensity = fread(fid, "4*float", 6);
    n = ceil(size(x_y_z_intensity,1)/4);
    for i = 1:4*n-size(x_y_z_intensity,1)
        x_y_z_intensity(end+1) = 0;
    end
    x_y_z_intensity = reshape(x_y_z_intensity, 4, [])';
    % read ring
    fseek(fid,212+16,'bof');
    ring = fread(fid, "uint16", 20);
    for i = 1:n-size(ring,1)
        ring(end+1) = 0;
    end
    % read time
    fseek(fid,212+18,'bof');
    time = fread(fid, "float", 18);
    for i = 1:n-size(time,1)
        time(end+1) = 0;
    end
    fclose(fid);    
    pcd = [x_y_z_intensity, ring, time];
    % cut zero points
    mask = sum(pcd, 2)~=0;
    pcd = pcd(mask, :);
end

function createDatasetFolders(OVERWRITE_ON, output_Dataset_folder, groupId, frameId,...
    LeopardCamera1_png_path, VelodyneLidar_pcd_path, OCULiiRadar_pcd_path, TIRadar_pcd_path, TIRadar_heatmap_path,...
    LeopardCamera1_IntrinsicMatrix, VelodyneLidar_to_LeopardCamera1_TransformMatrix, OCULiiRadar_to_LeopardCamera1_TransformMatrix, TIRadar_to_LeopardCamera1_TransformMatrix)
    
    [folder_LeopardCamera1, folder_VelodyneLidar, folder_OCULiiRadar, folder_TIRadar, folder_MEMS] = createFolders(output_Dataset_folder, groupId, frameId);
    
    % LeopardCamera1    
    LeopardCamera1_png_srcPath = LeopardCamera1_png_path;
    temp = split(LeopardCamera1_png_path, filesep);
    temp = replace(temp{end}, '.png', '');
    LeopardCamera1_timestamp = str2double(temp);
    LeopardCamera1_png_dstPath = fullfile(folder_LeopardCamera1,sprintf('%.3f.png', LeopardCamera1_timestamp));
    if ~exist(LeopardCamera1_png_dstPath, 'file') || OVERWRITE_ON == 1
        if exist(LeopardCamera1_png_srcPath, 'file')
            copyfile(LeopardCamera1_png_srcPath, LeopardCamera1_png_dstPath);
        else
            fprintf('%s can not be found.\n', LeopardCamera1_png_srcPath);
        end
    else
        fprintf('%s has been already exist.\n', LeopardCamera1_png_dstPath);
    end
    LeopardCamera1_json_dstPath = fullfile(folder_LeopardCamera1,sprintf('%.3f.json', LeopardCamera1_timestamp));
    if ~exist(LeopardCamera1_json_dstPath, 'file') || OVERWRITE_ON == 1
        LeopardCamera1_json = struct();
        LeopardCamera1_json.timestamp = sprintf('%.3f', LeopardCamera1_timestamp);
        LeopardCamera1_json.png_filename = sprintf('%.3f.png', LeopardCamera1_timestamp);
        LeopardCamera1_json.width = 3517;
        LeopardCamera1_json.height = 1700;
        LeopardCamera1_json.IntrinsicMatrix = LeopardCamera1_IntrinsicMatrix;
        LeopardCamera1_json.annotation = struct();
        savejson('', LeopardCamera1_json, 'FileName', LeopardCamera1_json_dstPath);
    else
        fprintf('%s has been already exist.\n', LeopardCamera1_json_dstPath);
    end

    % VelodyneLidar
    VelodyneLidar_pcd_srcPath = VelodyneLidar_pcd_path;
    temp = split(VelodyneLidar_pcd_srcPath, filesep);
    temp = replace(temp{end}, '.pcd', '');
    VelodyneLidar_timestamp = str2double(temp);
    VelodyneLidar_timestamp_str = temp;
%     VelodyneLidar_pcd_dstPath = fullfile(folder_VelodyneLidar, sprintf('%.3f.pcd', VelodyneLidar_timestamp));
    VelodyneLidar_pcd_dstPath = fullfile(folder_VelodyneLidar, sprintf('%s.pcd', VelodyneLidar_timestamp_str));
    if ~exist(VelodyneLidar_pcd_dstPath, 'file') || OVERWRITE_ON == 1
        if exist(VelodyneLidar_pcd_srcPath, 'file')
            copyfile(VelodyneLidar_pcd_srcPath, VelodyneLidar_pcd_dstPath);
        else
            fprintf('%s can not be found.\n', VelodyneLidar_pcd_srcPath);
        end        
    else
        fprintf('%s has been already exist.\n', VelodyneLidar_pcd_dstPath);
    end
    VelodyneLidar_json_dstPath = fullfile(folder_VelodyneLidar, sprintf('%.3f.json',VelodyneLidar_timestamp));
    if ~exist(VelodyneLidar_json_dstPath, 'file') || OVERWRITE_ON == 1
        VelodyneLidar_json = struct();
        VelodyneLidar_json.timestamp = sprintf('%.3f',VelodyneLidar_timestamp);
        VelodyneLidar_json.ros_timestamp = VelodyneLidar_timestamp_str; % ros timestamp
        VelodyneLidar_json.pcd_filename = sprintf('%.3f.pcd', VelodyneLidar_timestamp);
        VelodyneLidar_json.pcd_attributes = struct('x', 'float32', 'y', 'float32', 'z', 'float32', 'intensity', 'float32', 'ring', 'float32', 'time', 'float32');
        VelodyneLidar_json.VelodyneLidar_to_LeopardCamera1_TransformMatrix = VelodyneLidar_to_LeopardCamera1_TransformMatrix;
        VelodyneLidar_json.annotation = struct();
        savejson('', VelodyneLidar_json, 'FileName', VelodyneLidar_json_dstPath);
    else
        fprintf('%s has been already exist.\n', VelodyneLidar_json_dstPath);
    end

    % OCULiiRadar
    OCULiiRadar_pcd_srcPath = OCULiiRadar_pcd_path;
    temp = split(OCULiiRadar_pcd_srcPath, filesep);
    temp = replace(temp{end}, '.pcd', '');
    OCULiiRadar_timestamp = str2double(temp);
    OCULiiRadar_pcd_dstPath = fullfile(folder_OCULiiRadar, sprintf('%.3f.pcd', OCULiiRadar_timestamp));
    if ~exist(OCULiiRadar_pcd_dstPath, 'file') || OVERWRITE_ON == 1
        if exist(OCULiiRadar_pcd_srcPath, 'file')
            copyfile(OCULiiRadar_pcd_srcPath, OCULiiRadar_pcd_dstPath);
        else
            fprintf('%s can not be found.\n', OCULiiRadar_pcd_srcPath);
        end            
    else
        fprintf('%s has been already exist.\n', OCULiiRadar_pcd_dstPath);
    end
    OCULiiRadar_json_dstPath = fullfile(folder_OCULiiRadar, sprintf('%.3f.json', OCULiiRadar_timestamp));
    if ~exist(OCULiiRadar_json_dstPath, 'file') || OVERWRITE_ON == 1
        OCULiiRadar_json = struct();
        OCULiiRadar_json.timestamp = sprintf('%.3f', OCULiiRadar_timestamp);
        OCULiiRadar_json.pcd_filename = sprintf('%.3f.pcd', OCULiiRadar_timestamp);
        OCULiiRadar_json.pcd_attributes = struct('x', 'float32', 'y', 'float32', 'z', 'float32', 'velocity', 'float32', 'intensity', 'float32');
        OCULiiRadar_json.OCULiiRadar_to_LeopardCamera1_TransformMatrix = OCULiiRadar_to_LeopardCamera1_TransformMatrix;
        OCULiiRadar_json.annotation = struct();
        savejson('', OCULiiRadar_json, 'FileName', OCULiiRadar_json_dstPath);
    else
        fprintf('%s has been already exist.\n', OCULiiRadar_json_dstPath);
    end

    % TIRadar
    TIRadar_pcd_srcPath = TIRadar_pcd_path;
    temp = split(TIRadar_pcd_srcPath, filesep);
    temp = replace(temp{end}, '.pcd', '');
    TIRadar_timestamp = str2double(temp);
    TIRadar_pcd_dstPath = fullfile(folder_TIRadar, sprintf('%.3f.pcd', TIRadar_timestamp));
    if ~exist(TIRadar_pcd_dstPath, 'file') || OVERWRITE_ON == 1
        if exist(TIRadar_pcd_srcPath, 'file')
            copyfile(TIRadar_pcd_srcPath, TIRadar_pcd_dstPath);
        else
            fprintf('%s can not be found.\n', TIRadar_pcd_srcPath);
        end         
    else
        fprintf('%s has been already exist.\n', TIRadar_pcd_dstPath);
    end
    TIRadar_heatmap_srcPath = TIRadar_heatmap_path;
    TIRadar_heatmap_dstPath = fullfile(folder_TIRadar, sprintf('%.3f.heatmap.bin', TIRadar_timestamp));
    if ~exist(TIRadar_heatmap_dstPath, 'file') || OVERWRITE_ON == 1
        if exist(TIRadar_heatmap_srcPath, 'file')
            copyfile(TIRadar_heatmap_srcPath, TIRadar_heatmap_dstPath);
        else
            fprintf('%s can not be found.\n', TIRadar_heatmap_srcPath);
        end         
    else
        fprintf('%s has been already exist.\n', TIRadar_heatmap_dstPath);
    end
    TIRadar_json_dstPath = fullfile(folder_TIRadar, sprintf('%.3f.json', TIRadar_timestamp));
    if ~exist(TIRadar_json_dstPath, 'file') || OVERWRITE_ON == 1
        TIRadar_json = struct();
        TIRadar_json.timestamp = sprintf('%.3f', TIRadar_timestamp);
        TIRadar_json.pcd_filename = sprintf('%.3f.pcd', TIRadar_timestamp);
        TIRadar_json.pcd_attributes = struct('x', 'float32', 'y', 'float32', 'z', 'float32', 'velocity', 'float32', 'SNR', 'float32');
        TIRadar_json.heatmap_info = struct('matrix_name',{'static', 'dynamic','xBin','yBin'},...
            'size',{'257x232','257x232','257x232','257x232'},...
            'format',{'float','float','float','float'});
        TIRadar_json.TIRadar_to_LeopardCamera1_TransformMatrix = TIRadar_to_LeopardCamera1_TransformMatrix;
        TIRadar_json.annotation = struct();
        savejson('', TIRadar_json, 'FileName', TIRadar_json_dstPath);
    else
        fprintf('%s has been already exist.\n', TIRadar_json_dstPath);
    end

end
        


function [folder_LeopardCamera1, folder_VelodyneLidar, folder_OCULiiRadar, folder_TIRadar, folder_MEMS] = createFolders(root_path, groupId, frameId)
    folder_root = fullfile(root_path, sprintf('group%04d_frame%04d',groupId,frameId));
    folder_LeopardCamera1 = fullfile(folder_root, 'LeopardCamera1');
    folder_VelodyneLidar = fullfile(folder_root, 'VelodyneLidar');
    folder_OCULiiRadar = fullfile(folder_root, 'OCULiiRadar');
    folder_TIRadar = fullfile(folder_root, 'TIRadar');
    folder_MEMS = fullfile(folder_root, 'MEMS');

    if ~exist(folder_root, 'dir')
        mkdir(folder_root);
    else
        fprintf('%s has already been created.\n', folder_root);
    end

    if ~exist(folder_LeopardCamera1, 'dir')
        mkdir(folder_LeopardCamera1);
    else
        fprintf('%s has already been created.\n', folder_LeopardCamera1);
    end

    if ~exist(folder_VelodyneLidar, 'dir')
        mkdir(folder_VelodyneLidar);
    else
        fprintf('%s has already been created.\n', folder_VelodyneLidar);
    end

    if ~exist(folder_OCULiiRadar, 'dir')
        mkdir(folder_OCULiiRadar);
    else
        fprintf('%s has already been created.\n', folder_OCULiiRadar);
    end

    if ~exist(folder_TIRadar, 'dir')
        mkdir(folder_TIRadar);
    else
        fprintf('%s has already been created.\n', folder_TIRadar);
    end

    if ~exist(folder_MEMS, 'dir')
        mkdir(folder_MEMS);
    else
        fprintf('%s has already been created.\n', folder_MEMS);
    end
    
end
