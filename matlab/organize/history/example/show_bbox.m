clear all; close all; clc;

root_path = './';
groupId = 0;
frameId = 0;

PROJECT_ON = false;

showFolders(root_path, groupId, frameId, PROJECT_ON);

%%
function showFolders(root_path, groupId, frameId, PROJECT_ON)
    iscomplete = checkFolders(root_path, groupId, frameId);
    if iscomplete       

        folder_root = fullfile(root_path, sprintf('group%04d_frame%04d',groupId,frameId));
        folder_LeopardCamera1 = fullfile(folder_root, 'LeopardCamera1');
        folder_VelodyneLidar = fullfile(folder_root, 'VelodyneLidar');
        folder_OCULiiRadar = fullfile(folder_root, 'OCULiiRadar');
        folder_TIRadar = fullfile(folder_root, 'TIRadar');
        folder_MEMS = fullfile(folder_root, 'MEMS');
        
        LeopardCamera1_json_path = fullfile(folder_LeopardCamera1, dir(fullfile(folder_LeopardCamera1, '*.json')).name);
        LeopardCamera1_json = loadjson(LeopardCamera1_json_path);
        LeopardCamera1_annotation = LeopardCamera1_json.annotation;
        LeopardCamera1_png_path = fullfile(folder_LeopardCamera1, LeopardCamera1_json.png_filename);
        LeopardCamera1_IntrinsicMatrix = LeopardCamera1_json.IntrinsicMatrix;

        VelodyneLidar_json_path = fullfile(folder_VelodyneLidar, dir(fullfile(folder_VelodyneLidar, '*.json')).name);
        VelodyneLidar_json = loadjson(VelodyneLidar_json_path);
        VelodyneLidar_annotation = VelodyneLidar_json.annotation;
        VelodyneLidar_pcd_path = fullfile(folder_VelodyneLidar, VelodyneLidar_json.pcd_filename); 
        VelodyneLidar_to_LeopardCamera1_TransformMatrix = VelodyneLidar_json.VelodyneLidar_to_LeopardCamera1_TransformMatrix;

        OCULiiRadar_json_path = fullfile(folder_OCULiiRadar, dir(fullfile(folder_OCULiiRadar, '*.json')).name);
        OCULiiRadar_json = loadjson(OCULiiRadar_json_path);
        OCULiiRadar_annotation = OCULiiRadar_json.annotation;
        OCULiiRadar_pcd_path = fullfile(folder_OCULiiRadar, OCULiiRadar_json.pcd_filename); 
        OCULiiRadar_to_LeopardCamera1_TransformMatrix = OCULiiRadar_json.OCULiiRadar_to_LeopardCamera1_TransformMatrix;

        TIRadar_json_path = fullfile(folder_TIRadar, dir(fullfile(folder_TIRadar, '*.json')).name);
        TIRadar_json = loadjson(TIRadar_json_path);
        TIRadar_annotation = TIRadar_json.annotation;
        TIRadar_pcd_path = fullfile(folder_TIRadar, TIRadar_json.pcd_filename);
        TIRadar_to_LeopardCamera1_TransformMatrix = TIRadar_json.TIRadar_to_LeopardCamera1_TransformMatrix;

        showScence_bbox(PROJECT_ON, LeopardCamera1_png_path, VelodyneLidar_pcd_path, OCULiiRadar_pcd_path, TIRadar_pcd_path,...
            LeopardCamera1_annotation, VelodyneLidar_annotation, OCULiiRadar_annotation, TIRadar_annotation,...
            LeopardCamera1_IntrinsicMatrix, VelodyneLidar_to_LeopardCamera1_TransformMatrix, OCULiiRadar_to_LeopardCamera1_TransformMatrix, TIRadar_to_LeopardCamera1_TransformMatrix)

    end
end

