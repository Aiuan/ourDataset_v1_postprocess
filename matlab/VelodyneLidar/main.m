clear; close all; clc;

input = {
    % [processfolder(pcd), savefolder(pcd)]
    ["/media/ourDataset/preprocess/20211025_1/VelodyneLidar", "/media/ourDataset/preprocess/20211025_1/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211025_2/VelodyneLidar", "/media/ourDataset/preprocess/20211025_2/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211025_3/VelodyneLidar", "/media/ourDataset/preprocess/20211025_3/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211026_1/VelodyneLidar", "/media/ourDataset/preprocess/20211026_1/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211026_2/VelodyneLidar", "/media/ourDataset/preprocess/20211026_2/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211027_1/VelodyneLidar", "/media/ourDataset/preprocess/20211027_1/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211027_2/VelodyneLidar", "/media/ourDataset/preprocess/20211027_2/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211028_1/VelodyneLidar", "/media/ourDataset/preprocess/20211028_1/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211028_2/VelodyneLidar", "/media/ourDataset/preprocess/20211028_2/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211029_1/VelodyneLidar", "/media/ourDataset/preprocess/20211029_1/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211029_2/VelodyneLidar", "/media/ourDataset/preprocess/20211029_2/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211030_1/VelodyneLidar", "/media/ourDataset/preprocess/20211030_1/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211031_1/VelodyneLidar", "/media/ourDataset/preprocess/20211031_1/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211031_2/VelodyneLidar", "/media/ourDataset/preprocess/20211031_2/VelodyneLidar_fixed"];
%     ["/media/ourDataset/preprocess/20211031_3/VelodyneLidar", "/media/ourDataset/preprocess/20211031_3/VelodyneLidar_fixed"];
};

for n = 1 : size(input, 1)
    timeStart = tic;
    forder_input = input{n, 1}(1);
    folder_output = input{n, 1}(2); 
    folder_logs = fullfile(folder_output, "logs");

    if ~exist(folder_output, "dir")
        fprintf("create outputfolder: %s\n", folder_output);
        mkdir(folder_output);
    end

    if ~exist(folder_logs, "dir")
        fprintf("create logsfolder: %s\n", folder_logs);
        mkdir(folder_logs);
    end
    
    pcd_info = dir(fullfile(forder_input, "*.pcd"));
    parfor i = 1:size(pcd_info, 1)        
        pcd_path = fullfile(pcd_info(i).folder, pcd_info(i).name);
        fprintf("(%d/%d)Processing %s", i, size(pcd_info, 1), pcd_path);
        
        timestamp = sprintf("%.3f",round(str2double(replace(pcd_info(i).name, ".pcd", "")),3));
        pcdFilename = strcat(timestamp, ".pcd");
        output_pcd_path = fullfile(folder_output, pcdFilename); 
        if exist(output_pcd_path, "file")
            fprintf(", has been processed\n");
            continue;
        else
            time1 = tic;
            [frame_data_new, quality, OverlapAngle, max_angles_diff] = fixPcd(pcd_path);
            % quality OverlapAngle max_angles_diff
            logFilename = strcat(timestamp, ".txt");
            writematrix([quality; OverlapAngle; max_angles_diff], fullfile(folder_logs, logFilename));
            time2 = tic;
            fprintf(", processTime = %.6f s", (double(time2)-double(time1))/1e6);
        end
        
        
        time3 = tic;         
        writepcd(output_pcd_path, frame_data_new);
        time4 = tic;
        fprintf(", saveTime = %.6f s", (double(time4)-double(time3))/1e6);

        fprintf("\n");
    end
    

    timeEnd = tic;
    fprintf("%s has been processed, results save in %s, timeUsed = %.6f s\n", forder_input, folder_output, (double(timeEnd)-double(timeStart))/1e6);
end


function [frame_data_new, quality, OverlapAngle, max_angles_diff] = fixPcd(pcd_path)
    frame_data = readVelodynePcd(pcd_path);
    % clear nan in row
    frame_data((sum(isnan(frame_data),2)~=0), :) = [];
    
    frame_data_info =  [atan(-frame_data(:,2)./frame_data(:,1))/pi()*180 + (frame_data(:,1)<0)*180+ (frame_data(:,1)>0 & frame_data(:,2)>0)*360, frame_data(:, 6), frame_data];
    [~, I] = sort(frame_data_info(:, 2));
    frame_data_info_sorted = frame_data_info(I, :);
    times = unique(frame_data_info_sorted(:,2));
    start_angle = min(frame_data_info_sorted(frame_data_info_sorted(:,2)==times(1)));
    frame_data_info_sorted_re = [frame_data_info_sorted(:,1)-start_angle, frame_data_info_sorted(:,2:end)];
    THRED1 = 340;
    THRED2 = 180;
    while isempty(find(frame_data_info_sorted_re(:,1) > THRED1, 1))
        THRED1 = THRED1 - 10;
    end
    for i = find(times==frame_data_info_sorted_re(find(frame_data_info_sorted_re(:,1) > THRED1, 1), 2)) : size(times, 1)
        angles = frame_data_info_sorted_re(frame_data_info_sorted(:,2)==times(i), :);
        overlap_flags = [];
        for j = 1:size(angles, 1)
            if angles(j, 1) >= 0 && angles(j, 1) < THRED2
                overlap_flags = [overlap_flags, 1];
            else
                overlap_flags = [overlap_flags, 0];
            end   
        end
        frame_data_info_sorted_re(frame_data_info_sorted(:,2)==times(i), 9) = overlap_flags;
    end
    frame_data_new = frame_data_info_sorted_re(frame_data_info_sorted_re(:,end)==0, 3:8);
    
    OverlapAngle = start_angle;
    %fprintf("Overlap Angle = %.4f\n", OverlapAngle);
    angles = unique(frame_data_info(:,1));
    angles_diff = angles(2:end) - angles(1:end-1);
    %fprintf("Angle Diff Max = %.4f\n", max(angles_diff));    
    quality = 0;
    FOV = [270, 90];
    if OverlapAngle > FOV(1) || OverlapAngle < FOV(2)
        quality = quality + 1;
    end
    ANGLEDIFF_THRED = 0.1;
    max_angles_diff = max(angles_diff);
    if max_angles_diff > ANGLEDIFF_THRED
        quality = quality + 2;
    end

end

function frame_data = readVelodynePcd(pcd_path)
    timeReadStart = tic;
    fid = fopen(pcd_path);
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
    frame_data = [x_y_z_intensity, ring, time];
    % cut zero points
    mask = sum(frame_data, 2)~=0;
    frame_data = frame_data(mask, :);
    timeReadEnd = tic;
    fprintf(", readpcdTime = %.6f s", (double(timeReadEnd)-double(timeReadStart))/1e6);
end

function writepcd(output_pcd_path, pcd_data)

    fid = fopen(output_pcd_path, "w");
    fprintf(fid, "VERSION .7\n" + ...
        "FIELDS x y z intensity ring time\n" + ...
        "SIZE 4 4 4 4 4 4\n" + ...
        "TYPE F F F F F F\n" + ...
        "COUNT 1 1 1 1 1 1\n" + ...
        "WIDTH %d\n" + ...
        "HEIGHT 1\n" + ...
        "VIEWPOINT 0 0 0 1 0 0 0\n" + ...
        "POINTS %d\n" + ...
        "DATA ascii\n", size(pcd_data, 1), size(pcd_data, 1));
    fclose(fid);
    
    writematrix(pcd_data, output_pcd_path, "FileType", "text", "WriteMode", "append","Delimiter", " ")

end