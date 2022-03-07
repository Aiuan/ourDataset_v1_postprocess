function img_rgb = raw2rgb2(path, r_gain, g_gain, b_gain)
    width = 2880;
    height = 1860;
    num_bit = 12;
    num_byte =((num_bit - 1) / 8 + 1);
    
    fid = fopen(path ,"r");
    data = fread(fid, width*height, 'uint16');
    fclose(fid);
    
    img = reshape(data, width, height);
    img = img';
    img = img / max(max(img)) * 255;
    img = uint8(floor(img));
    
    img_rgb = demosaic(img,'bggr');
    r = img_rgb(:, :, 1) * r_gain;
    g = img_rgb(:, :, 2) * g_gain;
    b = img_rgb(:, :, 3) * b_gain;

    img_rgb(:, :, 1) = r;
    img_rgb(:, :, 2) = g;
    img_rgb(:, :, 3) = b;

    img_rgb = im2double(img_rgb);
end