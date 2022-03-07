import os
import sys
import shutil
import numpy as np
import pandas as pd
import cv2
from openpyxl import Workbook
from openpyxl.utils.dataframe import dataframe_to_rows

OURDATASET_ROOT = "/media/ourDataset/v1.0"
num_frames_per_label = 5
labelInfo_output_path = os.path.join("./runs")
discard_path = os.path.join(labelInfo_output_path, "discard")

def main(dayExp, groupId):
    df_groupsInfo = getGroupsInfo(dayExp, os.path.join(OURDATASET_ROOT, dayExp, "Dataset"), num_frames_per_label)

    window_title = dayExp
    cv2.namedWindow(window_title, cv2.WINDOW_NORMAL | cv2.WINDOW_KEEPRATIO)
    for i_groupId in range(len(df_groupsInfo)):
        if df_groupsInfo["groupId"].iloc[i_groupId] != int(groupId):
            continue

        print("============================================================================")
        images_projection_folder = os.path.join(OURDATASET_ROOT, dayExp, "Pic", "Projections")
        images_sensor_folder = os.path.join(OURDATASET_ROOT, dayExp, "Pic", "Sensors")

        labelInfo_path = generate_labelInfo(dayExp, df_groupsInfo["groupId"].iloc[i_groupId], df_groupsInfo.iloc[i_groupId], labelInfo_output_path)

        checkGroup(labelInfo_path, window_title, dayExp, df_groupsInfo["groupId"].iloc[i_groupId], df_groupsInfo.iloc[i_groupId], images_projection_folder, images_sensor_folder)

    cv2.destroyAllWindows()

def generate_labelInfo(dayExp, groupId, groupInfo, labelInfo_output_path):
    df_label = pd.DataFrame({
        "dayExp": [dayExp for i in groupInfo["frameIds"]],
        "groupId": [groupId for i in groupInfo["frameIds"]],
        "frameId": groupInfo["frameIds"],
        "need_label": [1 if i in groupInfo["frameIds_to_label"] else 0 for i in groupInfo["frameIds"]]
    })
    wb = Workbook()
    ws = wb.active
    for r in dataframe_to_rows(df_label, index=False, header=True):
        ws.append(r)
    if not os.path.exists(labelInfo_output_path):
        os.mkdir(labelInfo_output_path)
    df_label_save_path = os.path.join(labelInfo_output_path, '{}_group{:0>4d}({}_frames).xlsx'.format(dayExp, groupId, len(groupInfo["frameIds"])))
    if not os.path.exists(df_label_save_path):
        wb.save(df_label_save_path)

    print("{}_group{:0>4d} generate_labelInfo function done.".format(dayExp, groupId))
    return df_label_save_path



