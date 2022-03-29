import os
import numpy as np

adcdata_path = './data/TIRadar/1635144799.254.adcdata.bin'

adcdata = np.fromfile(adcdata_path, dtype='int16')
data = adcdata.reshape((256, 64, 16, 12, 2, 2), order='F')

subFrame0_RX0_chirp0_real = data[:, :, 0, 0, 0, 0]
subFrame0_RX0_chirp0_imag = data[:, :, 0, 0, 1, 0]
subFrame1_RX0_chirp0_real = data[:, :, 0, 0, 0, 1]
subFrame1_RX0_chirp0_imag = data[:, :, 0, 0, 1, 1]

print('done')