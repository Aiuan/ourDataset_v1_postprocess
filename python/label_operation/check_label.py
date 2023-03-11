import os
import json

import numpy as np
import pandas as pd

def process_label(label_root):
    folders = os.listdir(label_root)

    cnt = 0
    info = dict()
    info_group = dict()

    for folder in folders:
        if folder == 'replace_data':
            continue
        groups = os.listdir(os.path.join(label_root, folder))
        for group in groups:
            info_group[group[:20]] = group

            frames = os.listdir(os.path.join(label_root, folder, group))
            for frame in frames:
                cnt += 1
                print('Processing frame{} {}'.format(cnt, os.path.join(label_root, folder, group, frame)))
                group_folder_name = group
                frame_folder_name = frame
                LeopardCamera1_label_path = os.path.join(
                    os.path.join(label_root, folder, group, frame, 'LeopardCamera1'),
                    os.listdir(os.path.join(label_root, folder, group, frame, 'LeopardCamera1'))[0]
                )
                VelodyneLidar_label_path = os.path.join(
                    os.path.join(label_root, folder, group, frame, 'VelodyneLidar'),
                    os.listdir(os.path.join(label_root, folder, group, frame, 'VelodyneLidar'))[0]
                )
                info[frame_folder_name] = {
                    'group_folder_name': group_folder_name,
                    'frame_folder_name': frame_folder_name,
                    'LeopardCamera1_label_path': LeopardCamera1_label_path,
                    'VelodyneLidar_label_path': VelodyneLidar_label_path,
                    'replaced_frame': None
                }
    print(cnt)
    print('\n====================================================================')

    cnt_replace = 0
    replaced_frames = os.listdir(os.path.join(label_root, 'replace_data'))
    for replaced_frame in replaced_frames:
        cnt_replace += 1
        replace_frame = os.listdir(os.path.join(label_root, 'replace_data', replaced_frame))[0]
        print('{} >>>>>>>>>>>>>> {}'.format(replaced_frame, replace_frame))

        group_folder_name = info_group[replaced_frame[:20]]
        frame_folder_name = replace_frame
        LeopardCamera1_label_path = os.path.join(
            os.path.join(label_root, 'replace_data', replaced_frame, replace_frame, 'LeopardCamera1'),
            os.listdir(os.path.join(label_root, 'replace_data', replaced_frame, replace_frame, 'LeopardCamera1'))[0]
        )
        VelodyneLidar_label_path = os.path.join(
            os.path.join(label_root, 'replace_data', replaced_frame, replace_frame, 'VelodyneLidar'),
            os.listdir(os.path.join(label_root, 'replace_data', replaced_frame, replace_frame, 'VelodyneLidar'))[0]
        )
        info[frame_folder_name] = {
            'group_folder_name': group_folder_name,
            'frame_folder_name': frame_folder_name,
            'LeopardCamera1_label_path': LeopardCamera1_label_path,
            'VelodyneLidar_label_path': VelodyneLidar_label_path,
            'replaced_frame': replaced_frame
        }
    print(cnt_replace)

    return info

def load_json(json_path):
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data

def fix_LeopardCamera1_label(LeopardCamera1_label_path):
    label_origin = load_json(LeopardCamera1_label_path)
    error_cnt = 0

    truncation_level_dict = {
        '未遮挡': 0,
        '部分遮挡': 1,
        '80%以上遮挡': 2
    }
    class_dict = {
        '轿车': 'car',
        '客车公交车': 'bus',
        '货车': 'truck',
        '特殊车辆': 'special_vehicle',
        '敏感车辆': 'sensitive_object',
        '行人': 'pedestrian',
        '骑摩托车的人': 'motorcyclist',
        '摩托车': 'motorcycle',
        '骑自行车的人': 'cyclist',
        '自行车': 'cycle',
        '自行车群': 'cycle_group'
    }
    parked_dict = {
        '0': 0,
        '1': 1
    }

    for i in range(len(label_origin['annotation'])):
        if label_origin['annotation'][i]['truncation_level'] in list(truncation_level_dict.keys()):
            label_origin['annotation'][i]['truncation_level'] = truncation_level_dict[
                label_origin['annotation'][i]['truncation_level']]
        else:
            error_cnt += 1
            print(LeopardCamera1_label_path)
            print(i)
            print(label_origin['annotation'][i]['truncation_level'])
            label_origin['annotation'][i]['truncation_level'] = 1  # 停靠  更正为 1（部分遮挡）

        label_origin['annotation'][i]['class'] = class_dict[
            label_origin['annotation'][i]['class']]
        label_origin['annotation'][i]['parked'] = parked_dict[
            label_origin['annotation'][i]['parked']]
        label_origin['annotation'][i]['parking'] = label_origin['annotation'][i].pop('parked')

    return label_origin, error_cnt

