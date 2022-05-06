clear; close all; clc;

% ====================user's modify start=====================
exp = '20211025_1';
outputFolder = fullfile("/home/aify/Desktop/ourDataset/preprocess", exp, 'TIRadar_adc');
if ~exist(outputFolder, "dir")
    fprintf("Create outputfolder: %s\n", outputFolder);
    mkdir(outputFolder);
end
datasetFolder = "/mnt/DATASET";
dayFolders = dir(datasetFolder);

dayFolder = fullfile("/mnt/DATASET", exp);
dayFolder_TIRadar = fullfile(dayFolder, 'TIRadar');
groupFolders = dir(dayFolder_TIRadar);

calibFileName = "./input/256x64.mat";
pathGenParaFolder = 'input';
PARAM_FILE_GEN_ON = 0;
SAVE_ON = 1;
CHECK_LOG_ON = 0;
% ====================user's modify end=====================


%% create mmwave.json parameters file
if PARAM_FILE_GEN_ON == 1
    radarFolder = fullfile(dayFolder_TIRadar, groupFolders(3).name);
    radarInfoFile = dir(fullfile(radarFolder, "*.mmwave.json"));
    parameter_files_path = parameter_file_gen_json(fullfile(radarInfoFile.folder, radarInfoFile.name), calibFileName, pathGenParaFolder);   
end

%% process group
for groupFolderIndex = 3:length(groupFolders)    

    % check the number of files in group
    radarFolder = fullfile(dayFolder_TIRadar, groupFolders(groupFolderIndex).name);
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
    
    while (i_globalSubFrame+1 < cnt_globalSubFrames)        

        cnt_frame_processed = cnt_frame_processed + 1;
        
        % 当前帧时间戳
        timestamp_radar = subFramesInfo(i_globalSubFrame+1).master_timestamp + timestamp_diff;
        fprintf('雷达时间戳%.6f s\n', double(timestamp_radar)/1e6);

        if SAVE_ON
            data_path = fullfile(outputFolder, strcat(sprintf('%.3f', round(double(timestamp_radar)/1e6, 3)), ".adcdata.bin"));
            if exist(data_path, "file")
                %% 处理下一帧，跳过NumSubFramesPerFrame个子帧
                i_globalSubFrame = i_globalSubFrame +NumSubFramesPerFrame;
                continue;
            end
        end
            
        % 读取adc数据
        % read raw data
        adcDatas = readAdcData(subFramesInfo, i_globalSubFrame, parameter_files_path);
        if SAVE_ON
            % samplePerChirp, loopPerFrame, numRX, chirpPerLoop, real/imag, subFrameId 
            data = zeros(size(adcDatas(1).rawAdcData, 1), size(adcDatas(1).rawAdcData, 2),...
                size(adcDatas(1).rawAdcData, 3), size(adcDatas(1).rawAdcData, 4), 2, 2, 'int16');
            for i_subFrame = 0 : NumSubFramesPerFrame - 1
                data(:,:,:,:,1,i_subFrame+1) = real(adcDatas(i_subFrame + 1).rawAdcData);
                data(:,:,:,:,2,i_subFrame+1) = imag(adcDatas(i_subFrame + 1).rawAdcData);
            end

            data_path = fullfile(outputFolder, strcat(sprintf('%.3f', round(double(timestamp_radar)/1e6, 3)), ".adcdata.bin"));
            adcdata_save(data_path, data);            
        end   

%         % calibrate raw data
%         adcDatas = calibAdcData(adcDatas, calibFileName, parameter_files_path);
%         if SAVE_ON
%             samplePerChirp, loopPerFrame, numRX, chirpPerLoop, real/imag, subFrameId 
%             data = zeros(size(adcDatas(1).adcData, 1), size(adcDatas(1).adcData, 2),...
%                 size(adcDatas(1).adcData, 3), size(adcDatas(1).adcData, 4), 2, 2, 'int16');
%             for i_subFrame = 0 : NumSubFramesPerFrame - 1
%                 data(:,:,:,:,1,i_subFrame+1) = real(adcDatas(i_subFrame + 1).adcData);
%                 data(:,:,:,:,2,i_subFrame+1) = imag(adcDatas(i_subFrame + 1).adcData);
%             end
% 
%             data_path = fullfile(outputFolder, strcat(sprintf('%.3f', round(double(timestamp_radar)/1e6, 3)), ".adcdata.bin"));
%             adcdata_save(data_path, data);            
%         end   
        
        %% 处理下一帧，跳过NumSubFramesPerFrame个子帧
        i_globalSubFrame = i_globalSubFrame +NumSubFramesPerFrame;
        
    end

end

function adcdata_save(adcdata_path, adcdata)
    fileID = fopen(adcdata_path,'w');
    fwrite(fileID, adcdata,'int16');
    fclose(fileID);
end