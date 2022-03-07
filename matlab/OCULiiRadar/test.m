%% 
clear; close all; clc;

csv_path = "/mnt/DATASET/20211025_1/OCULiiRadar/radar_1/pcl/pcl.csv";

data = readmatrix(csv_path);

%%
timestamps = unique(data(:, 2));
for i = 1 : length(timestamps)
    frame_timestamp = timestamps(i);
    fprintf("Current frame's timestamp = %.3f\n",round(frame_timestamp/1e6,3));
    mask = (data(:, 2) == frame_timestamp);
    frame_data = data(mask, :);
    xyz = frame_data(:, 17:19);
    velocity = frame_data(:, 12);
    intensity = frame_data(:, 15);    
    output_pcd_path = sprintf("./%.3f.pcd",round(frame_timestamp/1e6,3));
    writepcd(output_pcd_path, [xyz, velocity, intensity]);
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