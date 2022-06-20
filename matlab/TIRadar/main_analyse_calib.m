clear all; close all; clc;

% ====================user's modify start=====================
match_id = 26;
image_path = sprintf('./runs/match%d.bmp', match_id);
timestamp_image = uint64(0);
radar_path = sprintf('/mnt/DATASET/20211027_calib/TIRadar_LeopardCamera1_calibration2/TIRadar/calib%d', match_id);
output_path = './runs';

calibFileName = './input/256x64.mat';
pathGenParaFolder = 'input';
radarTimeFile = dir(fullfile(radar_path, '*.startTime.txt'));
radarInfoFile = dir(fullfile(radar_path, '*.mmwave.json'));
radarBinFile_list = dir(fullfile(radar_path, '*.bin'));

PARAM_FILE_GEN_ON = 0;
rangeFFTFilter_ON = 0;
dopplerFFTFilter_ON = 0;
WAITKEY_ON = 1;
CHECK_LOG_ON = 0;
PLOT_ON = 1;
SAVE_ON = 1;

% TIRadar_to_LeopardCamera1 20211027
radar_camera_matchMatrix = [
    2019.61363529422, 1745.88166828988, -111.433796801951, -419.938881768377;
    26.0193673714885, 870.796981112031, -2038.30078479358, -120.997110351106;
    0.0244308479903333, 0.997614077965117, -0.0645700016438225, -0.00641535834610336
];
% ====================user's modify end=====================

%% create mmwave.json parameters file
if PARAM_FILE_GEN_ON == 1
    parameter_files_path = parameter_file_gen_json(fullfile(radarInfoFile.folder, radarInfoFile.name), calibFileName, pathGenParaFolder);
else
    parameter_files_path = struct();
    parameter_files_path(1).path = fullfile(pathGenParaFolder, 'subFrame0_param.m');
    parameter_files_path(2).path = fullfile(pathGenParaFolder, 'subFrame1_param.m');
end

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
            fprintf('正在检查第 %s 片中第 %d/%d 帧（全局的第 %d/%d 帧）\n',  sliceIdBasedPath(sliceId).sliceId, frameId+1, num_validFrames, cnt_globalFrames, totNumFrames);
        end
        
        for i_subFrame = 0 : NumSubFramesPerFrame -1
            cnt_globalSubFrames = cnt_globalSubFrames + 1;
            subFrameId = i_subFrame + frameId * NumSubFramesPerFrame;
            if CHECK_LOG_ON
                fprintf('正在检查第 %d/%d 子帧（全局的第 %d/%d 子帧）信息\n',  subFrameId+1, num_validSubFrames, cnt_globalSubFrames, totNumSubFrames);
            end
            
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
if (subFrame_timeDiff - getPara(parameter_files_path(1).path, 'SubFramePeriod') * 1000) > timeDiff_permitError
    dropSubframe = true;
    disp('===========================================================');
    fprintf('## WARNING: 头部丢帧导致子帧参数不匹配\n');
else
    dropSubframe = false;
end


%% get pcStartTime & radarStartTime and calculate difference between pcStartTime and radarStartTime
pcStartTime = getPCStartTime(radarTimeFile);
radarStartTime = getRadarStartTime(fullfile(radar_path, 'master_0000_idx.bin'));
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
    % camera时间戳
    fprintf('相机时间戳%.6f s\n', double(timestamp_image)/1e6);
    % radar时间戳
    fprintf('雷达时间戳%.6f s\n', double(timestamp_radar)/1e6);
    fprintf('时间戳相差%.3f ms\n', abs(double(timestamp_image) - double(timestamp_radar))/1e3);
%     if PLOT_ON
%         figure(2);
%         imshow(image_path);
%     end
    
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

