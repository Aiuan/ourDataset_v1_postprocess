import os
import glob
import shutil

ourDataset_path = '/media/ourDataset/v1.0_label'
preprocess_path = '/media/ourDataset/preprocess'
group_queries = ['20211025_1', '20211025_2', '20211026_2', '20211027_1', '20211027_2']


def log(text):
    print(text)

def log_BLUE(text):
    print('\033[0;34;40m{}\033[0m'.format(text))

def log_YELLOW(text):
    print('\033[0;33;40m{}\033[0m'.format(text))

def log_GREEN(text):
    print('\033[0;32;40m{}\033[0m'.format(text))

def log_RED(text):
    print('\033[0;31;40m{}\033[0m'.format(text))

def search_query(queries, item):
    for query in queries:
        if query in item:
            return True
    return False

def main():
    groups = os.listdir(ourDataset_path)
    groups.sort()

    for group in groups:
        if search_query(group_queries, group):
            exp = group.split('_group')[0]
            frames = os.listdir(os.path.join(ourDataset_path, group))
            frames.sort()
            for frame in frames:
                TIRadar_json_path = glob.glob(os.path.join(ourDataset_path, group, frame, 'TIRadar', '*.json'))[0]
                TIRadar_json_name = TIRadar_json_path.split('/')[-1].replace('.json', '')
                TIRadar_adc_path = os.path.join(preprocess_path, exp, 'TIRadar_adc', '{}.adcdata.bin'.format(TIRadar_json_name))
                if os.path.exists(TIRadar_adc_path):
                    des_path = TIRadar_json_path.replace('.json', '.adcdata.bin')
                    if not os.path.exists(des_path):
                        shutil.copyfile(TIRadar_adc_path, des_path)
                        log_GREEN('copy done - {}'.format(des_path))
                    else:
                        log_YELLOW('already exist - {}'.format(des_path))
                else:
                    log_RED('does not exist - {}'.format(TIRadar_adc_path))


if __name__ == '__main__':
    main()

