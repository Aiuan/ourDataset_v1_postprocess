% 测试raw转rgb图像并调色
clear all; close all; clc;

path = "/mnt/DATASET/20211025_3/LeopardCamera1/1635163440.48191.raw";
intrinsics_path = "./LeopardCamera1_oringin.mat";
load(intrinsics_path);

%%
fprintf("===============================================\n");
tic;
image_rgb = raw2rgb2(path, 1, 1, 1);
toc;
fprintf("raw2rgb completed.\n");

tic;
% 去畸变
image_undistort = undistortImage(image_rgb, cameraParams, "OutputView", "valid");
toc;
fprintf("undistort completed.\n");

% 裁剪
% figure();
% imshow(image_undistort);
% rectangle("Position", [1, 1, 3517-1, 1700-1], "EdgeColor", "r", "LineWidth", 2);
tic;
image_undistort_cutReshape = image_undistort(1:1700, :, :);
toc;
fprintf("cutReshape completed.\n");
figure();
imshow(image_undistort_cutReshape);

%%
fprintf("===============================================\n");
tic;
image_rgb = raw2rgb(path, 1, 1, 1);
toc;
fprintf("raw2rgb completed.\n");
% figure();
% imshow(img_rgb);

tic;
% 去畸变
image_undistort = undistortImage(image_rgb, cameraParams, "OutputView", "valid");
toc;
fprintf("undistort completed.\n");

% 裁剪
% figure();
% imshow(image_undistort);
% rectangle("Position", [1, 1, 3517-1, 1700-1], "EdgeColor", "r", "LineWidth", 2);
tic;
image_undistort_cutReshape = image_undistort(1:1700, :, :);
toc;
fprintf("cutReshape completed.\n");
figure();
imshow(image_undistort_cutReshape);







