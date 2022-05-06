clear all; close all; clc;

load('./input/256x64.mat');

calibdata = struct();
calibdata.Slope_MHzperus = params.Slope_MHzperus;
calibdata.Sampling_Rate_sps = params.Sampling_Rate_sps;
calibdata.AngleMat = calibResult.AngleMat;
calibdata.RangeMat = calibResult.RangeMat;
calibdata.PeakValMat = calibResult.PeakValMat;
calibdata.RxMismatch = calibResult.RxMismatch;
calibdata.TxMismatch = calibResult.TxMismatch;
calibdata.Rx_fft = calibResult.Rx_fft;

savejson('', calibdata, 'FileName', './runs/calibdata.json');