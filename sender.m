close all;
clear all;
clc;

%main:
[cover,FsCover] = wavread('cover.wav');
[secret,Fssecret] = wavread('secret.wav');


%sound(100*cover,FsCover);

frameSize = (10/1000)*Fssecret;% frame length= 10 ms without overlap
hfileIn = dsp.AudioFileReader('secret.wav','SamplesPerFrame', frameSize, ...
            'OutputDataType', 'double');

fileInfo = info(hfileIn);
Fs = fileInfo.SampleRate;
fftLen = 256;


numOfFrame = (length(secret)-frameSize)/frameSize; %skip 5msc from begin and end of signal
numOfFrame = round(numOfFrame);
overlap = (5/1000)*Fssecret;

diff_len = abs(length(secret)-length(cover));
if length(cover) > length(secret)
    secret = [secret(1:end) ; zeros(diff_len,1)];
else
    cover = [cover(1:end) ; zeros(diff_len,1)];
end

%window = createWindow(frameSize);
p = 10;
expi = i;


hpreemphasis = dsp.FIRFilter(...
        'Numerator', [1 -0.95]);

hbuf = dsp.Buffer(2*frameSize, frameSize);
hwindow = dsp.Window;

hacf = dsp.Autocorrelator( ...
            'MaximumLagSource', 'Property', ...
            'Scaling', 'Biased');
        
hlevinson = dsp.LevinsonSolver( ...
                'AOutputPort', true, ...
                'KOutputPort', true);
            
            
hanalysis = dsp.FIRFilter(...
                    'Structure','Lattice MA',...
                    'ReflectionCoefficientsSource', 'Input port');

hsynthesis = dsp.AllpoleFilter('Structure','Lattice AR');

hdeemphasis = dsp.AllpoleFilter('Denominator',[1 -0.95]);

haudioOut = dsp.AudioPlayer( ...
                'SampleRate', Fs, ...
                'QueueDuration', 1.0);

% Setup plots for visualization.
s = hfigslpc('setup',Fs,frameSize,fftLen);

i= 1;
all_v2s = zeros(numOfFrame*81,1);
avg_snr = 0;
while ~isDone(hfileIn)
    
 
    %.................Sender..............................
    
    sig = step(hfileIn);                         % Read audio input

    % Analysis- Determine LPC coefficients
    sigpreem = step(hpreemphasis, sig);          % Pre-emphasis
    sigwin   = step(hwindow, step(hbuf, sigpreem) );% Buffer and Window
    sigacf   = step(hacf, sigwin);               % Autocorrelation
    [sigA, sigK] = step(hlevinson, sigacf);      % Levinson-Durbin
    siglpc   = step(hanalysis, sigpreem, sigK);        % Analysis filter

    v2 = [sigK ; siglpc];
    all_v2s((i-1)*81+1:i*81) = v2(:);
    
    
    %Extract current frame from cover
    startTmp = overlap+1+(i-1)*frameSize;
    endTmp = overlap+1+i*frameSize-1;
    cover_frame = cover(startTmp-overlap : endTmp+overlap);
    
    
    
    %get DWT and FFT from cover signal
    [cA,cD] = dwt(cover_frame,'db1');
    s1 = fft(abs(cD));
    mag_s1  = abs(s1);
    phase_s1 = angle(s1);
    
    %embed secret msg parameters in the cover
    mag_s3 = abs(embed_msg(mag_s1,v2)); 
    fft_s3 = mag_s3.*exp(phase_s1*expi);

    
    %Make Stego signal
    s3 = real(ifft(fft_s3))/10000;
    stego_frame = idwt(cA,s3,'db1');
    stego_msg(startTmp-overlap : endTmp+overlap,1) = stego_frame;
    i =i+1;
    
    %step(stego_frame,10*sigout);
    %...........Receiver.....................................
    
    %.........Get IDWT......
    [cA,cD] = dwt(stego_frame,'db1');
    fft2_s3 = fft(10000*cD);
    mag2_s3  = abs(fft2_s3);
    v22 = extract_msg(mag2_s3);
    
    
    sigK = v2(1);
    siglpc = v2(2:end);
    for k=1:length(siglpc)
        if mod(k,2)~=0
            siglpc(k) = 0;
        end
    end
    
     
    %.......Synthesis.......
    hsynthesis.ReflectionCoefficients = sigK.';
    sigsyn = step(hsynthesis, siglpc);           % Synthesis filter
    sigout = step(hdeemphasis, sigsyn);          % De-emphasis
    
   
    
    avg_snr = avg_snr + 10*log10(sum(cover_frame.^2)/(sum((cover_frame-stego_frame).^2)));
    %step(haudioOut,10*sigout);
    
end
avg_snr = avg_snr/numOfFrame;
%wavplay(zeros(1,100*stego_msg),FsCover);
wavplay(10*stego_msg,FsCover);

wavwrite(stego_msg,FsCover,'stego.wav');