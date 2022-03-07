clear all;close all; clc;

OVERWRITE_ON = 0;
root_path = "/home/aify/Desktop/ourDataset/v1.0";
dayExps = dir(root_path);
% dayExps_discard = '';

for i_dayExp = 3:length(dayExps)   
    
    dayExp = dayExps(i_dayExp).name;
    fprintf("================================\nProcessing %s\n", dayExp);

%     if dayExp == dayExps_discard
%         fprintf("%s is discarded.\n", dayExp);
%         continue;
%     end

    fig = figure("Visible","off", "Units","pixels", "Position",[0,0,3840,1080]);
    ax1 = axes(fig, "Units","pixels", "Position",[0,0,3840,1080]);

    
    [group_frame_info, groupInfo] = getGroupInfo(fullfile(root_path, dayExp, "Dataset"));

    projections_folder = fullfile(root_path, dayExp, 'Pic/Projections');
    sensers_folder = fullfile(root_path, dayExp, 'Pic/Sensors');

    vedio_path = fullfile(root_path, dayExp, "Vedio");
    if ~exist(vedio_path, "dir")
        mkdir(vedio_path);
        fprintf("Create %s\n", vedio_path);
    end    
    for i_group = 1:length(groupInfo)
        t_start = tic;
        groupId = groupInfo(i_group).groupId;
        frame_length = groupInfo(i_group).frame_length;
        frameIds = groupInfo(i_group).frameIds;
        frameIds_to_label = groupInfo(i_group).frameIds_to_label;

        output_vedio_path = fullfile(vedio_path, sprintf("%s_group%04d(%d_frames).avi", dayExp, groupId, frame_length));
        if exist(output_vedio_path, "file") && ~OVERWRITE_ON
            fprintf("%s has already been gennerated.\n", output_vedio_path);
            continue;
        end
        outputVideo = VideoWriter(output_vedio_path);
        outputVideo.FrameRate = 10;
        open(outputVideo);
        for i_frame = 1:length(frameIds)
            frameId = frameIds(i_frame);
            img_name = sprintf("groupId%04d_frameId%04d.jpg", groupId, frameId);
            
            img_projection = imread(fullfile(projections_folder, img_name));
            img_projection = imresize(img_projection, [1080, 1920]);
            img_sensor = imread(fullfile(sensers_folder, img_name));
            img_sensor = imresize(img_sensor, [1080, 1920]);
            img = [img_projection, img_sensor];

            cla(ax1);
            imshow(img);
            if ismember(frameId, frameIds_to_label)
                text(ax1, 30, 30,...
                    sprintf("%s__group(%d/%d)__frame(%d/%d) ##wait for labeling", dayExp, groupId, length(groupInfo), frameId, length(frameIds)),...
                    "Color", "red", "FontSize",20);
            else
                text(ax1, 30, 30,...
                    sprintf("%s__group(%d/%d)__frame(%d/%d)", dayExp, groupId, length(groupInfo), frameId, length(frameIds)),...
                    "Color", "black", "FontSize",20);
            end

            img = getframe(fig).cdata;

            writeVideo(outputVideo, img);

            fprintf("%s_group(%d/%d)_frame(%d/%d) has been processed.\n", dayExp, groupId, length(groupInfo), frameId, length(frameIds));
        end
        close(outputVideo);
        t_end = tic;
        fprintf("%s_group%04d(%d_frames).avi has been generated, timeUsed = %.2f s.\n", dayExp, groupId, length(frameIds), double(t_end-t_start)/1e6);
    end
    
    close(fig);
end


function [group_frame_info, groupInfo] = getGroupInfo(dataset_path)
    group_frame_info = struct();
    groupInfo = struct();

    temp = dir(dataset_path);
    k = 0;
    for i = 3:length(temp)
        k = k+1;
        group_frame_info(k).groupId_frameId = temp(i).name;
        group_frame_info(k).groupId = str2num(group_frame_info(k).groupId_frameId(6:9));
        group_frame_info(k).frameId = str2num(group_frame_info(k).groupId_frameId(16:end));
    end

    groupIds = unique([group_frame_info.groupId]);
    k = 0;
    for i = 1:length(groupIds)
        k = k+1;
        groupInfo(k).groupId = groupIds(i);
        temp = group_frame_info([group_frame_info.groupId]==groupInfo(k).groupId);
        groupInfo(k).frame_length = length(temp);
        groupInfo(k).frameIds = [temp.frameId];
        groupInfo(k).frameIds_to_label =  groupInfo(k).frameIds(1:5:end);
        groupInfo(k).label_frame_length = length(groupInfo(k).frameIds_to_label);
    end


    
end


