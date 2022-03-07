clear all;close all;clc;

load('./lidarLabeling_1635145524.825.mat');

root_path = './';
groupId = 0;
frameId = 0;
iscomplete = true;
folder_root = fullfile(root_path, sprintf('group%04d_frame%04d',groupId,frameId));
if ~exist(folder_root, 'dir')        
    fprintf('%s does not exist.\n', folder_root);
    iscomplete = false;
end
folder_VelodyneLidar = fullfile(folder_root, 'VelodyneLidar');
if ~exist(folder_VelodyneLidar, 'dir')
    fprintf('%s does not exist.\n', folder_VelodyneLidar);
    iscomplete = false;
else
    temp = dir(fullfile(folder_VelodyneLidar, '*.json'));
    if isempty(temp)
        fprintf('.json does not exist in %s.\n', folder_VelodyneLidar);
        iscomplete = false;
    else
        VelodyneLidar_json_path = fullfile(folder_VelodyneLidar, temp.name);
    end        
end

if iscomplete
    VelodyneLidar_json = loadjson(VelodyneLidar_json_path);
    annotation = struct();
    objectNames = gTruth.LabelData.Properties.VariableNames;
    for i = 1 : length(objectNames)
        objectName = objectNames{i};
        annotation(i).objectID = objectName;
        if contains(objectName, 'car')
            annotation(i).class = 0;
        elseif contains(objectName, 'pedestrian')
            annotation(i).class = 1;
        elseif contains(objectName, 'cyclist')
            annotation(i).class = 2;
        else
            annotation(i).class = -1;
        end

        eval(sprintf('objectInfo = gTruth.LabelData.%s;', objectName));        
        [annotation(i).xc, annotation(i).yc, annotation(i).zc, annotation(i).l, annotation(i).w, annotation(i).h, annotation(i).theta] = compute_annotation(objectInfo);

    end
    VelodyneLidar_json.annotation = annotation;
    savejson('', VelodyneLidar_json, 'FileName', VelodyneLidar_json_path);
end

%%
function [xc, yc, zc, l, w, h, theta] = compute_annotation(objectInfo)
    xc = objectInfo(1);
    yc = objectInfo(2);
    zc = objectInfo(3);
    w = objectInfo(4);
    l = objectInfo(5);
    h = objectInfo(6);
    theta = objectInfo(9)-270;
end