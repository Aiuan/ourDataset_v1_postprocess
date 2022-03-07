import os
import shutil
import pandas as pd
import numpy as np
from openpyxl import load_workbook
from openpyxl.utils.dataframe import dataframe_to_rows


OURDATASET_ROOT = "/media/ourDataset/v1.0"
SELECT_ROOT = "/media/ourDataset/v1.0_select_results"
SAVE_ROOT = "/media/ourDataset/v1.0_label"
SAVE_VEDIO_ROOT = "/media/ourDataset/v1.0_label/vedio"

def save_dayExp_group_selected(dayExp_selected, dayExp_group_selected):
    print('{} start.'.format(dayExp_group_selected))

    dayExp = dayExp_group_selected.split('_group')[0]
    groupId = int(dayExp_group_selected.split('_group')[1].split('(')[0])
    cnt_frame = int(dayExp_group_selected.split('(')[1].split('_')[0])

    # read selected frame to be labeled
    wb = load_workbook(os.path.join(SELECT_ROOT, dayExp_selected, dayExp_group_selected))
    ws = wb.active
    data = ws.values
    cols = next(data)
    data = list(data)
    df = pd.DataFrame(data, columns=cols)
    frameId_to_label = df[df['need_label']==1]['frameId'].values.tolist()

    # save vedio
    if not os.path.exists(SAVE_VEDIO_ROOT):
        os.mkdir(SAVE_VEDIO_ROOT)
    src_vedio_path = os.path.join(OURDATASET_ROOT, dayExp, 'Vedio', dayExp_group_selected.replace('.xlsx', '.avi'))
    des_vedio_path = os.path.join(SAVE_VEDIO_ROOT, '{}_group{:0>4d}_{}frames_{}labeled'.format(dayExp, groupId, cnt_frame,
                                                                                   len(frameId_to_label)))
    if not os.path.exists(des_vedio_path):
        shutil.copyfile(src_vedio_path, des_vedio_path)

    # save data files
    cnt_frame_to_label = len(frameId_to_label)
    des_path = os.path.join(SAVE_ROOT, '{}_group{:0>4d}_{}frames_{}labeled'.format(dayExp, groupId, cnt_frame,
                                                                                   cnt_frame_to_label))
    if not os.path.exists(des_path):
        os.mkdir(des_path)

    for frameId in range(cnt_frame):
        data_folder_src_path = os.path.join(OURDATASET_ROOT, dayExp, 'Dataset',
                                        'group{:0>4d}_frame{:0>4d}'.format(groupId, frameId))
        if frameId in frameId_to_label:
            data_folder_des_path = os.path.join(des_path,
                                                '{}_group{:0>4d}_frame{:0>4d}_labeled'.format(dayExp, groupId, frameId))
        else:
            data_folder_des_path = os.path.join(des_path,
                                                '{}_group{:0>4d}_frame{:0>4d}'.format(dayExp, groupId, frameId))

        if not os.path.exists(data_folder_des_path):
            shutil.copytree(data_folder_src_path, data_folder_des_path)

    print('{} has been processed.'.format(dayExp_group_selected))
    return cnt_frame, cnt_frame_to_label


def main():
    cnt_frames = 0
    cnt_frames_to_label = 0
    dayExps_selected = os.listdir(SELECT_ROOT)
    dayExps_selected.sort()
    for dayExp_selected in dayExps_selected:
        dayExp_groups_selected = os.listdir(os.path.join(SELECT_ROOT, dayExp_selected))
        for dayExp_group_selected in dayExp_groups_selected:
            if not '.xlsx' in dayExp_group_selected:
                continue
            res = save_dayExp_group_selected(dayExp_selected, dayExp_group_selected)
            cnt_frames += res[0]
            cnt_frames_to_label += res[1]
    print('Total frame: {}'.format(cnt_frames))
    print('Total frame: {}'.format(cnt_frames_to_label))


if __name__ == "__main__":
    main()