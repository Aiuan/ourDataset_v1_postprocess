clear all; close all; clc;
OVERWRITE_ON = 1;

root_path = './';
groupId = 0;
frameId = 0;
[folder_LeopardCamera1, folder_VelodyneLidar, folder_OCULiiRadar, folder_TIRadar, folder_MEMS] = createFolders(root_path, groupId, frameId);

%%
folderName = '20211025_1';
LeopardCamera1_png_dataFolder = fullfile('/media/ourDataset/preprocess', folderName, 'LeopardCamera1');
LeopardCamera1_raw_dataFolder = fullfile('/mnt/DATASET', folderName, 'LeopardCamera1');
VelodyneLidar_pcd_dataFolder = fullfile('/media/ourDataset/preprocess', folderName, 'VelodyneLidar_fixed');
OCULiiRadar_dataFolder = fullfile('/media/ourDataset/preprocess', folderName, 'OCULiiRadar');
TIRadar_dataFolder = fullfile('/media/ourDataset/preprocess', folderName, 'TIRadar');

calib_path = '../calib_results';
load(fullfile(calib_path,"LeopardCamera1_IntrinsicMatrix.mat"));
load(fullfile(calib_path,"OCULiiRadar_to_LeopardCamera1_TransformMatrix.mat"));
load(fullfile(calib_path,"TIRadar_to_LeopardCamera1_TransformMatrix.mat"));
load(fullfile(calib_path,"VelodyneLidar_to_LeopardCamera1_TransformMatrix.mat"));

%%
LeopardCamera1_timestamp = 1635145524.879;
LeopardCamera1_raw_srcPath = fullfile(LeopardCamera1_raw_dataFolder, '1635145524.87876.raw');
LeopardCamera1_raw_dstPath = fullfile(folder_LeopardCamera1,sprintf('%.3f.raw', LeopardCamera1_timestamp));
if ~exist(LeopardCamera1_raw_dstPath, 'file') || OVERWRITE_ON == 1
    copyfile(LeopardCamera1_raw_srcPath, LeopardCamera1_raw_dstPath);
else
    fprintf('%s has been already exist.\n', LeopardCamera1_raw_dstPath);
end
LeopardCamera1_png_srcPath = fullfile(LeopardCamera1_png_dataFolder, sprintf('%.3f.png', LeopardCamera1_timestamp));
LeopardCamera1_png_dstPath = fullfile(folder_LeopardCamera1,sprintf('%.3f.png', LeopardCamera1_timestamp));
if ~exist(LeopardCamera1_png_dstPath, 'file') || OVERWRITE_ON == 1
    copyfile(LeopardCamera1_png_srcPath, LeopardCamera1_png_dstPath);
else
    fprintf('%s has been already exist.\n', LeopardCamera1_png_dstPath);
end
LeopardCamera1_json_dstPath = fullfile(folder_LeopardCamera1,sprintf('%.3f.json', LeopardCamera1_timestamp));
if ~exist(LeopardCamera1_json_dstPath, 'file') || OVERWRITE_ON == 1
    LeopardCamera1_json = struct();
    LeopardCamera1_json.timestamp = sprintf('%.3f', LeopardCamera1_timestamp);
    LeopardCamera1_json.raw_filename = sprintf('%.3f.raw', LeopardCamera1_timestamp);
    LeopardCamera1_json.png_filename = sprintf('%.3f.png', LeopardCamera1_timestamp);
    LeopardCamera1_json.width = 3517;
    LeopardCamera1_json.height = 1700;
    LeopardCamera1_json.IntrinsicMatrix = LeopardCamera1_IntrinsicMatrix;
    LeopardCamera1_json.annotation = struct();
    savejson('', LeopardCamera1_json, 'FileName', LeopardCamera1_json_dstPath);
else
    fprintf('%s has been already exist.\n', LeopardCamera1_json_dstPath);
end

%%
VelodyneLidar_timestamp = 1635145524.825;
VelodyneLidar_pcd_srcPath = fullfile(VelodyneLidar_pcd_dataFolder, sprintf('%.3f.pcd', VelodyneLidar_timestamp));
VelodyneLidar_pcd_dstPath = fullfile(folder_VelodyneLidar, sprintf('%.3f.pcd', VelodyneLidar_timestamp));
if ~exist(VelodyneLidar_pcd_dstPath, 'file') || OVERWRITE_ON == 1
    copyfile(VelodyneLidar_pcd_srcPath, VelodyneLidar_pcd_dstPath);
