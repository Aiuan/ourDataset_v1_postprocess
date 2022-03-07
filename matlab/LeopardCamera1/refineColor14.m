function image_refineColor = refineColor14(img_rgb)    
    fprintf("refineColor14");
    R = img_rgb(:,:,1);
    B = img_rgb(:,:,3);
    img_rgb(:,:,1) = B;
    img_rgb(:,:,3) = R;
    [wbheight, wbwidth, ~]=size(img_rgb);
     R1=mean(mean(img_rgb(:,:,1)));
     G1=mean(mean(img_rgb(:,:,2)));
     B1=mean(mean(img_rgb(:,:,3)));
     RBmean = (R1+B1)/2;
     RGBmean = (R1+G1+B1)/3;
     
     if RBmean>0.5
         rr=0.85;   gr=0.25;   br=-0.1;
         rg=RBmean/2-0.1;   gg=1-RBmean+0.2;    bg=RBmean/2-0.1;
         rb=-0.1;    gb=0.3;   bb=0.8;
         
     else
         rr=0.85;   gr=0.25;   br=-0.1;
         rg=RBmean/2;   gg=1-RBmean;    bg=RBmean/2;
         rb=-0.1;    gb=0.3;   bb=0.8;
     end
     
    if RGBmean <= 0.1
        img_hsv = rgb2hsv(img_rgb);
        a = 5-RGBmean*30;
        img_hsv(:,:,3) = a * img_hsv(:,:,3);
        img_rgb = hsv2rgb(img_hsv);
        
    elseif RGBmean <=0.2
        img_hsv = rgb2hsv(img_rgb);
        b = 3-RGBmean*10;
        img_hsv(:,:,3) = b * img_hsv(:,:,3);
        img_rgb = hsv2rgb(img_hsv);
    end
     
     
     if G1>0.95 && RBmean>0.8
        % 亮度调节
        img_rgb = imadjust(img_rgb,[0 0 0; 1 1 1],[0 1],[2.2;2.2;2.2]);
     end
     
     
     final_img = img_rgb;
     old_img_lin = rgb2lin(final_img);
     Percentile = 10;
     illuminant = illumwhite(old_img_lin, Percentile); % 假设前 Percentile% 最亮的红色、绿色和蓝色值代表白色来 估计 RGB 图像中的场景照明
     new_img_lin = chromadapt(old_img_lin,illuminant,'ColorSpace','linear-rgb');
     final_img = lin2rgb(new_img_lin);
%      final_img = new_img;
     
     if  RGBmean>0.2 && G1<0.95 && ((G1-R1)>=(G1*0.1) || (G1-B1)>=(G1*0.1))   % 判断条件有点简单
%        final_img = dynamic_awb(myimg);
%          final_img = final_img;
         im1 = rgb2ycbcr(final_img);
         Lu=im1(:,:,1);
         Cb=im1(:,:,2);
         Cr=im1(:,:,3);
         
         tst=zeros(wbheight,wbwidth);

         % 计算Cb、Cr的均值Mb、Mr
         Mb=mean(mean(Cb));
         Mr=mean(mean(Cr));

         % 计算Cb、Cr的均方差
         Db=sum(sum(Cb-Mb))/(wbheight*wbwidth);
         Dr=sum(sum(Cr-Mr))/(wbheight*wbwidth);

         % 根据阀值的要求提取出near-white区域的像素点
         cnt=1;
         for i=1:wbheight
             for j=1:wbwidth
                 b1=Cb(i,j)-(Mb+Db*sign(Mb));
                 b2=Cr(i,j)-(1.5*Mr+Dr*sign(Mr));
                 if (b1<abs(1.5*Db) & b2<abs(1.5*Dr))
                    Ciny(cnt)=Lu(i,j);
                    tst(i,j)=Lu(i,j);
                    cnt=cnt+1;
                 end
             end
         end
         cnt=cnt-1;
         iy=sort(Ciny,'descend');%将提取出的像素点从亮度值大的点到小的点依次排列
         % 第一个参数大或第二个参数小会过曝天空发白，能改善天空发红，和场景偏绿            
         
        if G1>=0.7 
            Reference = 6-G1;
            brightness = 12+G1;
        elseif G1>=0.45
            Reference = 5-G1;
            brightness = 13+G1;        
        elseif G1>=0.3
            Reference = 4-G1;
            brightness = 12+G1; 
        else
            Reference = 3.5-G1;
            brightness = 12.5+G1; 
        end
        
        if G1-RBmean>=0.1
            Reference = 5-G1*2+(G1-RBmean)*15;
            brightness = 11+G1*2-(G1-RBmean)*15;
         end 
