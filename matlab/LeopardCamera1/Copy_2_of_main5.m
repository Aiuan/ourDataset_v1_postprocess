% input: processfolder(raw) - savefolder(png)
% raw2png
% refineColor
% undistort
% cutReshape

clear all; close all; clc;

input = {
    % [processfolder(raw), savefolder(png), refineColorMode]
%     ["/mnt/DATASET/20211025_1/LeopardCamera1", "/media/ourDataset/preprocess/20211025_1/LeopardCamera1", 7];
    ["/mnt/DATASET/20211025_2/LeopardCamera1", "/media/ourDataset/preprocess/20211025_2/LeopardCamera1", 7];
%     ["/mnt/DATASET/20211025_3/LeopardCamera1", "/media/ourDataset/preprocess/20211025_3/LeopardCamera1", 8];
%     ["/mnt/DATASET/20211026_1/LeopardCamera1", "/media/ourDataset/preprocess/20211026_1/LeopardCamera1", 8];
%     ["/mnt/DATASET/20211026_2/LeopardCamera1", "/media/ourDataset/preprocess/20211026_2/LeopardCamera1", 7];
%     ["/mnt/DATASET/20211027_1/LeopardCamera1", "/media/ourDataset/preprocess/20211027_1/LeopardCamera1", 9];
%     ["/mnt/DATASET/20211027_2/LeopardCamera1", "/media/ourDataset/preprocess/20211027_2/LeopardCamera1", 10];
%     ["/mnt/DATASET/20211028_1/LeopardCamera1", "/media/ourDataset/preprocess/20211028_1/LeopardCamera1", 11];
%     ["/mnt/DATASET/20211028_2/LeopardCamera1", "/media/ourDataset/preprocess/20211028_2/LeopardCamera1", 12];
%     ["/mnt/DATASET/20211029_1/LeopardCamera1", "/media/ourDataset/preprocess/20211029_1/LeopardCamera1", 13];
%     ["/mnt/DATASET/20211029_2/LeopardCamera1", "/media/ourDataset/preprocess/20211029_2/LeopardCamera1", 14];
%     ["/mnt/DATASET/20211030_1/LeopardCamera1", "/media/ourDataset/preprocess/20211030_1/LeopardCamera1", 15];
%     ["/mnt/DATASET/20211031_1/LeopardCamera1", "/media/ourDataset/preprocess/20211031_1/LeopardCamera1", 16];
%     ["/mnt/DATASET/20211031_2/LeopardCamera1", "/media/ourDataset/preprocess/20211031_2/LeopardCamera1", 16];
%     ["/mnt/DATASET/20211031_3/LeopardCamera1", "/media/ourDataset/preprocess/20211031_3/LeopardCamera1", 16];

};
intrinsics_path = "./LeopardCamera1_oringin.mat";

load(intrinsics_path);
for n = 1 : size(input, 1)
    tic;
    folder_input = input{n, 1}(1);
    folder_output = input{n, 1}(2); 
    refineColorMode = str2double(input{n, 1}(3)); 
    
    if ~exist(folder_output, "dir")
        fprintf("create outputfolder: %s\n", folder_output);
        mkdir(folder_output);
    end

    info_raws = dir(fullfile(folder_input, "*.raw"));
    parfor i = 1:length(info_raws)
        time1 = tic;
        
        rawFilename = info_raws(i).name;
        % check
        pngFilename = strcat(sprintf("%.3f",round(str2double(replace(rawFilename, ".raw", "")),3)), ".png");
        pngFilepath = fullfile(folder_output,pngFilename);
        if exist(pngFilepath, "file")
            fprintf("(%d/%d) %s has already been generated.\n", i, length(info_raws), pngFilepath);
            continue;
        end
        rawFilepath = fullfile(info_raws(i).folder, rawFilename);
        % raw2rgb
        image_rgb = raw2rgb2(rawFilepath, 1, 1, 1);

        % refineColor
        switch refineColorMode
            case 1
                image_rgb_refineColor = refineColor1(image_rgb);
            case 2
                image_rgb_refineColor = refineColor2(image_rgb);
            case 3
                image_rgb_refineColor = refineColor3(image_rgb);
            case 4
                image_rgb_refineColor = refineColor4(image_rgb);
            case 5
                image_rgb_refineColor = refineColor5(image_rgb);
            case 6
                image_rgb_refineColor = refineColor6(image_rgb);
            case 7
                image_rgb_refineColor = refineColor7(image_rgb);
            case 8                
                image_rgb_refineColor = refineColor8(image_rgb);
            case 9                
                image_rgb_refineColor = refineColor9(image_rgb);
            case 10                
                image_rgb_refineColor = refineColor10(image_rgb);
            case 11                
                image_rgb_refineColor = refineColor11(image_rgb);
            case 12                
                image_rgb_refineColor = refineColor12(image_rgb);
            case 13                
                image_rgb_refineColor = refineColor13(image_rgb);
            case 14               
                image_rgb_refineColor = refineColor14(image_rgb);
            case 15                
                image_rgb_refineColor = refineColor15(image_rgb);
            case 16                
                image_rgb_refineColor = refineColor16(image_rgb);
            case 17                
                image_rgb_refineColor = refineColor17(image_rgb);
        end      

        % undistort
        image_undistort = undistortImage(image_rgb_refineColor, cameraParams, "OutputView", "valid");
        % cutReshapes
        image_undistort_cut = image_undistort(1:1700, :, :);

        % save
        % ms timestamp name
%         pngFilename = strcat(sprintf("%.3f",round(str2double(replace(rawFilename, ".raw", "")),3)), ".png");
%         pngFilepath = fullfile(folder_output,pngFilename);
        imwrite(image_undistort_cut, pngFilepath);
        time2 = tic;
        fprintf(", (%d/%d) %s has been generated", i, length(info_raws), pngFilepath);
        fprintf(", processTime = %.6f s.\n", (double(time2)-double(time1))/1e6);
    end

    
    timeUsed = toc;
    fprintf("%s has been processed, results save in %s, timeUsed = %.3f s\n", folder_input, folder_output, timeUsed);
end




