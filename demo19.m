img=dicomread('E:\CTLearning\s5\i000019.dcm'); 
info =dicominfo('E:\CTLearning\s5\i000019.dcm'); 

%figure,imshow(img,'DisplayRange',[]);
imgDst = img;
imgDst2 = img;

fp = fopen('07Lines.txt','w+');
%fpi = fopen('06i.txt','w+');
%fpj = fopen('06j.txt','w+');
fpe = fopen('07mape.txt','w+');
fp2 = fopen('07Lines_2.txt','w+');


center_i = 513/2;
center_j = 513/2;
oi = 1;
oj = 1;

Ra = 0;
m = 0;

% for i = 1:512
%     for j = 1:512
%         if img(i,j) > 0
%             rr = sqrt((center_i-i) ^ 2 + (center_j-j) ^ 2);
%             m = m +1;
%             if rr > Ra
%                 Ra = rr;
%                 oi = i;
%                 oj = j;
%             end
%         end
%         
%         
%     end
% end

a1 = sqrt((center_i-1) ^ 2 + (center_j-242) ^ 2);
a2 = sqrt((center_i-512) ^ 2 + (center_j-272) ^ 2);

label = zeros(512,512);



for ci = 256:-1:1
    for cj= 1:256
        if img(ci,cj) > 0
        
            break;
        end
    end
    
    k = (256 - cj) / (256 - ci);
    b = cj - k*ci;
    k2 = (256 - ci) / (256 - cj);
    b2 = ci - k2*cj;

    num = 0;
    Lines = [];
    lines_i = [];
    lines_j = [];
    
    % values of each line
    for i = ci : 256
    	for j = cj : 256
    		y1 = k * i + b;
    		y2 = k2 * j + b2;
    		dis1 = abs(y1 - j);
    		dis2 = abs(y2 - i);
    		if dis1 < 0.4 || dis2 < 0.4
    			Lines = [Lines, img(i,j)];
                fprintf(fp,'%d\t',img(i,j));
                %fprintf(fpi,'%d\t',i);
                %fprintf(fpj,'%d\t',j);
                lines_i = [lines_i, i];
                lines_j = [lines_j, j];
                num = num + 1;
    		end

    	end
    end
         
    fprintf(fp,'\n');
    
    % fit each line with y = k*exp(-x)+b
    va1 = double(Lines(3));
    va2 = double(Lines(4));
    
    L2 = double(Lines(2));
    L3 = double(Lines(3));
    L4 = double(Lines(4));
    L5 = double(Lines(5));
    L6 = double(Lines(6));
    L10 = double(Lines(10));
    L11 = double(Lines(11));
    L12 = double(Lines(12));
    L13 = double(Lines(13));
    %bias = (L5+L6) / 2;
    bias = (L11 + L10 ) /2;
    bging = (L2+L3+L4)/3;
    
    if ci == 256
        biasOld = bias;
    end
    
    coef1 = (va1-bias) / exp(-3);
    coef2 = (va2-bias) / exp(-4);
    coef = (coef1 + coef2) / 2;
    
    for in = 1:12
        ttv = int16(coef*exp(-in) + bias);
        v(in) = ttv;
    end
    
    % v2,3,4,5 percentage error
    mape = 0;
    
    for cn = 2:4
        prev = double(v(cn));
        meav = double(Lines(cn));
        mape = mape + abs(prev - meav) / meav*100;
    end
    
    mape = mape / 4;
    fprintf(fpe,'%f\n',mape);
    
    %correct bias
    %if bging > 1000
        if bias > 1260
            bias = biasOld;
        end
    
        if bias < 1100
            bias = biasOld;
        end
   % end
    
    if mape < 100 && bging>1500
        for cm = 1:12%%%%%%%%%%%%%%%%%%%
            
%             if (Lines(cm+1) - Lines(cm)) > 20 && cm > 3
%                 break;
%             end

            vaDst = bias;