%         data_path = fullfile(output_path, strcat(sprintf('%.3f', round(double(timestamp_radar)/1e6, 3)), ".adcdata.bin"));
        temp = split(image_path, '/');
        temp = temp{end};
        temp = split(temp, '.');
        temp = temp{1};
        data_path = fullfile(output_path, strcat(temp, ".adcdata.bin"));
        adcdata_save(data_path, data); 
    end

    % calibrate raw data
    adcDatas = calibAdcData(adcDatas, calibFileName, parameter_files_path);
    
    % 用以存储中间过程信息
    subFrame_results = struct();
    % 逐子帧处理
    for i_subFrame = 0 : NumSubFramesPerFrame - 1
        fprintf('>>正在处理第 %d 子帧       ',  i_subFrame);
        adcData = adcDatas(i_subFrame + 1).adcData;
        % reorder 
        RxForMIMOProcess = getPara(parameter_files_path(i_subFrame + 1).path, 'RxForMIMOProcess');
        adcData = adcData(:,:,RxForMIMOProcess,:);

        % rangeFFT
        tic;
        rangeFFTOut = rangeFFT(adcData, parameter_files_path(i_subFrame + 1).path, rangeFFTFilter_ON);
        fprintf('rangeFFT耗时%.3f s       ', toc);

        % dopplerFFT
        tic;
        dopplerFFTOut = dopplerFFT(rangeFFTOut, parameter_files_path(i_subFrame + 1).path, dopplerFFTFilter_ON);
        fprintf('dopplerFFT耗时%.3f s       ', toc);

        % 转化为虚拟天线形式，维度（每个Chirp中的采样点数，每根天线发射的chirp数量，虚拟天线数量 ）
        dopplerFFTOut = reshape(dopplerFFTOut,size(dopplerFFTOut,1), size(dopplerFFTOut,2), size(dopplerFFTOut,3)*size(dopplerFFTOut,4));
        % 聚合虚拟天线维度
        sig_integrate = 10*log10(sum((abs(dopplerFFTOut)).^2,3) + 1);
        subFrame_results(i_subFrame + 1).dopplerMap = sig_integrate;
        

        % CFAR
        tic;
        detection_results = CFAR(dopplerFFTOut, parameter_files_path(i_subFrame + 1).path);
        fprintf('CFAR耗时%.3f s       ', toc);
        detect_all_points = zeros(length(detection_results), 3);%初始化CFAR到的点的信息矩阵
        for iobj = 1 : length(detection_results)
            detect_all_points (iobj,1)=detection_results(iobj).rangeInd+1;%range index
            detect_all_points (iobj,2)=detection_results(iobj).dopplerInd_org+1;%doppler index
            detect_all_points (iobj,3)=detection_results(iobj).estSNR;%estimated SNR
        end
        subFrame_results(i_subFrame + 1).CFARResults = detection_results;
        
        
        % DOA
        if ~isempty(detection_results)
            tic;
            angleEst = DOA(detection_results, parameter_files_path(i_subFrame + 1).path);
            fprintf('DOA耗时%.3f s\n', toc);
            
            if ~isempty(angleEst)%如果检测到角度结果
                angles_all_points = zeros(length(angleEst), 6);%初始化DOA到的点的信息矩阵
                xyz = zeros(length(angleEst), 9);%初始化DOA到的点转换至直角坐标系下的信息矩阵
                for iobj = 1:length(angleEst)%对第iobj个检测结果
                    % angleEst.angles有4个值，取前两个：第一个为方位角azimuth，第二个为高程角elvation
                    angles_all_points (iobj,1)=angleEst(iobj).angles(1);%方位角azimuth                    
                    % 原先z值与现实坐标反了，原因是这里的elevation正负号出错了，因此于20210531修正
                    angles_all_points (iobj,2)=-angleEst(iobj).angles(2);%高程角elvation                    
                    angles_all_points (iobj,3)=angleEst(iobj).estSNR;%预测信噪比
                    angles_all_points (iobj,4)=angleEst(iobj).rangeInd;%取range的Index
                    angles_all_points (iobj,5)=angleEst(iobj).doppler_corr;%取doppler_corr
                    angles_all_points (iobj,6)=angleEst(iobj).range;%取range

                    xyz(iobj,1) = angles_all_points (iobj,6)*sind(angles_all_points (iobj,1))*cosd(angles_all_points (iobj,2));%x
                    xyz(iobj,2) = angles_all_points (iobj,6)*cosd(angles_all_points (iobj,1))*cosd(angles_all_points (iobj,2));%y
                    xyz(iobj,3) = angles_all_points (iobj,6)*sind(angles_all_points (iobj,2));%z
                    xyz(iobj,4) = angleEst(iobj).doppler_corr;%v
                    xyz(iobj,5) = angleEst(iobj).range;%range
                    xyz(iobj,6) = angleEst(iobj).estSNR;%取估计信噪比
                    xyz(iobj,7) = angleEst(iobj).doppler_corr_overlap;%取doppler_corr_overlap
                    xyz(iobj,8) = angleEst(iobj).doppler_corr_FFT;%取doppler_corr_FFT
                    xyz(iobj,9) = angleEst(iobj).dopplerInd_org;%取dopplerInd_org
                end
            end
        end
        subFrame_results(i_subFrame + 1).DOAResults = angleEst;
        subFrame_results(i_subFrame + 1).xyz = xyz;
        
        
        
        if PLOT_ON
            row_totFigure = 4;
            cnt_rowFigure = 0;
            
            figure(1);
            if i_subFrame == 0
                clf;
            end
