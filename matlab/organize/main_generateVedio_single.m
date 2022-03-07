clear all;close all; clc;

root_path = "/home/aify/Desktop/ourDataset/v1.0";
group = "20211027_2";
groupId = 0;

images_folder = fullfile(root_path, group, 'Pic/Projections');

imageNames = dir(fullfile(images_folder, '*.jpg'));
imageNames = {imageNames.name}';

output_vedio_path = fullfile(root_path, group, sprintf("group%04d.avi", groupId));
startIndex = inf;
endIndex = -inf;
for ii = 1:length(imageNames)
    imageName = imageNames{ii};
    if contains(imageName, sprintf("groupId%04d", groupId))
        startIndex = min(startIndex, ii);
        endIndex = max(endIndex, ii);
    end
end

outputVideo = VideoWriter(output_vedio_path);
outputVideo.FrameRate = 10;
open(outputVideo);
for ii = startIndex:endIndex
   img = imread(fullfile(images_folder,imageNames{ii}));
   img = imresize(img, [1080, 1920]);
   writeVideo(outputVideo,img);
   ii
end
close(outputVideo);



%%
clear all;close all; clc;

root_path = "/home/aify/Desktop/ourDataset/v1.0";
group = "20211028_2";
groupId = 0;

images_folder = fullfile(root_path, group, 'Pic/Sensors');

imageNames = dir(fullfile(images_folder, '*.jpg'));
imageNames = {imageNames.name}';


output_vedio_path = fullfile(root_path, group, sprintf("Sensors_group%04d.avi", groupId));
startIndex = inf;
endIndex = -inf;
for ii = 1:length(imageNames)
    imageName = imageNames{ii};
    if contains(imageName, sprintf("groupId%04d", groupId))
        startIndex = min(startIndex, ii);
        endIndex = max(endIndex, ii);
    end
end

outputVideo = VideoWriter(output_vedio_path);
outputVideo.FrameRate = 10;
open(outputVideo);
for ii = startIndex:endIndex
   img = imread(fullfile(images_folder,imageNames{ii}));
   img = imresize(img, [1080, 1920]);
   writeVideo(outputVideo,img);
   ii
end
close(outputVideo);