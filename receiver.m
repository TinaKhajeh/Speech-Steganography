close all;
clear all;
clc;

frameSize = 160;
fftLen = 256;
hfileIn = dsp.AudioFileReader('secret.wav','SamplesPerFrame', frameSize, ...
            'OutputDataType', 'double');

fileInfo = info(hfileIn);
Fs = fileInfo.SampleRate;
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
secret_msg = [];
while ~isDone(hfileIn)
    sig = step(hfileIn);                         % Read audio input

    % Analysis
    % Note that the filter coefficients are passed in as an argument to the
    % step method of the hanalysis filter System object.
    sigpreem = step(hpreemphasis, sig);          % Pre-emphasis
    sigwin   = step(hwindow, step(hbuf, sigpreem));% Buffer and Window
    sigacf   = step(hacf, sigwin);               % Autocorrelation
    [sigA, sigK] = step(hlevinson, sigacf);      % Levinson-Durbin
    siglpc   = step(hanalysis, sigpreem, sigK);        % Analysis filter

    % Synthesis
    sigK = sigK';
    hsynthesis.ReflectionCoefficients = sigK;
    for k=1:length(siglpc)
        if mod(k,2)~=0
            siglpc(k) = 0;
        end
    end
    
    sigsyn = step(hsynthesis, siglpc);           % Synthesis filter
    sigout = step(hdeemphasis, sigsyn);          % De-emphasis

    step(haudioOut, 10*sigout);                     % Play output audio

     secret_msg = [secret_msg; sigout];
    % Update plots
    %s = plotlpcdata(s, sigA, sigwin);
end

wavwrite(secret_msg,Fs,'constructed.wav');
release(hfileIn);
pause(haudioOut.QueueDuration);    % Wait until audio finishes playing
release(haudioOut);
hfigslpc('cleanup',s);
