%% load lidar data
clear; close all; clc;
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

%% 
frame_data_info =  [atan(-frame_data(:,2)./frame_data(:,1))/pi()*180 + (frame_data(:,1)<0)*180+ (frame_data(:,1)>0 & frame_data(:,2)>0)*360, frame_data(:, 6), frame_data];
rings = unique(frame_data_info(:,7));

frame_data_new = [];
start_angles = [];
for ringId = 1 : size(rings, 1)
    ring = rings(ringId);
    frame_data_info_ring = frame_data_info(frame_data_info(:,7) == ring, :);

    [tsorted, I] = sort(frame_data_info_ring(:, 2));
    frame_data_info_ring_sorted = frame_data_info_ring(I, :);
    times = unique(frame_data_info_ring_sorted(:,2));

    start_angle = min(frame_data_info_ring_sorted(frame_data_info_ring_sorted(:,2)==times(1)));
    start_angles = [start_angles, start_angle];
    frame_data_info_ring_sorted_re = [frame_data_info_ring_sorted(:,1)-start_angle, frame_data_info_ring_sorted(:,2:end)];
    
    thred1 = 340;
    thred2 = 180;

    while isempty(find(frame_data_info_ring_sorted_re(:,1) > thred1, 1))
        thred1 = thred1 - 10;
    end
    for i = find(times==frame_data_info_ring_sorted_re(find(frame_data_info_ring_sorted_re(:,1) > thred1, 1), 2)) : size(times, 1)
        angles = frame_data_info_ring_sorted_re(frame_data_info_ring_sorted(:,2)==times(i), :);
        overlap_flags = [];
        for j = 1:size(angles, 1)
            if angles(j, 1) >= 0 && angles(j, 1) < thred2
                overlap_flags = [overlap_flags, 1];
            else
                overlap_flags = [overlap_flags, 0];
            end   
        end
        frame_data_info_ring_sorted_re(frame_data_info_ring_sorted(:,2)==times(i), 9) = overlap_flags;
    end

    frame_data_new = [frame_data_new; frame_data_info_ring_sorted_re(frame_data_info_ring_sorted_re(:,end)==0, 3:8)];
end

%% 
OverlapAngle = mean(start_angles);
fprintf("Overlap Angle = %.4f\n", OverlapAngle);
angles = unique(frame_data_info(:,1));
angles_diff = angles(2:end) - angles(1:end-1);
fprintf("Angle Diff Max = %.4f\n", max(angles_diff));

quality = 0;
FOV = [270, 90];
if OverlapAngle > FOV(1) || OverlapAngle < FOV(2)
    quality = quality + 1;
end
ANGLEDIFF_THRED = 0.1;
if max(angles_diff) > ANGLEDIFF_THRED
    quality = quality + 2;
end
%% save
writepcd("./test2.pcd", frame_data_new);
function writepcd(output_pcd_path, pcd_data)
    fid = fopen(output_pcd_path, "w");
    fprintf(fid, "VERSION .7\n");
    fprintf(fid, "FIELDS x y z intensity ring time\n");
    fprintf(fid, "SIZE 4 4 4 4 4 4\n");
    fprintf(fid, "TYPE F F F F F F\n");
    fprintf(fid, "COUNT 1 1 1 1 1 1\n");
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
        fprintf(fid, "%f ", pcd_data(i, 5));
        fprintf(fid, "%f", pcd_data(i, 6));
        fprintf(fid, "\n");
    end
    fclose(fid);
end