def checkGroup(labelInfo_path, window_title, dayExp, groupId, groupInfo, images_projection_folder, images_sensor_folder):
    print("Processing {}_group{:0>4d}, please check the frame which need to be labeled accroding to the {}".format(dayExp, groupId, labelInfo_path))
    frameIds = groupInfo["frameIds"]
    frameIds_to_label = groupInfo["frameIds_to_label"]

    i_frameId = 0
    while (i_frameId < len(frameIds) and i_frameId >= 0):
        frameId = frameIds[i_frameId]
        # print("==============================================")
        print("{}_group{:0>4d}_frame{:0>4d}({}/{})".format(dayExp, groupId, frameId, frameId, len(frameIds)-1))
        image_projection = cv2.imread(
            os.path.join(images_projection_folder, "groupId{:0>4d}_frameId{:0>4d}.jpg".format(groupId, frameId)),
            cv2.IMREAD_COLOR)
        image_sensor = cv2.imread(
            os.path.join(images_sensor_folder, "groupId{:0>4d}_frameId{:0>4d}.jpg".format(groupId, frameId)),
            cv2.IMREAD_COLOR)
        img = np.hstack((cv2.resize(image_projection, (1836, 1080), interpolation=cv2.INTER_LINEAR),
                         cv2.resize(image_sensor, (1836, 1080), interpolation=cv2.INTER_LINEAR)))
        img_text = img
        textIdx = 0
        if frameId in frameIds_to_label:
            img_text = addText(img_text, textIdx,
                               "{}_group{:0>4d}_frame{:0>4d}({}/{}) ---- LABEL".format(dayExp, groupId, frameId, frameId,
                                                                             len(frameIds)-1), (0, 0, 255))
        else:
            img_text = addText(img_text, textIdx,
                               "{}_group{:0>4d}_frame{:0>4d}({}/{}) ---- UNLABEL".format(dayExp, groupId, frameId, frameId,
                                                                            len(frameIds)-1), (0, 0, 0))
        textIdx += 1
        img_text = addText(img_text, textIdx, 'Keyboard help:', (0, 0, 0))
        textIdx += 1
        img_text = addText(img_text, textIdx, 'q: exit', (0, 0, 0))
        textIdx += 1
        img_text = addText(img_text, textIdx, 'a: Last Frame', (0, 0, 0))
        textIdx += 1
        img_text = addText(img_text, textIdx, 'd: Next Frame', (0, 0, 0))
        textIdx += 1

        cv2.imshow(window_title, img_text)
        keyboard_value = cv2.waitKey(0) & 0xFF
        if keyboard_value == ord('d'):
            i_frameId = min(i_frameId + 1, len(frameIds))
        elif keyboard_value == ord('a'):
            i_frameId = max(i_frameId - 1, 0)
        elif keyboard_value == ord('q'):
            break

    print("{}_group{:0>4d} checkGroup function done.".format(dayExp, groupId))
    include_flag = input("As for {}_group{:0>4d}, should this group data be included in ourDataset? (yes/no)".format(dayExp, groupId))
    if not include_flag == "yes":
        if not os.path.exists(discard_path):
            os.mkdir(discard_path)
        despath = os.path.join(discard_path, labelInfo_path.split("/")[-1])
        if not os.path.exists(despath):
            shutil.move(labelInfo_path, despath)
        else:
            os.remove(despath)
            shutil.move(labelInfo_path, despath)



def addText(img, textIdx, text, font_color):
    font = cv2.FONT_HERSHEY_SIMPLEX
    font_size = 1.2
    # font_color = (0, 0, 255)
    line_size = 2
    x_pixel_start = 10
    x_pixel_interval = 0
    y_pixel_start = 50
    y_pixel_interval = 50

    x = x_pixel_start + textIdx * x_pixel_interval
    y = y_pixel_start + textIdx * y_pixel_interval

    img_text = cv2.putText(img, text, (x, y), font, font_size, font_color, line_size)
    return img_text


def getGroupsInfo(dayExp, dataset_path, num_frames_per_label):
    dayExp_groupId_frameId_folders = os.listdir(dataset_path)
    dayExp_groupId_frameId_folders.sort()

    df_group_frame_info = pd.DataFrame({
        "dayExp_groupId_frameId": [dayExp+"_"+item for item in dayExp_groupId_frameId_folders],
        "groupId": [int(item[5:9]) for item in dayExp_groupId_frameId_folders],
        "frameId": [int(item[15:19]) for item in dayExp_groupId_frameId_folders]
    })
    res = df_group_frame_info.groupby(["groupId"])

    df_groupsInfo = pd.DataFrame({
        "groupId": res["frameId"].count().keys().to_list(),
        "frame_length": res["frameId"].count().values.tolist(),
        "frameIds": [[frameId for frameId in range(frame_length)] for frame_length in res["frameId"].count().values.tolist()],
        "label_frame_length": [frame_length // num_frames_per_label for frame_length in res["frameId"].count().values.tolist()],
        "frameIds_to_label": [[frameId for frameId in range(0, frame_length, num_frames_per_label)] for frame_length in res["frameId"].count().values.tolist()]
    })

    print("{} getGroupInfo function done.", dayExp)
    return df_groupsInfo





if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit("python error")

    dayExp = sys.argv[1]  #"20211025_1"
    groupId = sys.argv[2]
    main(dayExp, groupId)