function showScence_bbox(PROJECT_ON, LeopardCamera1_png_path, VelodyneLidar_pcd_path, OCULiiRadar_pcd_path, TIRadar_pcd_path,...
    LeopardCamera1_annotation, VelodyneLidar_annotation, OCULiiRadar_annotation, TIRadar_annotation,...
    LeopardCamera1_IntrinsicMatrix, VelodyneLidar_to_LeopardCamera1_TransformMatrix, OCULiiRadar_to_LeopardCamera1_TransformMatrix, TIRadar_to_LeopardCamera1_TransformMatrix)

    forward_ranges = [0, 80];
    left_right_ranges = [-40, 40];

    LeopardCamera1_png = imread(LeopardCamera1_png_path);
    LeopardCamera1_timestamp = getTimestampFromPath(LeopardCamera1_png_path);
         
    [VelodyneLidar_pcd, ~] = readPcd(VelodyneLidar_pcd_path);
    VelodyneLidar_timestamp = getTimestampFromPath(VelodyneLidar_pcd_path);
    VelodyneLidar_x_ranges = [forward_ranges(1), forward_ranges(2)];
    VelodyneLidar_y_ranges = [left_right_ranges(1), left_right_ranges(2)];
    VelodyneLidar_z_ranges = [-inf, inf];
    VelodyneLidar_mask = VelodyneLidar_pcd(:,1)>=VelodyneLidar_x_ranges(1)...
        & VelodyneLidar_pcd(:,1)<=VelodyneLidar_x_ranges(2)...
        & VelodyneLidar_pcd(:,2)>=VelodyneLidar_y_ranges(1)...
        & VelodyneLidar_pcd(:,2)<=VelodyneLidar_y_ranges(2)...
        & VelodyneLidar_pcd(:,3)>=VelodyneLidar_z_ranges(1)...
        & VelodyneLidar_pcd(:,3)<=VelodyneLidar_z_ranges(2);  
    VelodyneLidar_pcd_struct = getPcdStruct('VelodyneLidar', VelodyneLidar_pcd, VelodyneLidar_mask, VelodyneLidar_to_LeopardCamera1_TransformMatrix, PROJECT_ON);
        
    
    [OCULiiRadar_pcd, ~] = readPcd(OCULiiRadar_pcd_path);
    OCULiiRadar_timestamp = getTimestampFromPath(OCULiiRadar_pcd_path);    
    OCULiiRadar_x_ranges = [left_right_ranges(1), left_right_ranges(2)];
    OCULiiRadar_y_ranges = [-inf, inf];
    OCULiiRadar_z_ranges = [forward_ranges(1), forward_ranges(2)];
    OCULiiRadar_mask = OCULiiRadar_pcd(:,1)>=OCULiiRadar_x_ranges(1)...
        & OCULiiRadar_pcd(:,1)<=OCULiiRadar_x_ranges(2)...
        & OCULiiRadar_pcd(:,2)>=OCULiiRadar_y_ranges(1)...
        & OCULiiRadar_pcd(:,2)<=OCULiiRadar_y_ranges(2)...  
        & OCULiiRadar_pcd(:,3)>=OCULiiRadar_z_ranges(1)...
        & OCULiiRadar_pcd(:,3)<=OCULiiRadar_z_ranges(2);     
    OCULiiRadar_pcd_struct = getPcdStruct('OCULiiRadar', OCULiiRadar_pcd, OCULiiRadar_mask, OCULiiRadar_to_LeopardCamera1_TransformMatrix, PROJECT_ON);
  

    [TIRadar_pcd, ~] = readPcd(TIRadar_pcd_path);
    TIRadar_timestamp = getTimestampFromPath(TIRadar_pcd_path);    
    TIRadar_x_ranges = [left_right_ranges(1), left_right_ranges(2)];
    TIRadar_y_ranges = [forward_ranges(1), forward_ranges(2)];
    TIRadar_z_ranges = [-inf, inf];
    TIRadar_mask = TIRadar_pcd(:,1)>=TIRadar_x_ranges(1)...
        & TIRadar_pcd(:,1)<=TIRadar_x_ranges(2)...
        & TIRadar_pcd(:,2)>=TIRadar_y_ranges(1)...
        & TIRadar_pcd(:,2)<=TIRadar_y_ranges(2)...  
        & TIRadar_pcd(:,3)>=TIRadar_z_ranges(1)...
        & TIRadar_pcd(:,3)<=TIRadar_z_ranges(2);     
    TIRadar_pcd_struct = getPcdStruct('TIRadar', TIRadar_pcd, TIRadar_mask, TIRadar_to_LeopardCamera1_TransformMatrix, PROJECT_ON);
  
    fig = figure('Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
    tg = uitabgroup(fig);
    t1 = uitab(tg);
    t1.Title = 'sensors';
    t1_ax1 = axes(t1, 'Units', 'normalized', 'OuterPosition', [0, 0.5, 0.5, 0.5]);
    imshow(LeopardCamera1_png);
    title(sprintf('LeopardCamera1: %s s (diff=%.3f s)', LeopardCamera1_timestamp, str2double(LeopardCamera1_timestamp)-str2double(LeopardCamera1_timestamp)));
    t1_ax2 = axes(t1, 'Units', 'normalized', 'OuterPosition', [0.5, 0.5, 0.5, 0.5]);
    scatter3([VelodyneLidar_pcd_struct.x],...
        [VelodyneLidar_pcd_struct.y],...
        [VelodyneLidar_pcd_struct.z],...
        5,...
        [VelodyneLidar_pcd_struct.intensity],...
        'filled')
    xlabel('x(m)');
    ylabel('y(m)');
    zlabel('z(m)');
    axis([VelodyneLidar_x_ranges(1), VelodyneLidar_x_ranges(2), VelodyneLidar_y_ranges(1), VelodyneLidar_y_ranges(2), VelodyneLidar_z_ranges(1), VelodyneLidar_z_ranges(2)]);
    title(sprintf('VelodyneLidar: %s s (diff=%.3f s)', VelodyneLidar_timestamp, str2double(VelodyneLidar_timestamp)-str2double(LeopardCamera1_timestamp)));
    set(t1_ax2, 'View', [-90, 90]);
    colormap("jet");
    colorbar;
    t1_ax3 = axes(t1, 'Units', 'normalized', 'OuterPosition', [0, 0, 0.5, 0.5]);
    scatter3([OCULiiRadar_pcd_struct.x],...
        [OCULiiRadar_pcd_struct.y],...
        [OCULiiRadar_pcd_struct.z],...
        5,...
        [OCULiiRadar_pcd_struct.velocity],...
        'filled')
    xlabel('x(m)');
    ylabel('y(m)');
    zlabel('z(m)');
    axis([OCULiiRadar_x_ranges(1), OCULiiRadar_x_ranges(2), OCULiiRadar_y_ranges(1), OCULiiRadar_y_ranges(2), OCULiiRadar_z_ranges(1), OCULiiRadar_z_ranges(2)]);
    title(sprintf('OCULiiRadar: %s s (diff=%.3f s)', OCULiiRadar_timestamp, str2double(OCULiiRadar_timestamp)-str2double(LeopardCamera1_timestamp)));
    set(t1_ax3, 'View', [0, 0]);
    colormap("jet");
    colorbar;
    t1_ax4 = axes(t1, 'Units', 'normalized', 'OuterPosition', [0.5, 0, 0.5, 0.5]);
    scatter3([TIRadar_pcd_struct.x],...
        [TIRadar_pcd_struct.y],...
        [TIRadar_pcd_struct.z],...
        5,...
        [TIRadar_pcd_struct.velocity],...
        'filled')
    xlabel('x(m)');
    ylabel('y(m)');
    zlabel('z(m)');
    axis([TIRadar_x_ranges(1), TIRadar_x_ranges(2), TIRadar_y_ranges(1), TIRadar_y_ranges(2), TIRadar_z_ranges(1), TIRadar_z_ranges(2)]);
    title(sprintf('TIRadar: %s s (diff=%.3f s)', TIRadar_timestamp, str2double(TIRadar_timestamp)-str2double(LeopardCamera1_timestamp)));
    set(t1_ax4, 'View', [0, 90]);
    colormap("jet");
    colorbar;

    if PROJECT_ON
        t2 = uitab(tg);
        t2.Title = 'projection';
        t2_ax1 = axes(t2, 'Units', 'normalized', 'OuterPosition', [0, 0.5, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('LeopardCamera1: %s s (diff=%.3f s)', LeopardCamera1_timestamp, str2double(LeopardCamera1_timestamp)-str2double(LeopardCamera1_timestamp)));
        t2_ax2 = axes(t2, 'Units', 'normalized', 'OuterPosition', [0.5, 0.5, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('VelodyneLidar: %s s (diff=%.3f s)', VelodyneLidar_timestamp, str2double(VelodyneLidar_timestamp)-str2double(LeopardCamera1_timestamp)));
        hold on;
        scatter([VelodyneLidar_pcd_struct.u],...
            [VelodyneLidar_pcd_struct.v],...
            5,...
            [VelodyneLidar_pcd_struct.intensity],...
            'filled');
        hold off;
        t2_ax3 = axes(t2, 'Units', 'normalized', 'OuterPosition', [0, 0, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('OCULiiRadar: %s s (diff=%.3f s)', OCULiiRadar_timestamp, str2double(OCULiiRadar_timestamp)-str2double(LeopardCamera1_timestamp)));
        hold on;
        scatter([OCULiiRadar_pcd_struct.u],...
            [OCULiiRadar_pcd_struct.v],...
            5,...
            [OCULiiRadar_pcd_struct.velocity],...
            'filled');
        hold off;
        t2_ax4 = axes(t2, 'Units', 'normalized', 'OuterPosition', [0.5, 0, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('TIRadar: %s s (diff=%.3f s)', TIRadar_timestamp, str2double(TIRadar_timestamp)-str2double(LeopardCamera1_timestamp)));
        hold on;
        scatter([TIRadar_pcd_struct.u],...
            [TIRadar_pcd_struct.v],...
            5,...
            [TIRadar_pcd_struct.velocity],...
            'filled');
        hold off;
    end
    
    if ~isempty(VelodyneLidar_annotation)
        VelodyneLidar_bbox_struct = getBboxStruct(VelodyneLidar_annotation, VelodyneLidar_to_LeopardCamera1_TransformMatrix);

        t_new = uitab(tg);
        t_new.Title = 'Annotation from VelodyneLidar';
        
        t_new_ax1 = axes(t_new, 'Units', 'normalized', 'OuterPosition', [0, 0.5, 0.5, 0.5]);
        imshow(LeopardCamera1_png);
        title(sprintf('LeopardCamera1: %s s (diff=%.3f s)', LeopardCamera1_timestamp, str2double(LeopardCamera1_timestamp)-str2double(VelodyneLidar_timestamp)));
        % plot projected bbox
        plot_projected_bbox(t_new_ax1, VelodyneLidar_bbox_struct);
        
        t_new_ax2 = axes(t_new, 'Units', 'normalized', 'OuterPosition', [0.5, 0.5, 0.5, 0.5]);
        scatter3([VelodyneLidar_pcd_struct.x],...
            [VelodyneLidar_pcd_struct.y],...
            [VelodyneLidar_pcd_struct.z],...
            5,...
            [VelodyneLidar_pcd_struct.intensity],...
            'filled')
        xlabel('x(m)');
        ylabel('y(m)');
        zlabel('z(m)');
        axis([VelodyneLidar_x_ranges(1), VelodyneLidar_x_ranges(2), VelodyneLidar_y_ranges(1), VelodyneLidar_y_ranges(2), VelodyneLidar_z_ranges(1), VelodyneLidar_z_ranges(2)]);
        title(sprintf('VelodyneLidar: %s s (diff=%.3f s)', VelodyneLidar_timestamp, str2double(VelodyneLidar_timestamp)-str2double(VelodyneLidar_timestamp)));
        colormap("jet");
        set(t_new_ax2, 'View', [-55, 67]);
        % plot 3d bbox
        plot_3d_bbox(t_new_ax2, VelodyneLidar_bbox_struct);

        t_new_ax3 = axes(t_new, 'Units', 'normalized', 'OuterPosition', [0, 0, 0.5, 0.5]);
        scatter3([OCULiiRadar_pcd_struct.x],...
            [OCULiiRadar_pcd_struct.y],...
            [OCULiiRadar_pcd_struct.z],...
            5,...
            [OCULiiRadar_pcd_struct.velocity],...
            'filled')
        xlabel('x(m)');
        ylabel('y(m)');
        zlabel('z(m)');
        axis([OCULiiRadar_x_ranges(1), OCULiiRadar_x_ranges(2), OCULiiRadar_y_ranges(1), OCULiiRadar_y_ranges(2), OCULiiRadar_z_ranges(1), OCULiiRadar_z_ranges(2)]);
        title(sprintf('OCULiiRadar: %s s (diff=%.3f s)', OCULiiRadar_timestamp, str2double(OCULiiRadar_timestamp)-str2double(VelodyneLidar_timestamp)));
        colormap("jet");
        set(t_new_ax3, 'View', [0, 0]);
        % plot 3d bbox in OCULiiRadar coordinate
        Tv = LeopardCamera1_IntrinsicMatrix\VelodyneLidar_to_LeopardCamera1_TransformMatrix;
        Tv = [Tv;0 0 0 1];
        To = LeopardCamera1_IntrinsicMatrix\OCULiiRadar_to_LeopardCamera1_TransformMatrix;
        To = [To;0 0 0 1];
        VelodyneLidar_to_OCULiiRadar_TransformMatrix = To\Tv;
        plot_transformed_3d_bbox(t_new_ax3, VelodyneLidar_bbox_struct, VelodyneLidar_to_OCULiiRadar_TransformMatrix);

        t_new_ax4 = axes(t_new, 'Units', 'normalized', 'OuterPosition', [0.5, 0, 0.5, 0.5]);
        scatter3([TIRadar_pcd_struct.x],...
            [TIRadar_pcd_struct.y],...
            [TIRadar_pcd_struct.z],...
            5,...
            [TIRadar_pcd_struct.velocity],...
            'filled')
        xlabel('x(m)');
        ylabel('y(m)');
        zlabel('z(m)');
        axis([TIRadar_x_ranges(1), TIRadar_x_ranges(2), TIRadar_y_ranges(1), TIRadar_y_ranges(2), TIRadar_z_ranges(1), TIRadar_z_ranges(2)]);
        title(sprintf('TIRadar: %s s (diff=%.3f s)', TIRadar_timestamp, str2double(TIRadar_timestamp)-str2double(VelodyneLidar_timestamp)));
        colormap("jet");
        set(t_new_ax4, 'View', [0, 90]);
        % plot 3d bbox in TIRadar coordinate
        Tv = LeopardCamera1_IntrinsicMatrix\VelodyneLidar_to_LeopardCamera1_TransformMatrix;
        Tv = [Tv;0 0 0 1];
        Tt = LeopardCamera1_IntrinsicMatrix\TIRadar_to_LeopardCamera1_TransformMatrix;
        Tt = [Tt;0 0 0 1];
        VelodyneLidar_to_TIRadar_TransformMatrix = Tt\Tv;
        plot_transformed_3d_bbox(t_new_ax4, VelodyneLidar_bbox_struct, VelodyneLidar_to_TIRadar_TransformMatrix);
    end
end

function plot_transformed_3d_bbox(ax, bbox_struct, transformMatrix)
    hold(ax,'on');
    for i = 1:length(bbox_struct.points)
        corners_xyz = [[bbox_struct.points(i).x], [bbox_struct.points(i).y], [bbox_struct.points(i).z]];
        % transform
        corners_xyz = transform_3Dpoint_to_3Dpoint(corners_xyz, transformMatrix);
        for j = 1:size(bbox_struct.lines,1)
            if j<=4
                line(ax, corners_xyz(bbox_struct.lines(j,:),1), corners_xyz(bbox_struct.lines(j,:),2),...
                    corners_xyz(bbox_struct.lines(j,:),3), 'Color', 'r', 'LineWidth', 2);
            else
                line(ax, corners_xyz(bbox_struct.lines(j,:),1), corners_xyz(bbox_struct.lines(j,:),2),...
                    corners_xyz(bbox_struct.lines(j,:),3), 'Color', 'g', 'LineWidth', 2);
            end
        end
    end
    hold(ax,'off');
end

function xyz_transformed = transform_3Dpoint_to_3Dpoint(xyz, transformMatrix)
    xyz_transformed = [xyz'; ones(1, size(xyz,1))];
    xyz_transformed = transformMatrix * xyz_transformed;
    xyz_transformed = xyz_transformed(1:3, :);
    xyz_transformed = xyz_transformed';
end

function plot_projected_bbox(ax, bbox_struct)
    hold(ax,'on');
    for i = 1:length(bbox_struct.points)
        corners_uv = [[bbox_struct.points(i).u], [bbox_struct.points(i).v]];
        for j = 1:size(bbox_struct.lines,1)
            if j<=4
                line(ax, corners_uv(bbox_struct.lines(j,:),1), corners_uv(bbox_struct.lines(j,:),2), 'Color', 'r');
            else
                line(ax, corners_uv(bbox_struct.lines(j,:),1), corners_uv(bbox_struct.lines(j,:),2), 'Color', 'g');
            end
        end
    end
    hold(ax,'off');
end

function plot_3d_bbox(ax, bbox_struct)
    hold(ax,'on');
    for i = 1:length(bbox_struct.points)
        corners_xyz = [[bbox_struct.points(i).x], [bbox_struct.points(i).y], [bbox_struct.points(i).z]];
        for j = 1:size(bbox_struct.lines,1)
            if j<=4
                line(ax, corners_xyz(bbox_struct.lines(j,:),1), corners_xyz(bbox_struct.lines(j,:),2),...
                    corners_xyz(bbox_struct.lines(j,:),3), 'Color', 'r', 'LineWidth', 2);
            else
                line(ax, corners_xyz(bbox_struct.lines(j,:),1), corners_xyz(bbox_struct.lines(j,:),2),...
                    corners_xyz(bbox_struct.lines(j,:),3), 'Color', 'g', 'LineWidth', 2);
            end
        end
    end
    hold(ax,'off');
end

function bboxes_struct = getBboxStruct(annotation, transformMatrix)
    points_struct = struct();
    for i = 1:length(annotation)
        corners_xyz = calculate_corners(annotation(i).xc, annotation(i).yc, annotation(i).zc, annotation(i).l, annotation(i).w, annotation(i).h, annotation(i).theta);
        points_struct(i).x = corners_xyz(:, 1);
        points_struct(i).y = corners_xyz(:, 2);
        points_struct(i).z = corners_xyz(:, 3);
        corners_uv = project_3Dpoint_to_pixel(corners_xyz, transformMatrix);
        points_struct(i).u = corners_uv(:, 1);
        points_struct(i).v = corners_uv(:, 2);        
    end
    
    faces_struct = struct();
    faces_struct.front = [1,2,3,4];
    faces_struct.back = [5,6,7,8];
    faces_struct.left = [2,6,7,3];
    faces_struct.right = [5,1,4,8];
    faces_struct.top = [2,1,5,6];
    faces_struct.bottom = [7,8,4,3];

    lines = [1,2;2,3;3,4;4,1;5,6;6,7;7,8;8,5;1,5;2,6;3,7;4,8];

    bboxes_struct = struct('points', points_struct, 'faces', faces_struct, 'lines', lines);
end

function corners_xyz = calculate_corners(xc, yc, zc, l, w, h, theta)
    x = [l/2, l/2, l/2, l/2, -l/2, -l/2, -l/2, -l/2];
    y = [-w/2, w/2, w/2, -w/2, -w/2, w/2, w/2, -w/2];
    z = [h/2, h/2, -h/2, -h/2, h/2, h/2, -h/2, -h/2];

    rot_matrix = [cos(pi/180*theta), -sin(pi/180*theta), 0; sin(pi/180*theta), cos(pi/180*theta), 0; 0, 0, 1];
    corners_xyz = rot_matrix * [x; y; z] + [xc;yc;zc];
    corners_xyz = corners_xyz';
end

function pcd_struct = getPcdStruct(type, pcd, mask, transformMatrix, trasform_on)
    
    xyz = [pcd(mask,1), pcd(mask,2), pcd(mask, 3)];

    if trasform_on
        uv = project_3Dpoint_to_pixel(xyz, transformMatrix);
    
        if strcmp(type, 'VelodyneLidar')
            pcd_struct = struct('u', num2cell(uv(:,1)),...
                'v', num2cell(uv(:,2)),...
                'x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'intensity', num2cell(pcd(mask, 4)),...
                'ring', num2cell(pcd(mask, 5)));
        elseif strcmp(type, 'OCULiiRadar')
            pcd_struct = struct('u', num2cell(uv(:,1)),...
                'v', num2cell(uv(:,2)),...
                'x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'velocity', num2cell(pcd(mask, 4)),...
                'intensity', num2cell(pcd(mask, 5)));
        elseif strcmp(type, 'TIRadar') 
            pcd_struct = struct('u', num2cell(uv(:,1)),...
                'v', num2cell(uv(:,2)),...
                'x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'velocity', num2cell(pcd(mask, 4)),...
                'SNR', num2cell(pcd(mask, 5)));
        else
            pcd_struct = struct();
        end
    else
        if strcmp(type, 'VelodyneLidar')
            pcd_struct = struct('x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'intensity', num2cell(pcd(mask, 4)),...
                'ring', num2cell(pcd(mask, 5)));
        elseif strcmp(type, 'OCULiiRadar')
            pcd_struct = struct('x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'velocity', num2cell(pcd(mask, 4)),...
                'intensity', num2cell(pcd(mask, 5)));
        elseif strcmp(type, 'TIRadar') 
            pcd_struct = struct('x', num2cell(xyz(:,1)),...
                'y', num2cell(xyz(:,2)),...
                'z', num2cell(xyz(:,3)),...
                'velocity', num2cell(pcd(mask, 4)),...
                'SNR', num2cell(pcd(mask, 5)));
        else
            pcd_struct = struct();
        end
    end

end

function uv = project_3Dpoint_to_pixel(xyz, transformMatrix)
    xyz1 = [xyz'; ones(1, size(xyz,1))];
    uv1=transformMatrix * xyz1 * (diag(1./([0,0,1] * transformMatrix * xyz1)));
    uv=uv1(1:2, :);
    uv = round(uv);
    uv = uv';
end


function timestamp = getTimestampFromPath(path)
    temp = split(path, filesep);
    temp = temp{end};
    temp = split(temp, '.');
    timestamp = strcat(temp{1}, '.', temp{2});    
end

function [pcd, colInfo] = readPcd(pcd_path)
    fid = fopen(pcd_path, 'r');
    fgetl(fid);
    temp1 = fgetl(fid);
    fgetl(fid);
    temp2 = fgetl(fid);
    temp1 = split(temp1);
    temp2 = split(temp2);
    colInfo = struct();
    for i = 2:length(temp1)
        if temp2{i} == 'F'
            eval(sprintf('colInfo.%s = "float32";', temp1{i}));
        end
    end
    fgetl(fid);
    fgetl(fid);
    fgetl(fid);
    fgetl(fid);
    fgetl(fid);
    fgetl(fid);
    formatSpec = '';
    for i = 2:length(temp1)
        if i ~= length(temp1)
            formatSpec = strcat(formatSpec, '%f', {32});
        else
            formatSpec = strcat(formatSpec, '%f');
        end
    end
    formatSpec = formatSpec{1};

    pcd = fscanf(fid, formatSpec, [length(temp1)-1, Inf]);
    pcd = pcd';

    fclose(fid);
    
end


function iscomplete = checkFolders(root_path, groupId, frameId)
    iscomplete = true;

    folder_root = fullfile(root_path, sprintf('group%04d_frame%04d',groupId,frameId));
    folder_LeopardCamera1 = fullfile(folder_root, 'LeopardCamera1');
    folder_VelodyneLidar = fullfile(folder_root, 'VelodyneLidar');
    folder_OCULiiRadar = fullfile(folder_root, 'OCULiiRadar');
    folder_TIRadar = fullfile(folder_root, 'TIRadar');
    folder_MEMS = fullfile(folder_root, 'MEMS');

    if ~exist(folder_root, 'dir')        
        fprintf('%s does not exist.\n', folder_root);
        iscomplete = false;
    end

    if ~exist(folder_LeopardCamera1, 'dir')
        fprintf('%s does not exist.\n', folder_LeopardCamera1);
        iscomplete = false;
    else
        temp = dir(fullfile(folder_LeopardCamera1, '*.raw'));
        if isempty(temp)
            fprintf('.raw does not exist in %s.\n', folder_LeopardCamera1);
            iscomplete = false;
        end
        temp = dir(fullfile(folder_LeopardCamera1, '*.png'));
        if isempty(temp)
            fprintf('.png does not exist in %s.\n', folder_LeopardCamera1);
            iscomplete = false;
        end
        temp = dir(fullfile(folder_LeopardCamera1, '*.json'));
        if isempty(temp)
            fprintf('.json does not exist in %s.\n', folder_LeopardCamera1);
            iscomplete = false;
        end
    end

    if ~exist(folder_VelodyneLidar, 'dir')
        fprintf('%s does not exist.\n', folder_VelodyneLidar);
        iscomplete = false;
    else
        temp = dir(fullfile(folder_VelodyneLidar, '*.pcd'));
        if isempty(temp)
            fprintf('.pcd does not exist in %s.\n', folder_VelodyneLidar);
            iscomplete = false;
        end
        temp = dir(fullfile(folder_VelodyneLidar, '*.json'));
        if isempty(temp)
            fprintf('.json does not exist in %s.\n', folder_VelodyneLidar);
            iscomplete = false;
        end        
    end

    if ~exist(folder_OCULiiRadar, 'dir')
        fprintf('%s does not exist.\n', folder_OCULiiRadar);
        iscomplete = false;
    else
        temp = dir(fullfile(folder_OCULiiRadar, '*.pcd'));
        if isempty(temp)
            fprintf('.pcd does not exist in %s.\n', folder_OCULiiRadar);
            iscomplete = false;
        end
        temp = dir(fullfile(folder_OCULiiRadar, '*.json'));
        if isempty(temp)
            fprintf('.json does not exist in %s.\n', folder_OCULiiRadar);
            iscomplete = false;
        end
    end

    if ~exist(folder_TIRadar, 'dir')
        fprintf('%s does not exist.\n', folder_TIRadar);
        iscomplete = false;
    else
        temp = dir(fullfile(folder_TIRadar, '*.pcd'));
        if isempty(temp)
            fprintf('.pcd does not exist in %s.\n', folder_TIRadar);
            iscomplete = false;
        end
        temp = dir(fullfile(folder_TIRadar, '*.json'));
        if isempty(temp)
            fprintf('.json does not exist in %s.\n', folder_TIRadar);
            iscomplete = false;
        end
    end

    if ~exist(folder_MEMS, 'dir')
        fprintf('%s does not exist.\n', folder_MEMS);
        iscomplete = false;
    end
    
    if iscomplete
        fprintf('%s is complete.\n', folder_root);
    else
        fprintf('%s is incomplete.\n', folder_root);
    end
end
