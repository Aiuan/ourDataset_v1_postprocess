import os
import cv2

def addText(img, textIdx, text):
    font = cv2.FONT_HERSHEY_SIMPLEX
    font_size = 1.2
    font_color = (0, 0, 255)
    line_size = 2
    x_pixel_start = 10
    x_pixel_interval = 0
    y_pixel_start = 50
    y_pixel_interval = 50

    x = x_pixel_start + textIdx * x_pixel_interval
    y = y_pixel_start + textIdx * y_pixel_interval

    img_text = cv2.putText(img, text, (x, y), font, font_size, font_color, line_size)
    return img_text



def imageCheck(image_folder, startTimestamp=None):
    image_list = os.listdir(image_folder)
    image_list.sort(key=lambda x: float(x.split('.png')[0]))
    num_image = len(image_list)
    cv2.namedWindow(image_folder, cv2.WINDOW_NORMAL | cv2.WINDOW_KEEPRATIO)

    i = 0
    isVedioMode = True
    if startTimestamp != None:
        isContinue = True

    while (i < num_image and i >= 0):
        image_name = image_list[i]
        image_path = os.path.join(image_folder, image_name)
        print("{}/{}  Path: {}".format(i + 1, num_image, image_path))
        curTimestamp = float(image_name.split('.png')[0])

        if startTimestamp != None:
            if curTimestamp < startTimestamp:
                i = min(i+1, num_image)
                continue
            if isContinue:
                isContinue = False
                print("=====================================================")
                print("Below is images whose timestamp > {}".format(startTimestamp))
                print("Press any key to contiue...")
                cv2.waitKey(0)

        img = cv2.imread(image_path, cv2.IMREAD_COLOR)

        img_text = img
        textIdx = 0
        img_text = addText(img_text, textIdx, 'FrameIdx: {}'.format(i + 1))
        textIdx += 1
        img_text = addText(img_text, textIdx, 'Timestamp: {}'.format(curTimestamp))
        textIdx += 1
        img_text = addText(img_text, textIdx, 'isVedioMode: {}'.format(isVedioMode))
        textIdx += 1
        img_text = addText(img_text, textIdx, 'Keyboard help:')
        textIdx += 1
        img_text = addText(img_text, textIdx, '    q: exit')
        textIdx += 1
        img_text = addText(img_text, textIdx, '    space: switch VedioMode/FrameMode')
        textIdx += 1
        img_text = addText(img_text, textIdx, '    in FrameMode:')
        textIdx += 1
        img_text = addText(img_text, textIdx, '        a: Last Frame')
        textIdx += 1
        img_text = addText(img_text, textIdx, '        d: Next Frame')
        textIdx += 1

        cv2.imshow(image_folder, img_text)
        if isVedioMode:
            i = min(i+1, num_image)
            keyboard_value = cv2.waitKey(25) & 0xFF
            if keyboard_value == ord(' ') or keyboard_value == ord('a') or keyboard_value == ord('d'):
                isVedioMode = not isVedioMode
            elif keyboard_value == ord('q'):
                break
        else:
            keyboard_value = cv2.waitKey(0) & 0xFF
            if keyboard_value == ord('d'):
                i = min(i+1, num_image)
            elif keyboard_value == ord('a'):
                i = max(i-1, 0)
            elif keyboard_value == ord(' '):
                isVedioMode = not isVedioMode
            elif keyboard_value == ord('q'):
                break

    cv2.destroyAllWindows()



if __name__ == '__main__':
    image_folder = '/media/ourDataset/preprocess/20211031_2/LeopardCamera1'
    startTimestamp = 1635671002.019
    imageCheck(image_folder, startTimestamp)