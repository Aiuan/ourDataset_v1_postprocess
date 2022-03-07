clear all; close all; clc;

WAITKEY_ON = true;
PROJECT_ON = true;

dataset_process_folder = '/media/ourDataset/preprocess';

dataset_group = '20211025_1';
LeopardCamera1_timestamps_folder = './filted_LeopardCamera1_timestamps';
VelodyneLidar_timestamps_folder = './VelodyneLidar_timestamps';
OCULiiRadar_timestamps_folder = './OCULiiRadar_timestamps';
TIRadar_timestamps_folder = './TIRadar_timestamps';

max_synchro_error = 0.5; % s
LeopardCamera1_timestamps_offset = 0; % s
VelodyneLidar_timestamps_offset = 0; % s
OCULiiRadar_timestamps_offset = 0; % s
TIRadar_timestamps_offset = 0; % s

load('./calib_results/LeopardCamera1_IntrinsicMatrix.mat');
load('./calib_results/VelodyneLidar_to_LeopardCamera1_TransformMatrix.mat');
load('./calib_results/OCULiiRadar_to_LeopardCamera1_TransformMatrix.mat');
load('./calib_results/TIRadar_to_LeopardCamera1_TransformMatrix.mat');

process_single(dataset_group, dataset_process_folder, max_synchro_error, WAITKEY_ON, PROJECT_ON,...
    LeopardCamera1_timestamps_folder, LeopardCamera1_timestamps_offset,...
    VelodyneLidar_timestamps_folder,VelodyneLidar_timestamps_offset,...
    OCULiiRadar_timestamps_folder, OCULiiRadar_timestamps_offset,...
    TIRadar_timestamps_folder, TIRadar_timestamps_offset,...
    LeopardCamera1_IntrinsicMatrix, VelodyneLidar_to_LeopardCamera1_TransformMatrix, OCULiiRadar_to_LeopardCamera1_TransformMatrix, TIRadar_to_LeopardCamera1_TransformMatrix);


