function mag_s3 = embed_msg(s1,v2)
 M = length(s1);
 p = length(v2)-2;
 
mag_s3 = zeros(M,1);
 

 %construct s3 by replacing s1 by v2
%mag_s3(1:M/2-p-2) = s1(1:max(M/2-p-2,0));

v3 = zeros(M/2+1,1);
j=2;
v3(1) = v2(1);
for k=2:p+2
    if mod(k,4)==1
        v3(j)= v2(k);
        if sign(v2(k))==1
            v3(j+1)= 1/10;
        end
        j = j+2;
    end
end
 
 
mag_s3(1:M/2+1) = v3(:,1);

 
mag_s3(M/2+2:M) = flipud(mag_s3(2:M/2)); %symmetric
 

end