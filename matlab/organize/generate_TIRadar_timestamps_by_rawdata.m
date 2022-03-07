clear all; close all; clc;

output_folder = './TIRadar_timestamps';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    fprintf('%s is created.\n', output_folder);
end
dataset_origin_path = '/mnt/DATASET';
dataset_process_path = '/media/ourDataset/preprocess';
OVERWRITE_ON = 0;


% dataset_group = '20211025_1';
% process_single(output_folder, dataset_origin_path, dataset_group, OVERWRITE_ON);

process(output_folder, dataset_origin_path, dataset_process_path, OVERWRITE_ON);


%%
function process(output_folder, dataset_origin_path, dataset_process_path, OVERWRITE_ON)
    temp = dir(dataset_process_path);
    for i = 3:length(temp)
        dataset_group = temp(i).name;
        process_single(output_folder, dataset_origin_path, dataset_group, OVERWRITE_ON);
    end
end

function process_single(output_folder, dataset_origin_path, dataset_group, OVERWRITE_ON)
    disp('===========================================================');
    fprintf('%s\n', dataset_group);
    file_save_path = fullfile(output_folder, strcat(dataset_group, '.mat'));
    if ~exist(file_save_path, 'file') || OVERWRITE_ON
        dataset_group_origin_path = fullfile(dataset_origin_path, dataset_group);
        [TIRadar_timestamps, TIRadar_infos] = get_TIRadar_timestamps(dataset_group_origin_path);
        if ~isempty(TIRadar_timestamps)
            save(file_save_path, 'TIRadar_timestamps');
        end
    else
        fprintf('%s has already been generated.\n', file_save_path);
    end
    fprintf('Done.\n');
end

function [TIRadar_timestamps, TIRadar_infos] = get_TIRadar_timestamps(dataset_group_origin_path)
    TIRadar_timestamps = [];
    TIRadar_infos = struct;

    TIRadar_path = fullfile(dataset_group_origin_path, 'TIRadar');
    items = dir(TIRadar_path);
    if length(items) < 3
        return;
    end
    valid_groups = struct();
    k = 0;    
    for i = 3:length(items)        
        folder_name = items(i).name;
        folder_path = fullfile(TIRadar_path, folder_name);
        iscomplete = check_TIRadar_folder(folder_path);
        if iscomplete
            k = k + 1;
            temp = split(folder_name, '_');
            index = str2num(temp{end});
            valid_groups(k).index = index;
            valid_groups(k).path = folder_path;
            valid_groups(k).name = folder_name;
        end
    end
        
    k = 0;
    [~, temp] = sort([valid_groups.index]);
    for i = temp
        k = k + 1;
        TIRadar_infos(k).name = valid_groups(i).name;        
        TIRadar_infos(k).path = valid_groups(i).path;
        fprintf('Processing %s\n', TIRadar_infos(k).path);
        TIRadar_infos(k).timestamps = get_timestamps(valid_groups(i).path);
        TIRadar_timestamps = [TIRadar_timestamps;TIRadar_infos(k).timestamps];
    end
end

function timestamps = get_timestamps(radarFolder)
    radarTimeFile = dir(fullfile(radarFolder, '*.startTime.txt'));
    radarBinFile_list = dir(fullfile(radarFolder, '*.bin'));

    % get sliceId based path
    sliceIdBasedPath = getSliceIdBasedPath(radarBinFile_list);
    
    % initialization
    subFramesInfo = struct();
    cnt_globalSubFrames = 0;
    cnt_globalFrames = 0;

    % get parameter from
    NumSubFramesPerFrame = 2;
    for sliceId = 1:length(sliceIdBasedPath)
        num_validSubFrames = getValidFrames(sliceIdBasedPath, sliceId);
        num_validFrames = num_validSubFrames / NumSubFramesPerFrame;
        for frameId = 0: num_validFrames-1  
            cnt_globalFrames = cnt_globalFrames +1;            
            for i_subFrame = 0 : NumSubFramesPerFrame -1
                cnt_globalSubFrames = cnt_globalSubFrames + 1;
                subFrameId = i_subFrame + frameId * NumSubFramesPerFrame;                
                % record frame information
                subFramesInfo(cnt_globalSubFrames).globalSubFrameId = cnt_globalSubFrames-1;
                curSubFrameInfo = getFrameInfo(sliceIdBasedPath, sliceId, subFrameId);
                fieldnames_cell = fieldnames(curSubFrameInfo);
                for i_field = 1: length(fieldnames_cell)
                    fieldname = fieldnames_cell{i_field};
                    eval(['subFramesInfo(cnt_globalSubFrames).', fieldname, ' = curSubFrameInfo.', fieldname, ';']);            
                end
            end            
        end        
    end

    % check if drop some subframes?
    subFrame_timeDiff = subFramesInfo(2).master_timestamp - subFramesInfo(1).master_timestamp;
    timeDiff_permitError = 1000;% us
    if (subFrame_timeDiff - 15 * 1000) > timeDiff_permitError
        dropSubframe = true;