%             if vaDst < 0
%                 vaDst = bias;
%             end
%             if vaDst > 2000
%                 vaDst = bias;
%             end
            
            imgDst(lines_i(cm),lines_j(cm)) = vaDst - 1*(12-cm);   %%%%%%%%
            imgDst2(lines_i(cm),lines_j(cm)) = vaDst- 1*(12-cm);    %%%%%%%%  
            label(lines_i(cm),lines_j(cm)) = label(lines_i(cm),lines_j(cm))+1;
            
%             if bias > 1270
%                 imgDst(lines_i(cm),lines_j(cm)) = img(lines_i(cm),lines_j(cm)) - coef*exp(-cm);
%                 imgDst2(lines_i(cm),lines_j(cm)) = img(lines_i(cm),lines_j(cm)) - coef*exp(-cm);
%             end
            
        end
    end
    if bging < 1500
        for ct = 1:4
            imgDst(lines_i(ct),lines_j(ct)) = imgDst(lines_i(5),lines_j(5));
            imgDst2(lines_i(ct),lines_j(ct)) = imgDst(lines_i(5),lines_j(5));
        end
    end
    
    
    for cx = 1:num
        fprintf(fp2,'%d\t',imgDst(lines_i(cx),lines_j(cx)));
    end
    fprintf(fp2,'\n');
    
    %filter unprocessed pixels
    RR = (ci-center_i)*(ci-center_i) + (cj-center_j)*(cj-center_j);
    for cm = 1:12              %%%%%%%%%%%%%%
        if lines_i(cm) > 1 && lines_j(cm) > 1 && ((lines_i(cm) -center_i)*(lines_i(cm)-center_i) + (lines_j(cm)-center_j)*(lines_j(cm)-center_j)) < RR
            if label(lines_i(cm)-1,lines_j(cm)) == 0
                imgDst2(lines_i(cm)-1,lines_j(cm)) = imgDst(lines_i(cm),lines_j(cm));
            end
            if label(lines_i(cm),lines_j(cm)-1) == 0
                imgDst2(lines_i(cm),lines_j(cm)-1) = imgDst(lines_i(cm),lines_j(cm));
            end
            if label(lines_i(cm)-1,lines_j(cm)-1) == 0
                imgDst2(lines_i(cm)-1,lines_j(cm)-1) = imgDst(lines_i(cm),lines_j(cm));
            end
        end
    end
 
    

%     coef = (va-bias) * 4*4*4;
%     for in = 1:12
%         v(in) = coef/(in*in*in) + bias;
%     end
%     L3 = Lines(3);
%     L4 = Lines(4);
%     va2 = (L3 + L4) / 2;
%     L11 = Lines(11);
%     L13 = Lines(13);
%     bias2 = (L11 + L13) / 2;
%     coef2 = (va2 - bias2) / exp(-3.5);
%     for in = 1:12
%         v2(in) = coef2*exp(-in) + bias2;
%     end
    
    biasOld = bias;
    sss = 0;
                                                                                     
    
end


%%% median filter
imgDst3 = imgDst2;

for ci = 2:255
    for cj = 2:255
        Mask = [imgDst2(ci-1,cj),imgDst2(ci+1,cj),imgDst2(ci,cj),imgDst2(ci,cj-1),imgDst2(ci,cj+1),imgDst2(ci-1,cj-1),imgDst2(ci+1,cj-1),imgDst2(ci+1,cj+1),imgDst2(ci-1,cj+1)];
        imgDst3(ci,cj) = median(Mask);
    end
end

% imgDst4 = imgDst3;
% for ci = 2:255
%     for cj = 2:255
%         Mask = [imgDst3(ci-1,cj),imgDst3(ci+1,cj),imgDst3(ci,cj),imgDst3(ci,cj-1),imgDst3(ci,cj+1),imgDst3(ci-1,cj-1),imgDst3(ci+1,cj-1),imgDst3(ci+1,cj+1),imgDst3(ci-1,cj+1)];
%         imgDst3(ci,cj) = median(Mask);
%     end
% end

dicomwrite(imgDst3,'E:\CTLearning\s5\i000019_2.dcm', 'CreateMode','Copy',info);
fclose(fp);
fclose(fp2);

