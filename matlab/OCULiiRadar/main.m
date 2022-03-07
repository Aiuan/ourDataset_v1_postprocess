clear; close all; clc;

input = {
    % [processfolder(csv), savefolder(pcd)]
%     ["/mnt/DATASET/20211025_1/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211025_1/OCULiiRadar"],
%     ["/mnt/DATASET/20211025_2/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211025_2/OCULiiRadar"],
%     ["/mnt/DATASET/20211025_3/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211025_3/OCULiiRadar"],
%     ["/mnt/DATASET/20211026_1/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211026_1/OCULiiRadar"],
%     ["/mnt/DATASET/20211026_2/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211026_2/OCULiiRadar"],
%     ["/mnt/DATASET/20211027_1/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211027_1/OCULiiRadar"],
%     ["/mnt/DATASET/20211027_2/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211027_2/OCULiiRadar"],
    ["/mnt/DATASET/20211028_1/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211028_1/OCULiiRadar"],
%     ["/mnt/DATASET/20211028_2/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211028_2/OCULiiRadar"],
%     ["/mnt/DATASET/20211029_1/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211029_1/OCULiiRadar"],
%     ["/mnt/DATASET/20211029_2/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211029_2/OCULiiRadar"],
%     ["/mnt/DATASET/20211030_1/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211030_1/OCULiiRadar"],
%     ["/mnt/DATASET/20211031_1/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211031_1/OCULiiRadar"],
%     ["/mnt/DATASET/20211031_2/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211031_2/OCULiiRadar"],
%     ["/mnt/DATASET/20211031_3/OCULiiRadar/radar_1/pcl/pcl.csv", "/media/ourDataset/preprocess/20211031_3/OCULiiRadar"],

};

for n = 1 : size(input, 1)
    tic;
    csv_path = input{n, 1}(1);
    folder_output = input{n, 1}(2); 

    if ~exist(folder_output, "dir")
        fprintf("create outputfolder: %s\n", folder_output);
        mkdir(folder_output);
    end

    data = readmatrix(csv_path);
    fprintf("read completed: %s\n", csv_path);
    timestamps = unique(data(:, 2));
    for i = 1 : length(timestamps)
        frame_timestamp = timestamps(i);        
        output_pcd_path = sprintf("%s/%.3f.pcd", folder_output,round(frame_timestamp/1e6,3));
        if exist(output_pcd_path, 'file')
            fprintf("(%d / %d)Current frame's timestamp = %.3f has already been generated.\n",i, length(timestamps), round(frame_timestamp/1e6,3));
            continue;
        end
        fprintf("(%d / %d)Current frame's timestamp = %.3f\n",i, length(timestamps), round(frame_timestamp/1e6,3));
        mask = (data(:, 2) == frame_timestamp);
        frame_data = data(mask, :);
        xyz = frame_data(:, 17:19);
        velocity = frame_data(:, 12);
        intensity = frame_data(:, 15);            
        writepcd(output_pcd_path, [xyz, velocity, intensity]);
    end

    timeUsed = toc;
    fprintf("%s has been processed, results save in %s, timeUsed = %.3f s\n", csv_path, folder_output, timeUsed);
end


function writepcd(output_pcd_path, pcd_data)
    fid = fopen(output_pcd_path, "w");
    fprintf(fid, "VERSION .7\n");
    fprintf(fid, "FIELDS x y z velocity intensity\n");
    fprintf(fid, "SIZE 4 4 4 4 4\n");
    fprintf(fid, "TYPE F F F F F\n");
    fprintf(fid, "COUNT 1 1 1 1 1\n");
    fprintf(fid, "WIDTH %d\n", size(pcd_data, 1));
    fprintf(fid, "HEIGHT 1\n");
    fprintf(fid, "VIEWPOINT 0 0 0 1 0 0 0\n");
    fprintf(fid, "POINTS %d\n", size(pcd_data, 1));
    fprintf(fid, "DATA ascii\n");    
    for i = 1:size(pcd_data, 1)
        fprintf(fid, "%f ", pcd_data(i, 1));
        fprintf(fid, "%f ", pcd_data(i, 2));
        fprintf(fid, "%f ", pcd_data(i, 3));
        fprintf(fid, "%f ", pcd_data(i, 4));
        fprintf(fid, "%f", pcd_data(i, 5));
        fprintf(fid, "\n");
    end
    fclose(fid);
end