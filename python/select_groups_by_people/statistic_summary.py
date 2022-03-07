import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from openpyxl import Workbook
from openpyxl.utils.dataframe import dataframe_to_rows

OURDATASET_ROOT = "/media/ourDataset/v1.0"
GROUP_MIN_LAST_FRAME = 100 # last_time = last_frame * fps(10)
SAVE_ON = 1
labelInfo_output_path = "./runs"

def main():
    dayExps = os.listdir(OURDATASET_ROOT)
    dayExps.sort()
    df_dayExp_groupId_frameId = pd.DataFrame({
        'dayExp': [],
        'groupId': [],
        'frameId': [],
        'path': []
    })
    for dayExp in dayExps:
        dayExp_dataset_folder = os.path.join(OURDATASET_ROOT, dayExp, 'Dataset')
        dayExp_groupId_frameId_folders = os.listdir(dayExp_dataset_folder)
        dayExp_groupId_frameId_folders.sort()
        temp = pd.DataFrame({
            'dayExp': [dayExp for item in dayExp_groupId_frameId_folders],
            'groupId': [int(item[5:9]) for item in dayExp_groupId_frameId_folders],
            'frameId': [int(item[15:19]) for item in dayExp_groupId_frameId_folders],
            'path': [os.path.join(dayExp_dataset_folder, item) for item in dayExp_groupId_frameId_folders]
        })

        df_dayExp_groupId_frameId = pd.concat([df_dayExp_groupId_frameId, temp], axis=0, ignore_index=True)


    cnt = df_dayExp_groupId_frameId.groupby(['dayExp', "groupId"]).agg("count")
    if SAVE_ON:
        df_save = pd.DataFrame({
            "dayExp": ["{}".format(item[0]) for item in cnt.frameId.keys().to_list()],
            "groupId": ["{}_group{:0>4d}".format(item[0], int(item[1])) for item in cnt.frameId.keys().to_list()],
            "cnt": cnt.frameId.values.tolist()
        })
        wb = Workbook()
        ws = wb.active
        for r in dataframe_to_rows(df_save, index=False, header=True):
            ws.append(r)
        if not os.path.exists(labelInfo_output_path):
            os.mkdir(labelInfo_output_path)
        df_label_save_path = os.path.join(labelInfo_output_path, 'cnt_frames.xlsx')
        wb.save(df_label_save_path)
        # if not os.path.exists(df_label_save_path):
        #     wb.save(df_label_save_path)


    # data = cnt["frameId"]
    # bin_width = 10
    # data_bins = [x for x in range(50-bin_width//2, data.max()+bin_width//2, bin_width)]
    # res = plt.hist(data, bins=data_bins)
    # plt.xlabel("cnt_frames_in_group")
    # plt.xticks([x for x in range(50, data.max()+bin_width//2, bin_width)], rotation="vertical")
    # plt.ylabel("cnt_groups")
    # for i in range(len(res[0])):
    #     plt.text(res[1][i], res[0][i]+2, str(int(res[0][i])))
    # plt.show()

    data = cnt[cnt["frameId"]>=GROUP_MIN_LAST_FRAME]["frameId"]
    bin_width = 10
    data_bins = [x for x in range(GROUP_MIN_LAST_FRAME - bin_width // 2, data.max() + bin_width // 2, bin_width)]
    res = plt.hist(data, bins=data_bins)
    plt.xlabel("cnt_frames_in_group")
    plt.xticks([x for x in range(GROUP_MIN_LAST_FRAME, data.max() + bin_width // 2, bin_width)], rotation="vertical")
    plt.ylabel("cnt_groups")
    for i in range(len(res[0])):
        plt.text(res[1][i], res[0][i] + 2, str(int(res[0][i])))
    plt.show()

    print("Sum_groups={}, Sum_frames={}".format(len(data), data.sum()))

    print("done")


if __name__ == "__main__":
    main()