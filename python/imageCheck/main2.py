import os
import cv2
import xlrd, xlwt

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



def imageCheck(image_folder, startTimestamp=None, xls=None):
    # create xls
    workbook = xlwt.Workbook(encoding='ascii')
    worksheet = workbook.add_sheet('dataset')
    worksheet.write(0,0, 'Start Timestamp')
    worksheet.write(0,1, 'End Timestamp')
    worksheet.write(0,2, 'Degree of Exposure')
    worksheet.write(0,3, 'Chromatic Aberration')
    worksheet.write(0,4, 'Color Jump')
    worksheet.write(0,5, 'Density of Car')
    worksheet.write(0,6, 'Density of Motor')
    worksheet.write(0,7, 'Density of Pedestrian')
    xls_idx = 1

    image_list = os.listdir(image_folder)
    image_list.sort(key=lambda x: float(x.split('.png')[0]))
    num_image = len(image_list)
    cv2.namedWindow(image_folder, cv2.WINDOW_NORMAL | cv2.WINDOW_KEEPRATIO)
    # cv2.namedWindow(image_folder, cv2.WINDOW_FULLSCREEN | cv2.WINDOW_KEEPRATIO)
    cv2.resizeWindow(image_folder, 1500, 800)
    i = 0
    isVedioMode = False
    if startTimestamp != None:
        isContinue = True

    record = False

    while (i < num_image and i >= 0):
        image_name = image_list[i]
        image_path = os.path.join(image_folder, image_name)
        # print("{}/{}  Path: {}".format(i + 1, num_image, image_path))
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
        try:
            img_shape = img.shape
        except:
            print('Problem image path = '+image_path)
            # isVedioMode = False
        else:
            img_text = img
            textIdx = 0
            img_text = addText(img_text, textIdx, 'FrameIdx: {}'.format(i + 1))
            textIdx += 1
            img_text = addText(img_text, textIdx, 'Timestamp: {:.3f}'.format(curTimestamp))
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

            # record begin
            if keyboard_value == ord('r') and not record:
                print('========Record Begin========')
                record = True
                bgn_time = str(curTimestamp)
            # record stop
            if keyboard_value == ord('s') and record:
                print('Record Stop: ')
                record = False
                stp_time = str(curTimestamp)
                exp = input('The degree of exposure (-0/0.5/1+): ')
                abe = input('The chromatic aberration(R/G/B): ')
                col = input('The color jump(y/n): ')
                car = input('The density of Car(0/5/10/10+): ')
                mot = input('The density of Motorcycle(0/5/10/10+): ')
                ped = input('The density of Pedestrian(0/5/10/10+): ')
                note = input('Note that: ')
                worksheet.write(xls_idx, 0, bgn_time)
                worksheet.write(xls_idx, 1, stp_time)
                worksheet.write(xls_idx, 2, exp)
                worksheet.write(xls_idx, 3, abe)
                worksheet.write(xls_idx, 4, col)
                worksheet.write(xls_idx, 5, car)
                worksheet.write(xls_idx, 6, mot)
                worksheet.write(xls_idx, 7, ped)
                worksheet.write(xls_idx, 8, note)
                xls_idx += 1
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

            # record begin
            if keyboard_value == ord('r') and not record:
                print('========Record Begin========')
                record = True
                bgn_time = curTimestamp
            # record stop
            if keyboard_value == ord('s') and record:
                print('Record Stop: ')
                record = False
                stp_time = curTimestamp
                exp = input('The degree of exposure (-0/0.5/1+): ')
                abe = input('The chromatic aberration(R/G/B): ')
                col = input('The color jump(y/n): ')
                car = input('The density of Car(0/5/10/10+): ')
                mot = input('The density of Motorcycle(0/5/10/10+): ')
                ped = input('The density of Pedestrian(0/5/10/10+): ')
                note = input('Note that: ')
                worksheet.write(xls_idx, 0, bgn_time)
                worksheet.write(xls_idx, 1, stp_time)
                worksheet.write(xls_idx, 2, exp)
                worksheet.write(xls_idx, 3, abe)
                worksheet.write(xls_idx, 4, col)
                worksheet.write(xls_idx, 5, car)
                worksheet.write(xls_idx, 6, mot)
                worksheet.write(xls_idx, 7, ped)
                worksheet.write(xls_idx, 8, note)
                xls_idx += 1


    cv2.destroyAllWindows()

    workbook.save(xls)


if __name__ == '__main__':
    image_folder = '/media/ourDataset/preprocess/20211028_2/LeopardCamera1/'
    # startTimestamp = 1635663472.97534
    # imageCheck(image_folder, startTimestamp)
    imageCheck(image_folder, startTimestamp=1635419067, xls='20211028_2.xls')