%          Reference = 6;
%          brightness = 10;
         nn=round(cnt/Reference);
         Ciny2(1:nn)=iy(1:nn);%提取出near-white区域中10%的亮度值较大的像素点做参考白点%

         % 提取出参考白点的RGB三信道的值
         mn=min(Ciny2);
         tst(tst<mn) = 0;
         tst(tst>=mn) = 1;
%          for i=1:x
%              for j=1:y
%                  if tst(i,j)<mn
%                     tst(i,j)=0;
%                  else
%                     tst(i,j)=1;
%                  end
%              end
%          end

         R=final_img(:,:,1);
         G=final_img(:,:,2);
         B=final_img(:,:,3);
         R=double(R).*tst;
         G=double(G).*tst;
         B=double(B).*tst; 

         % 计算参考白点的RGB的均值
         Rav=mean(mean(R));
         Gav=mean(mean(G));
         Bav=mean(mean(B));
         Ymax=double(max(max(Lu)))/brightness;%计算出图片的亮度的最大值%

         % 计算出RGB三信道的增益
         Rgain=Ymax/Rav;
         Ggain=Ymax/Gav;
         Bgain=Ymax/Bav;

         % 通过增益调整图片的RGB三信道
         final_img(:,:,1)=final_img(:,:,1)*Rgain;
         final_img(:,:,2)=final_img(:,:,2)*Ggain;
         final_img(:,:,3)=final_img(:,:,3)*Bgain;
%          final_img = final_img;
        
    end
     
   
    rgbena = [rr, gr, br; rg, gg, bg; rb, gb, bb];
   

    final_img = permute(final_img,[3,2,1]);
    final_img = reshape(final_img,[3,wbheight*wbwidth]);
    final_img = rgbena * final_img;
    final_img = reshape(final_img,[3,wbwidth,wbheight]);
    final_img = permute(final_img,[3,2,1]);
%     for i = 1:size(final_img,1)
%         for j = 1:size(final_img,2)
%             oldrgb = [final_img(i,j,1); final_img(i,j,2); final_img(i,j,3)];
%             newrgb = rgbena * oldrgb;
%             final_img(i,j,1) = newrgb(1);
%             final_img(i,j,2) = newrgb(2);
%             final_img(i,j,3) = newrgb(3);
%            
%         end
%     end
%     final_img = final_img;
    

    % 过亮处理
     R1=mean(mean(final_img(:,:,1)));
     G1=mean(mean(final_img(:,:,2)));
     B1=mean(mean(final_img(:,:,3)));
     RGBmean = (R1+G1+B1)/3;
     RGB3 = [R1 G1 B1];
     if RGBmean > 0.9 || R1>1 || G1>1 ||B1>1
        img_hsv = rgb2hsv(final_img);
        img_hsv(:,:,3) = (max(1.85-max(RGB3),0.55)) * img_hsv(:,:,3);
        final_img = hsv2rgb(img_hsv);
         
         old_img_lin = rgb2lin(final_img);
         Percentile = 10;
         illuminant = illumwhite(old_img_lin, Percentile); % 假设前 Percentile% 最亮的红色、绿色和蓝色值代表白色来 估计 RGB 图像中的场景照明
         old_img_lin = chromadapt(old_img_lin,illuminant,'ColorSpace','linear-rgb');
         final_img = lin2rgb(old_img_lin);
     end
     
    
    image_refineColor = final_img;
    

end