%         disp('===========================================================');
%         fprintf('## WARNING: 头部丢帧导致子帧参数不匹配\n');
    else
        dropSubframe = false;
    end

    % get pcStartTime & radarStartTime and calculate difference between pcStartTime and radarStartTime
    pcStartTime = getPCStartTime(radarTimeFile);
    radarStartTime = getRadarStartTime(fullfile(radarFolder, 'master_0000_idx.bin'));
    if dropSubframe
        radarStartTime = radarStartTime - 15000;
    end
    timestamp_diff = pcStartTime - radarStartTime;

    % radar process
    if dropSubframe
        i_globalSubFrame = 1;
    else
        i_globalSubFrame = 0;
    end

    timestamps = [];
    while (i_globalSubFrame+1 < cnt_globalSubFrames)       
        % 当前帧时间戳
        timestamp_radar = subFramesInfo(i_globalSubFrame+1).master_timestamp + timestamp_diff;
        timestamp_radar = round(double(timestamp_radar)/1e6, 3);
        timestamps = [timestamps; timestamp_radar];
        % 处理下一帧，跳过NumSubFramesPerFrame个子帧
        i_globalSubFrame = i_globalSubFrame +NumSubFramesPerFrame;        
    end
    
end

function iscomplete = check_TIRadar_folder(folder_path)
    temp = dir(fullfile(folder_path, '*.bin'));
    if length(temp) == 32
        iscomplete = true;
    else
        iscomplete = false;
    end
end

%% from radar speedExtend
function [sliceIdBasedPath] = getSliceIdBasedPath(radarBinFile_list)    
    if mod(length(radarBinFile_list), 8) ~= 0
        disp('####Error：.bin文件数量不是8的整数倍');
    end
    num_slices = ceil(length(radarBinFile_list)/8);
    sliceIdBasedPath = struct();
    for i =1: num_slices
        sliceIdBasedPath(i).sliceId = sprintf('%04d', i-1);
    end    
    for i = 1:length(radarBinFile_list)
        path = fullfile(radarBinFile_list(i).folder, radarBinFile_list(i).name);
        nameSplitResults = strsplit(radarBinFile_list(i).name, '_');
        device = nameSplitResults{1};
        sliceId = nameSplitResults{2};
        type = nameSplitResults{3};
        type = strsplit(type, '.');
        type = type{1};        
        eval(['sliceIdBasedPath(str2num(sliceId)+1).', device, '_', type, ' = ', 'path;']);        
    end
end

function num_validFrames = getValidFrames(sliceIdBasedPath, sliceId)
    masterIdx_path = sliceIdBasedPath(sliceId).master_idx;
    f = fopen(masterIdx_path, 'r');
    fseek(f, 12, 'bof');
    num_validFrames = uint32(fread(f, 1,'uint32'));
    fclose(f);
end