%%
function process_single(dataset_group, dataset_process_folder, max_synchro_error, WAITKEY_ON, PROJECT_ON,...
    LeopardCamera1_timestamps_folder, LeopardCamera1_timestamps_offset,...
    VelodyneLidar_timestamps_folder,VelodyneLidar_timestamps_offset,...
    OCULiiRadar_timestamps_folder, OCULiiRadar_timestamps_offset,...
    TIRadar_timestamps_folder, TIRadar_timestamps_offset,...
    LeopardCamera1_IntrinsicMatrix, VelodyneLidar_to_LeopardCamera1_TransformMatrix, OCULiiRadar_to_LeopardCamera1_TransformMatrix, TIRadar_to_LeopardCamera1_TransformMatrix)

    load(fullfile(LeopardCamera1_timestamps_folder, strcat(dataset_group, '.mat')));
    LeopardCamera1_timestamps = LeopardCamera1_timestamps + LeopardCamera1_timestamps_offset;
    load(fullfile(VelodyneLidar_timestamps_folder, strcat(dataset_group, '.mat')));
    VelodyneLidar_timestamps = VelodyneLidar_timestamps + VelodyneLidar_timestamps_offset;
    load(fullfile(OCULiiRadar_timestamps_folder, strcat(dataset_group, '.mat')));
    OCULiiRadar_timestamps = OCULiiRadar_timestamps + OCULiiRadar_timestamps_offset;
    load(fullfile(TIRadar_timestamps_folder, strcat(dataset_group, '.mat')));
    TIRadar_timestamps = TIRadar_timestamps + TIRadar_timestamps_offset;
    
    match_results = match_sensers_timestamps(max_synchro_error, LeopardCamera1_timestamps, VelodyneLidar_timestamps, OCULiiRadar_timestamps, TIRadar_timestamps);
    fig = figure('Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
    for i = 1:length(match_results)
        groupId = match_results(i).groupId;
        for j = 1:length(match_results(i).group)
            frameId = match_results(i).group(j).frameId;
            
            disp('===========================================================');
            fprintf('Show groupId%04d_frameId%04d\n', groupId, frameId);
            tic;
            LeopardCamera1_timestamp = match_results(i).group(j).LeopardCamera1_timestamp;
            LeopardCamera1_png_path = fullfile(dataset_process_folder, dataset_group, 'LeopardCamera1', sprintf('%.3f.png', LeopardCamera1_timestamp));

            VelodyneLidar_timestamp = match_results(i).group(j).VelodyneLidar_timestamp;
            VelodyneLidar_pcd_path = fullfile(dataset_process_folder, dataset_group, 'VelodyneLidar', sprintf('%.9f.pcd', VelodyneLidar_timestamp));
%             VelodyneLidar_pcd_path = fullfile(dataset_process_folder, dataset_group, 'VelodyneLidar_fixed', sprintf('%.3f.pcd', VelodyneLidar_timestamp));

            OCULiiRadar_timestamp = match_results(i).group(j).OCULiiRadar_timestamp;
            OCULiiRadar_pcd_path = fullfile(dataset_process_folder, dataset_group, 'OCULiiRadar', sprintf('%.3f.pcd', OCULiiRadar_timestamp));

            TIRadar_timestamp = match_results(i).group(j).TIRadar_timestamp;
            TIRadar_pcd_path = fullfile(dataset_process_folder, dataset_group, 'TIRadar', sprintf('%.3f.pcd', TIRadar_timestamp));
            
            showScence(fig, PROJECT_ON,...
                LeopardCamera1_png_path, VelodyneLidar_pcd_path, OCULiiRadar_pcd_path, TIRadar_pcd_path,...
                LeopardCamera1_IntrinsicMatrix, VelodyneLidar_to_LeopardCamera1_TransformMatrix, OCULiiRadar_to_LeopardCamera1_TransformMatrix, TIRadar_to_LeopardCamera1_TransformMatrix)
            toc;
            
            pause(0.1);

            if WAITKEY_ON
                key = waitforbuttonpress;
                while(key==0)
                    key = waitforbuttonpress;
                end        
            end
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

function showScence(fig, PROJECT_ON,...
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
  
    
    tg = uitabgroup(fig);
    t1 = uitab(tg);
    t1.Title = 'sensors';
    t1_ax1 = axes(t1, 'Units', 'normalized', 'OuterPosition', [0, 0.5, 0.5, 0.5]);
    imshow(LeopardCamera1_png);
    title(sprintf('LeopardCamera1: %s s (diff=%.3f s)', LeopardCamera1_timestamp, str2double(LeopardCamera1_timestamp)-str2double(LeopardCamera1_timestamp)));
    t1_ax2 = axes(t1, 'Units', 'normalized', 'OuterPosition', [0.5, 0.5, 0.5, 0.5]);
    scatter3([VelodyneLidar_pcd_struct.x],...
        [VelodyneLidar_pcd_struct.y],...
        [VelodyneLidar_pcd_struct.z],...
        5,...
        [VelodyneLidar_pcd_struct.intensity],...
        'filled')
    xlabel('x(m)');
    ylabel('y(m)');
    zlabel('z(m)');
    axis([VelodyneLidar_x_ranges(1), VelodyneLidar_x_ranges(2), VelodyneLidar_y_ranges(1), VelodyneLidar_y_ranges(2), VelodyneLidar_z_ranges(1), VelodyneLidar_z_ranges(2)]);
    title(sprintf('VelodyneLidar: %s s (diff=%.3f s)', VelodyneLidar_timestamp, str2double(VelodyneLidar_timestamp)-str2double(LeopardCamera1_timestamp)));
    set(t1_ax2, 'View', [-90, 90]);
    colormap("jet");
    colorbar;
    t1_ax3 = axes(t1, 'Units', 'normalized', 'OuterPosition', [0, 0, 0.5, 0.5]);
    scatter3([OCULiiRadar_pcd_struct.x],...
        [OCULiiRadar_pcd_struct.y],...
        [OCULiiRadar_pcd_struct.z],...
        5,...
        [OCULiiRadar_pcd_struct.velocity],...
        'filled')
    xlabel('x(m)');
    ylabel('y(m)');
    zlabel('z(m)');
    axis([OCULiiRadar_x_ranges(1), OCULiiRadar_x_ranges(2), OCULiiRadar_y_ranges(1), OCULiiRadar_y_ranges(2), OCULiiRadar_z_ranges(1), OCULiiRadar_z_ranges(2)]);
    title(sprintf('OCULiiRadar: %s s (diff=%.3f s)', OCULiiRadar_timestamp, str2double(OCULiiRadar_timestamp)-str2double(LeopardCamera1_timestamp)));
    set(t1_ax3, 'View', [0, 0]);
    colormap("jet");
    colorbar;
    t1_ax4 = axes(t1, 'Units', 'normalized', 'OuterPosition', [0.5, 0, 0.5, 0.5]);
    scatter3([TIRadar_pcd_struct.x],...
        [TIRadar_pcd_struct.y],...
        [TIRadar_pcd_struct.z],...
        5,...
        [TIRadar_pcd_struct.velocity],...
        'filled')
    xlabel('x(m)');
    ylabel('y(m)');
    zlabel('z(m)');
    axis([TIRadar_x_ranges(1), TIRadar_x_ranges(2), TIRadar_y_ranges(1), TIRadar_y_ranges(2), TIRadar_z_ranges(1), TIRadar_z_ranges(2)]);
    title(sprintf('TIRadar: %s s (diff=%.3f s)', TIRadar_timestamp, str2double(TIRadar_timestamp)-str2double(LeopardCamera1_timestamp)));
    set(t1_ax4, 'View', [0, 90]);
    colormap("jet");
    colorbar;

    if PROJECT_ON
        t2 = uitab(tg);
        t2.Title = 'projection';
        t2_ax1 = axes(t2, 'Units', 'normalized', 'OuterPosition', [0, 0.5, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('LeopardCamera1: %s s (diff=%.3f s)', LeopardCamera1_timestamp, str2double(LeopardCamera1_timestamp)-str2double(LeopardCamera1_timestamp)));
        t2_ax2 = axes(t2, 'Units', 'normalized', 'OuterPosition', [0.5, 0.5, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('VelodyneLidar: %s s (diff=%.3f s)', VelodyneLidar_timestamp, str2double(VelodyneLidar_timestamp)-str2double(LeopardCamera1_timestamp)));
        hold on;
        scatter([VelodyneLidar_pcd_struct.u],...
            [VelodyneLidar_pcd_struct.v],...
            5,...
            [VelodyneLidar_pcd_struct.intensity],...
            'filled');
        hold off;
        t2_ax3 = axes(t2, 'Units', 'normalized', 'OuterPosition', [0, 0, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('OCULiiRadar: %s s (diff=%.3f s)', OCULiiRadar_timestamp, str2double(OCULiiRadar_timestamp)-str2double(LeopardCamera1_timestamp)));
        hold on;
        scatter([OCULiiRadar_pcd_struct.u],...
            [OCULiiRadar_pcd_struct.v],...
            5,...
            [OCULiiRadar_pcd_struct.velocity],...
            'filled');
        hold off;
        t2_ax4 = axes(t2, 'Units', 'normalized', 'OuterPosition', [0.5, 0, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('TIRadar: %s s (diff=%.3f s)', TIRadar_timestamp, str2double(TIRadar_timestamp)-str2double(LeopardCamera1_timestamp)));
        hold on;
        scatter([TIRadar_pcd_struct.u],...
            [TIRadar_pcd_struct.v],...
            5,...
            [TIRadar_pcd_struct.velocity],...
            'filled');
        hold off;
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
    uv1=transformMatrix * xyz1 * (diag(1./([0,0,1] * transformMatrix * xyz1)));
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

