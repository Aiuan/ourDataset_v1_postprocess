import os
import glob
import json

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

def summary_LeopardCamera1_label(LeopardCamera1_label_path):
    label_origin = load_json(LeopardCamera1_label_path)

    truncation_level_value = []
    class_value = []
    parked_value = []

    for i in range(len(label_origin['annotation'])):
        truncation_level_value.append(label_origin['annotation'][i]['truncation_level'])
        class_value.append(label_origin['annotation'][i]['class'])
        parked_value.append(label_origin['annotation'][i]['parked'])

    return truncation_level_value, class_value, parked_value

def summary_VelodyneLidar_label(VelodyneLidar_label_path):
    label_origin = load_json(VelodyneLidar_label_path)

    class_value = []
    parked_value = []

    for i in range(len(label_origin['annotation'])):
        class_value.append(label_origin['annotation'][i]['class'])
        parked_value.append(label_origin['annotation'][i]['parked'])

    return class_value, parked_value

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
    dataset_root = '/media/ourDataset/v1.0_label'
    label_root = '/media/ourDataset/yunce_label'

    info = process_label(label_root)
    # value_truncation_level = []
    # value_class = []
    # value_parked = []
    # value_lidar_class = []
    # value_lidar_parked = []
    error_cnt = 0

    for i, (frame, value) in enumerate(info.items()):
        dataset_group_path = os.path.join(dataset_root, value['group_folder_name'])
        dataset_frame_path = os.path.join(dataset_group_path, frame)
        print('[{} / {}] Copy label to {}'.format(i + 1, len(info), dataset_frame_path))
        if not os.path.exists(dataset_frame_path):
            if '_labeled' in frame:
                dataset_frame_path = dataset_frame_path.replace('_labeled', '')
            else:
                dataset_frame_path = dataset_frame_path+'_labeled'
            print('## dataset_frame_path changing: {}'.format(dataset_frame_path))


        LeopardCamera1_label, error_cnt_single = fix_LeopardCamera1_label(value['LeopardCamera1_label_path'])
        error_cnt += error_cnt_single
        dataset_LeopardCamera1_label_path = glob.glob(os.path.join(dataset_frame_path, 'LeopardCamera1', '*.json'))[0]
        if os.path.exists(dataset_LeopardCamera1_label_path):
            with open(dataset_LeopardCamera1_label_path, 'w') as f:
                f.write(json.dumps(LeopardCamera1_label))

        VelodyneLidar_label = fix_VelodyneLidar_label(value['VelodyneLidar_label_path'])
        dataset_VelodyneLidar_label_path = glob.glob(os.path.join(dataset_frame_path, 'VelodyneLidar', '*.json'))[0]
        if os.path.exists(dataset_VelodyneLidar_label_path):
            with open(dataset_VelodyneLidar_label_path, 'w') as f:
                f.write(json.dumps(VelodyneLidar_label))

        if value['replaced_frame'] is not None:
            replaced_path = os.path.join(dataset_root, value['group_folder_name'], value['replaced_frame'])
            replace_path = dataset_frame_path
            if os.path.exists(replaced_path):
                os.rename(
                    replaced_path,
                    replaced_path.replace('_labeled', '')
                )
                print('## {} >>>> {}'.format(replaced_path, replaced_path.replace('_labeled', '')))
                os.rename(replace_path, replace_path+'_labeled')
                print('## {} >>>> {}'.format(replaced_path, replaced_path.replace('_labeled', '')))
            else:
                print('## Already renamed.')


        # truncation_level_value, class_value, parked_value = summary_LeopardCamera1_label(value['LeopardCamera1_label_path'])
        # value_truncation_level.extend(truncation_level_value)
        # value_class.extend(class_value)
        # value_parked.extend(parked_value)
        # class_lidar_value, parked_lidar_value = summary_VelodyneLidar_label(value['VelodyneLidar_label_path'])
        # value_lidar_class.extend(class_lidar_value)
        # value_lidar_parked.extend(parked_lidar_value)



    # value_truncation_level_unique = set(value_truncation_level)
    # value_class_unique = set(value_class)
    # value_parked_unique = set(value_parked)
    # value_lidar_class_unique = set(value_lidar_class)
    # value_lidar_parked_unique = set(value_lidar_parked)

    print(error_cnt)
    print('done')



if __name__ == '__main__':
    main()