%             set(gcf,'units','normalized','outerposition',[0.1 0.2 0.8 0.8]);
            % 调整位置
            position_left = [0, 0.3, 0.65, 0.65, 0, 0.3, 0.65, 0.65];
            position_bottom = [0.5, 0.5, 0.5, 0.75, 0, 0, 0, 0.25];
            position_width = [0.27, 0.27, 0.281, 0.281, 0.27, 0.27, 0.281, 0.281];
            position_height = [0.48, 0.48, 0.25, 0.25, 0.48, 0.48, 0.25, 0.25];
            
            rangeBin_list = ( 1 : getPara(parameter_files_path(i_subFrame + 1).path, 'rangeFFTSize') ) * getPara(parameter_files_path(i_subFrame + 1).path, 'rangeBinSize');
            velocityBin_list = ( -1*getPara(parameter_files_path(i_subFrame + 1).path, 'DopplerFFTSize')/2 : getPara(parameter_files_path(i_subFrame + 1).path, 'DopplerFFTSize')/2-1 ) * getPara(parameter_files_path(i_subFrame + 1).path, 'velocityBinSize');
            subFrame_results(i_subFrame + 1).rangeBin_list = rangeBin_list;
            subFrame_results(i_subFrame + 1).velocityBin_list = velocityBin_list;
            
            
            % 意义：Doppler Map曲线图
            % 横坐标——距离，纵坐标——强度，不同颜色的曲线表示不同速度，粗荧光绿线表示速度为0，黑点表示CFAR检测结果
            cnt_rowFigure = cnt_rowFigure + 1;
            figId = i_subFrame*row_totFigure+cnt_rowFigure;
            ax = axes('OuterPosition', [position_left(figId), position_bottom(figId), position_width(figId), position_height(figId)], 'Box', 'on');
            plot(ax, rangeBin_list, sig_integrate(:, size(sig_integrate,2)/2+1), 'g', 'LineWidth', 4);
            hold on;
            for vId=1 : size(sig_integrate, 2)
                powerList_vvId = sig_integrate(:,vId);
                plot(rangeBin_list, powerList_vvId);
                % 绘制CFAR检测结果
                if ~isempty(detection_results)%如果通过CFAR算法检测到了目标
                    ind = find(detect_all_points(:,2)==vId);%找到当前Doppler检测速度对应的检测点
                    if (~isempty(ind))%如果有监测点
                        rangeInd = detect_all_points(ind,1);%取检测到的点的range index
                        plot(ax, rangeBin_list(rangeInd), sig_integrate(rangeInd, vId),...
                            'o',...
                            'LineWidth', 2,...
                            'MarkerEdgeColor', 'k',...
                            'MarkerFaceColor', [.49 1 .63],...
                            'MarkerSize', 6);
                    end
                end
            end
            grid on;
            xlabel('Range(m)');
            ylabel('Receive Power (dB)');
            title(' DopplerMap I');
            hold off;
            set(ax, 'xLim', [0, rangeBin_list(end)]);
            
            % 意义：Doppler Map
            % 横坐标——速度，纵坐标——距离
            cnt_rowFigure = cnt_rowFigure + 1;
            figId = i_subFrame*row_totFigure+cnt_rowFigure;
            ax = axes('OuterPosition', [position_left(figId), position_bottom(figId), position_width(figId), position_height(figId)], 'Box', 'on');
            imagesc(ax, velocityBin_list, rangeBin_list, sig_integrate);
            c = colorbar;
            c.Label.String = 'Relative Power(dB)';
            xlabel('Velocity(m/s)   -: close to, +: away');
            ylabel('Range(m)');
            title(' DopplerMap II');            
            
            % 意义：点云图
            cnt_rowFigure = cnt_rowFigure + 1;
            figId = i_subFrame*row_totFigure+cnt_rowFigure;
            ax = axes('OuterPosition', [position_left(figId), position_bottom(figId), position_width(figId), position_height(figId)], 'Box', 'on');
            scatter3(ax, xyz(:, 1), xyz(:, 2), xyz(:, 3), 10, (xyz(:, 4)),'filled');%x,y,z,v
            c = colorbar;
            c.Label.String = 'velocity (m/s)'; 
            set(ax, 'CLim', [velocityBin_list(1), velocityBin_list(end)]);
            grid on;
            xlabel('X (m)');
            ylabel('Y (m)');
            zlabel('Z (m)');
            colormap('jet');                              
            title(sprintf('雷达时间戳%.6f s', double(subFramesInfo(i_globalSubFrame + i_subFrame + 1).master_timestamp + timestamp_diff)/1e6));
            hold on;
            xyz_zero = xyz(xyz(:,4)==0, :);
            scatter3(ax, xyz_zero(:,1), xyz_zero(:,2), xyz_zero(:,3), 10, (xyz_zero(:,4)),'w', 'filled');
            hold off;
            axis(ax, 'equal');
            set(ax, 'Color', [0.8,0.8,0.8]);
            set(ax, 'xLim', [-rangeBin_list(end), rangeBin_list(end)]);
            set(ax, 'yLim', [0, rangeBin_list(end)]);
            view([0, 90]);