def fix_VelodyneLidar_label(VelodyneLidar_label_path):
    label_origin = load_json(VelodyneLidar_label_path)

    parked_dict = {
        '0': 0,
        '1': 1
    }

    for i in range(len(label_origin['annotation'])):
        label_origin['annotation'][i]['parked'] = parked_dict[
            label_origin['annotation'][i]['parked']]

        label_origin['annotation'][i]['parking'] = label_origin['annotation'][i].pop('parked')
        label_origin['annotation'][i]['point_num'] = label_origin['annotation'][i].pop('num')

    return label_origin


def main():
    label_root = '/media/ourDataset/yunce_label'

    info = process_label(label_root)

    df_2Dbbox = pd.DataFrame()
    df_3Dbbox = pd.DataFrame()

    for i, (frame, value) in enumerate(info.items()):
        print('>>>> [{} / {}] '.format(i + 1, len(info)))

        LeopardCamera1_label, _ = fix_LeopardCamera1_label(value['LeopardCamera1_label_path'])
        VelodyneLidar_label = fix_VelodyneLidar_label(value['VelodyneLidar_label_path'])

        df_2Dbbox_tmp = pd.DataFrame(LeopardCamera1_label['annotation'])
        df_2Dbbox_tmp['group_folder'] = value['group_folder_name']
        df_2Dbbox_tmp['frame_folder'] = value['frame_folder_name']
        df_2Dbbox_tmp['replaced_frame'] = value['replaced_frame']
        df_2Dbbox = df_2Dbbox.append(df_2Dbbox_tmp, ignore_index=True)

        df_3Dbbox_tmp = pd.DataFrame(VelodyneLidar_label['annotation'])
        df_3Dbbox_tmp['group_folder'] = value['group_folder_name']
        df_3Dbbox_tmp['frame_folder'] = value['frame_folder_name']
        df_3Dbbox_tmp['replaced_frame'] = value['replaced_frame']
        df_3Dbbox = df_3Dbbox.append(df_3Dbbox_tmp, ignore_index=True)

    df_2Dbbox.to_csv('./df_2Dbbox.csv')
    df_3Dbbox.to_csv('./df_3Dbbox.csv')

    mask_w_less_25 = df_2Dbbox['w'] < 25
    mask_h_less_25 = df_2Dbbox['h'] < 25
    df_2Dbbox_error = df_2Dbbox[mask_w_less_25 | mask_h_less_25]
    df_2Dbbox_error['error_type'] = ''
    df_2Dbbox_error['error_type'][mask_w_less_25] += 'w_less_25, '
    df_2Dbbox_error['error_type'][mask_h_less_25] += 'h_less_25, '
    df_2Dbbox_error.to_csv('./df_2Dbbox_error.csv')

    mask_x_less_0 = df_3Dbbox['x'] < 0
    mask_x_greater_100 = df_3Dbbox['x'] > 100
    mask_car_numpcd_less_30 = (df_3Dbbox['class'].isin(['car', 'bus', 'truck', 'special_vehicle']))&(df_3Dbbox['point_num']<30)
    mask_cycle_numpcd_less_15 = (df_3Dbbox['class'].isin(['pedestrian', 'motorcycle', 'cycle', 'motorcyclist', 'cyclist']))&(df_3Dbbox['point_num']<15)
    df_3Dbbox_error = df_3Dbbox[mask_x_less_0 | mask_x_greater_100 | mask_car_numpcd_less_30 | mask_cycle_numpcd_less_15]
    df_3Dbbox_error['error_type'] = ''
    df_3Dbbox_error['error_type'][mask_x_less_0] += 'x_less_0, '
    df_3Dbbox_error['error_type'][mask_x_greater_100] += 'x_greater_100, '
    df_3Dbbox_error['error_type'][mask_car_numpcd_less_30] += 'car_numpcd_less_30, '
    df_3Dbbox_error['error_type'][mask_cycle_numpcd_less_15] += 'cycle_numpcd_less_15, '
    df_3Dbbox_error.to_csv('./df_3Dbbox_error.csv')

    print('done')



if __name__ == '__main__':
    main()