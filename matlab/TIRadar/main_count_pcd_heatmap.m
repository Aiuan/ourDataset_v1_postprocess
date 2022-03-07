clear; close all; clc;

% ====================user's modify start=====================
dayFolder = "/mnt/DATASET/20211031_3/TIRadar";
groupFolders = dir(dayFolder);

calibFileName = "./input/256x64.mat";
pathGenParaFolder = 'input';
PARAM_FILE_GEN_ON = 0;
CHECK_LOG_ON = 0;

counter = [];
% ====================user's modify end=====================


%% create mmwave.json parameters file
if PARAM_FILE_GEN_ON == 1
    radarFolder = fullfile(dayFolder, groupFolders(3).name);
    radarInfoFile = dir(fullfile(radarFolder, '*.mmwave.json'));
    parameter_files_path = parameter_file_gen_json(fullfile(radarInfoFile.folder, radarInfoFile.name), calibFileName, pathGenParaFolder);   
end


for groupFolderIndex = 3:length(groupFolders)

    radarFolder = fullfile(dayFolder, groupFolders(groupFolderIndex).name);
    if length(dir(radarFolder)) ~= 37
        fprintf('%s the number of files is not right.\n', radarFolder)
        continue;
    end

    radarTimeFile = dir(fullfile(radarFolder, '*.startTime.txt'));
    radarInfoFile = dir(fullfile(radarFolder, '*.mmwave.json'));
    radarBinFile_list = dir(fullfile(radarFolder, '*.bin'));

    parameter_files_path = struct();
    parameter_files_path(1).path = fullfile('input','subFrame0_param.m');
    parameter_files_path(2).path = fullfile('input','subFrame1_param.m');
    
    %% radar data check
    % get sliceId based path
    sliceIdBasedPath = getSliceIdBasedPath(radarBinFile_list);
    
    % initialization
    subFramesInfo = struct();
    cnt_globalSubFrames = 0;
    cnt_globalFrames = 0;
    
    % get parameter from 
    totNumFrames = getPara(parameter_files_path(1).path, 'frameCount');
    NumSubFramesPerFrame = getPara(parameter_files_path(1).path, 'NumSubFrames');
    totNumSubFrames = totNumFrames * NumSubFramesPerFrame;
    
    for sliceId = 1:length(sliceIdBasedPath)
        num_validSubFrames = getValidFrames(sliceIdBasedPath, sliceId);
        num_validFrames = num_validSubFrames / NumSubFramesPerFrame;
        for frameId = 0: num_validFrames-1  
            cnt_globalFrames = cnt_globalFrames +1;
            if CHECK_LOG_ON
                disp('===========================================================');
                fprintf('正在检查第 %s 片中第 %d/%d 帧（全局的第 %d/%d 帧）\n',  sliceIdBasedPath(sliceId).sliceId, frameId, num_validFrames-1, cnt_globalFrames-1, totNumFrames);
            end
            
            for i_subFrame = 0 : NumSubFramesPerFrame -1
                cnt_globalSubFrames = cnt_globalSubFrames + 1;
                subFrameId = i_subFrame + frameId * NumSubFramesPerFrame;
                if CHECK_LOG_ON
                    fprintf('正在检查第 %d/%d 子帧（全局的第 %d/%d 子帧）信息\n',  subFrameId, num_validSubFrames-1, cnt_globalSubFrames-1, totNumSubFrames);
                end
                
                % record frame information
                subFramesInfo(cnt_globalSubFrames).globalSubFrameId = cnt_globalSubFrames-1;
                curSubFrameInfo = getFrameInfo(sliceIdBasedPath, sliceId, subFrameId);
                fieldnames_cell = fieldnames(curSubFrameInfo);
%                 for i_field = 1: length(fieldnames_cell)
%                     fieldname = fieldnames_cell{i_field};
%                     eval(['subFramesInfo(cnt_globalSubFrames).', fieldname, ' = curSubFrameInfo.', fieldname, ';\n']);            
%                 end
                subFramesInfo(cnt_globalSubFrames).sliceFrameId = curSubFrameInfo.sliceFrameId;
                subFramesInfo(cnt_globalSubFrames).master_adcDataPath = curSubFrameInfo.master_adcDataPath;
                subFramesInfo(cnt_globalSubFrames).master_timestamp = curSubFrameInfo.master_timestamp;
                subFramesInfo(cnt_globalSubFrames).master_offset = curSubFrameInfo.master_offset;
                subFramesInfo(cnt_globalSubFrames).slave1_adcDataPath = curSubFrameInfo.slave1_adcDataPath;
                subFramesInfo(cnt_globalSubFrames).slave1_timestamp = curSubFrameInfo.slave1_timestamp;
                subFramesInfo(cnt_globalSubFrames).slave1_offset = curSubFrameInfo.slave1_offset;
                subFramesInfo(cnt_globalSubFrames).slave2_adcDataPath = curSubFrameInfo.slave2_adcDataPath;
                subFramesInfo(cnt_globalSubFrames).slave2_timestamp = curSubFrameInfo.slave2_timestamp;
                subFramesInfo(cnt_globalSubFrames).slave2_offset = curSubFrameInfo.slave2_offset;
                subFramesInfo(cnt_globalSubFrames).slave3_adcDataPath = curSubFrameInfo.slave3_adcDataPath;
                subFramesInfo(cnt_globalSubFrames).slave3_timestamp = curSubFrameInfo.slave3_timestamp;
                subFramesInfo(cnt_globalSubFrames).slave3_offset = curSubFrameInfo.slave3_offset;


            end
            
        end
        
    end
    
    % check if drop some subframes?
    subFrame_timeDiff = subFramesInfo(2).master_timestamp - subFramesInfo(1).master_timestamp;
    timeDiff_permitError = 1000;% us
    if (subFrame_timeDiff - getPara(parameter_files_path(1).path, 'SubFramePeriod') * 1000) > timeDiff_permitError
        dropSubframe = true;
        fprintf('===========================================================\n(%s)## WARNING: 头部丢帧导致子帧参数不匹配\n', radarFolder);
    else
        dropSubframe = false;
    end
    
    
    %% get pcStartTime & radarStartTime and calculate difference between pcStartTime and radarStartTime
    pcStartTime = getPCStartTime(radarTimeFile);
    radarStartTime = getRadarStartTime(fullfile(radarFolder, 'master_0000_idx.bin'));
    if dropSubframe
        radarStartTime = radarStartTime - 15000;
    end
    timestamp_diff = pcStartTime - radarStartTime;
    
    %% radar process
    if dropSubframe
        i_globalSubFrame = 1;
    else
        i_globalSubFrame = 0;
    end
    
    cnt_frame_processed = 0;
    
    while (i_globalSubFrame < cnt_globalSubFrames)
        cnt_frame_processed = cnt_frame_processed + 1;
                
        %% 处理下一帧，跳过NumSubFramesPerFrame个子帧
        i_globalSubFrame = i_globalSubFrame +NumSubFramesPerFrame;
        
    end

    fprintf("%d\n", cnt_frame_processed);
    counter = [counter; cnt_frame_processed];
end

fprintf("The number of frames in %s:\n%d\n",dayFolder, sum(counter));


