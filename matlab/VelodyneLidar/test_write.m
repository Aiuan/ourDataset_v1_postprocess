clear;close all;clc;
load("./data/frame_data_new.mat");

%%
tic;
writepcd1("./runs/test_write1.pcd", frame_data_new);
toc;

%%
tic;
writepcd2("./runs/test_write2.pcd", frame_data_new);
toc;

%%
function writepcd1(output_pcd_path, pcd_data)
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


function writepcd2(output_pcd_path, pcd_data)    

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