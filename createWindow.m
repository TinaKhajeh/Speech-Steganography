function [w] = createWindow(M)
% M is L(msec)*Fs(Hz)
%we will create a symmetric window with length 2M 
windowLength = M*2;
w = zeros(windowLength,1);
for i=0:windowLength
    if(i>=1 && i<=M/2)
        w(i)=0.54-0.46*cos((2*pi*i)/M-1);
    elseif(i>=M/2+1 && i<=(3*M/2))
        w(i)=1;
    elseif(i>=(3*M/2)+1 && i<=2*M)
        w(i)=0.54-0.46*cos((2*pi*(i-(M/2)))/(M-1));
    end
end
end