function curFrameInfo = getFrameInfo(sliceIdBasedPath, sliceId, frameId)
    curFrameInfo = struct();
    curFrameInfo.sliceFrameId = frameId;

    masterData_path = sliceIdBasedPath(sliceId).master_data;
    curFrameInfo.master_adcDataPath = masterData_path;
    masterIdx_path = sliceIdBasedPath(sliceId).master_idx;
    [~, ~,  ~, ~, ~, ~, curFrameInfo.master_timestamp, curFrameInfo.master_offset] = getFrameInfoFromIdx(masterIdx_path, frameId);
    
    slave1Data_path = sliceIdBasedPath(sliceId).slave1_data;
    curFrameInfo.slave1_adcDataPath = slave1Data_path;
    slave1Idx_path = sliceIdBasedPath(sliceId).slave1_idx;
    [~, ~,  ~, ~, ~, ~, curFrameInfo.slave1_timestamp, curFrameInfo.slave1_offset] = getFrameInfoFromIdx(slave1Idx_path, frameId);
    
    slave2Data_path = sliceIdBasedPath(sliceId).slave2_data;
    curFrameInfo.slave2_adcDataPath = slave2Data_path;
    slave2Idx_path = sliceIdBasedPath(sliceId).slave2_idx;
    [~, ~,  ~, ~, ~, ~, curFrameInfo.slave2_timestamp, curFrameInfo.slave2_offset] = getFrameInfoFromIdx(slave2Idx_path, frameId);
    
    slave3Data_path = sliceIdBasedPath(sliceId).slave3_data;
    curFrameInfo.slave3_adcDataPath = slave3Data_path;
    slave3Idx_path = sliceIdBasedPath(sliceId).slave3_idx;
    [~, ~,  ~, ~, ~, ~, curFrameInfo.slave3_timestamp, curFrameInfo.slave3_offset] = getFrameInfoFromIdx(slave3Idx_path, frameId);
    
    
end


function [tag, version,  flags, width, height, size, timestamp, offset] = getFrameInfoFromIdx(path, frameId)
    f = fopen(path, 'r');
    % File header in *_idx.bin:
    %     struct Info
    %     {
    %         uint32_t tag;
    %         uint32_t version;
    %         uint32_t flags;
    %         uint32_t numIdx;       // number of frames 
    %         uint64_t dataFileSize; // total data size written into file
    %     };
    % 
    % Index for every frame from each radar:
    %     struct BuffIdx
    %     {
    %         uint16_t tag;
    fseek(f, 24 + frameId * 48 + 0, 'bof');
    tag = uint16(fread(f, 1,'uint16'));
    %         uint16_t version; /*same as Info.version*/
    fseek(f, 24 + frameId * 48 + 2, 'bof');
    version = uint16(fread(f, 1,'uint16'));
    %         uint32_t flags;
    fseek(f, 24 + frameId * 48 + 4, 'bof');
    flags = uint32(fread(f, 1,'uint32'));
    %         uint16_t width;        
    fseek(f, 24 + frameId * 48 + 8, 'bof');
    width = uint16(fread(f, 1,'uint16'));
    %         uint16_t height;
    fseek(f, 24 + frameId * 48 + 10, 'bof');
    height = uint16(fread(f, 1,'uint16'));
    %         uint32_t pitchOrMetaSize[4]; /*For image data, this is pitch.
    %                                                        For raw data, this is size in bytes per metadata plane.*/
    %         uint32_t size; /*total size in bytes of the data in the buffer (sum of all planes)*/
    fseek(f, 24 + frameId * 48 + 28, 'bof');
    size = uint32(fread(f, 1,'uint32'));
    %         uint64_t timestamp;
    fseek(f, 24 + frameId * 48 + 32, 'bof');
    timestamp = uint64(fread(f, 1,'uint64'));
    %         uint64_t offset;
    fseek(f, 24 + frameId * 48 + 40, 'bof');
    offset = uint64(fread(f, 1,'uint64'));
    %     };
    fclose(f);
end

function radarStartTime = getPCStartTime(radarTimeFile)
    f = fopen(fullfile(radarTimeFile.folder, radarTimeFile.name), 'r');
    radarStartTime = fscanf(f, '%f');
    fclose(f);
    radarStartTime = uint64(radarStartTime*1000000);%16位UNIX时间
end

function radarStartTime = getRadarStartTime(path)
    f = fopen(path, 'r');
%     if skipOneSubframe_ON
%         subFrameId = 1;
%     else
%         subFrameId = 0;
%     end
    subFrameId = 0;
    %         uint64_t timestamp;
    fseek(f, 24 + subFrameId * 48 + 32, 'bof');
    radarStartTime = uint64(fread(f, 1,'uint64'));
    
    fclose(f);
end