else
    fprintf('%s has been already exist.\n', VelodyneLidar_pcd_dstPath);
end
VelodyneLidar_pcd_fixInfo_srcPath = fullfile(VelodyneLidar_pcd_dataFolder, 'logs', sprintf('%.3f.txt', VelodyneLidar_timestamp));
fixInfo = readmatrix(VelodyneLidar_pcd_fixInfo_srcPath);
VelodyneLidar_json_dstPath = fullfile(folder_VelodyneLidar, sprintf('%.3f.json',VelodyneLidar_timestamp));
if ~exist(VelodyneLidar_json_dstPath, 'file') || OVERWRITE_ON == 1
    VelodyneLidar_json = struct();
    VelodyneLidar_json.timestamp = sprintf('%.3f',VelodyneLidar_timestamp);
    VelodyneLidar_json.pcd_filename = sprintf('%.3f.pcd', VelodyneLidar_timestamp);
    VelodyneLidar_json.pcd_attributes = struct('x', 'float32', 'y', 'float32', 'z', 'float32', 'intensity', 'float32', 'ring', 'float32', 'time', 'float32');
    VelodyneLidar_json.fixInfo = struct('quality', fixInfo(1), 'overlapAngle', fixInfo(2), 'max_angles_diff', fixInfo(3));
    VelodyneLidar_json.VelodyneLidar_to_LeopardCamera1_TransformMatrix = VelodyneLidar_to_LeopardCamera1_TransformMatrix;
    VelodyneLidar_json.annotation = struct();
    savejson('', VelodyneLidar_json, 'FileName', VelodyneLidar_json_dstPath);
else
    fprintf('%s has been already exist.\n', VelodyneLidar_json_dstPath);
end

%%
OCULiiRadar_timestamp = 1635145524.862;
OCULiiRadar_pcd_srcPath = fullfile(OCULiiRadar_dataFolder, sprintf('%.3f.pcd', OCULiiRadar_timestamp));
OCULiiRadar_pcd_dstPath = fullfile(folder_OCULiiRadar, sprintf('%.3f.pcd', OCULiiRadar_timestamp));
if ~exist(OCULiiRadar_pcd_dstPath, 'file') || OVERWRITE_ON == 1
    copyfile(OCULiiRadar_pcd_srcPath, OCULiiRadar_pcd_dstPath);
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

%%
TIRadar_timestamp = 1635145476.747;
TIRadar_pcd_srcPath = fullfile(TIRadar_dataFolder, sprintf('%.3f.pcd', TIRadar_timestamp));
TIRadar_pcd_dstPath = fullfile(folder_TIRadar, sprintf('%.3f.pcd', TIRadar_timestamp));
if ~exist(TIRadar_pcd_dstPath, 'file') || OVERWRITE_ON == 1
    copyfile(TIRadar_pcd_srcPath, TIRadar_pcd_dstPath);
else
    fprintf('%s has been already exist.\n', TIRadar_pcd_dstPath);
end
TIRadar_json_dstPath = fullfile(folder_TIRadar, sprintf('%.3f.json', TIRadar_timestamp));
if ~exist(TIRadar_json_dstPath, 'file') || OVERWRITE_ON == 1
    TIRadar_json = struct();
    TIRadar_json.timestamp = sprintf('%.3f', TIRadar_timestamp);
    TIRadar_json.pcd_filename = sprintf('%.3f.pcd', TIRadar_timestamp);
    TIRadar_json.pcd_attributes = struct('x', 'float32', 'y', 'float32', 'z', 'float32', 'velocity', 'float32', 'SNR', 'float32');
    TIRadar_json.TIRadar_to_LeopardCamera1_TransformMatrix = TIRadar_to_LeopardCamera1_TransformMatrix;
    TIRadar_json.annotation = struct();
    savejson('', TIRadar_json, 'FileName', TIRadar_json_dstPath);
else
    fprintf('%s has been already exist.\n', TIRadar_json_dstPath);
end
% TIRadar_bin_path = ''; %12T16R adc data

%%
% MEMS_timestamp = '';
% MEMS_json_path = '';





%%
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