%             view([-9, 22]);     
            
            % 意义：图像+点云投影
            cnt_rowFigure = cnt_rowFigure + 1;
            figId = i_subFrame*row_totFigure+cnt_rowFigure;
            ax = axes('OuterPosition', [position_left(figId), position_bottom(figId), position_width(figId), position_height(figId)], 'Box', 'on');
            remove_distance_min = 5;
            remove_distance_max = 75;
            pixel_coordinate = projection(xyz, radar_camera_matchMatrix, remove_distance_min, remove_distance_max);
            imshow(image_path);
            title(sprintf('相机时间戳%.6f s', double(timestamp_image)/1e6));
            hold on;
            scatter(ax, pixel_coordinate(1,:), pixel_coordinate(2,:), 10, pixel_coordinate(3,:), 'filled');
            set(gca, 'CLim', [velocityBin_list(1), velocityBin_list(end)]);
            pixel_coordinate_zero = pixel_coordinate(:,pixel_coordinate(3,:)==0);
            scatter(ax, pixel_coordinate_zero(1,:), pixel_coordinate_zero(2,:), 10, pixel_coordinate_zero(3,:), 'w', 'filled');
            hold off;            
        end

        
    end
    pause(0.1);   
    
    
    
    %% 处理下一帧，跳过NumSubFramesPerFrame个子帧
    i_globalSubFrame = i_globalSubFrame +NumSubFramesPerFrame;
    
    if WAITKEY_ON
        key = waitforbuttonpress;
            while(key==0)
                key = waitforbuttonpress;
            end        
    end
end


function adcdata_save(adcdata_path, adcdata)
    fileID = fopen(adcdata_path,'w');
    fwrite(fileID, adcdata,'int16');
    fclose(fileID);
end
