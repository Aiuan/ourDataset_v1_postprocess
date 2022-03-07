%% load lidar data
clear; close all; clc;
tic;
pcd_path = "./data/chongdie2.pcd";
fid = fopen(pcd_path);
for i =1 : 11
    tline = fgetl(fid);
end
frame_data = [];
while ~feof(fid)
    x = fread(fid, 1, "single");
    if feof(fid)
        break;
    end
    y = fread(fid, 1, "single");
    if feof(fid)
        break;
    end
    z = fread(fid, 1, "single");
    if feof(fid)
        break;
    end
    intensity = fread(fid, 1, "single");
    if feof(fid)
        break;
    end
    ring = fread(fid, 1, "uint16");
    if feof(fid)
        break;
    end
    time = fread(fid, 1, "single");
    if feof(fid)
        break;
    end
    if x==0&&y==0&&z==0&&intensity==0&&ring==0&&time==0
        break;
    end    
    frame_data = [frame_data; x y z intensity ring time];    
end
fclose(fid);
toc;

%% load lidar data
clear; close all; clc;
tic;
pcd_path = "./data/chongdie2.pcd";
pcddata = pcread(pcd_path).Location;

fid = fopen(pcd_path);
fseek(fid,212,'bof');
x_y_z_intensity = fread(fid, "4*float", 6);
n = ceil(size(x_y_z_intensity,1)/4);
for i = 1:4*n-size(x_y_z_intensity,1)
    x_y_z_intensity(end+1) = 0;
end
x_y_z_intensity = reshape(x_y_z_intensity, 4, [])';

fseek(fid,212+16,'bof');
ring = fread(fid, "uint16", 20);
for i = 1:n-size(ring,1)
    ring(end+1) = 0;
end

fseek(fid,212+18,'bof');
time = fread(fid, "float", 18);
for i = 1:n-size(time,1)
    time(end+1) = 0;
end
fclose(fid);

frame_data = [x_y_z_intensity, ring, time];
mask = sum(frame_data, 2)~=0;
frame_data = frame_data(mask, :);
toc;