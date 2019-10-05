function v2 = LPC_parameters(x,p,fs)

frameSize = 1600;
fftLen = 2048;
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
            'MaximumLag', 12, ...
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

while ~isDone(hfileIn)
    sig = step(hfileIn);                         % Read audio input

    % Analysis
    % Note that the filter coefficients are passed in as an argument to the
    % step method of the hanalysis filter System object.
    sigpreem = step(hpreemphasis, sig);          % Pre-emphasis
    sigwin   = step(hwindow, step(hbuf, sigpreem) );% Buffer and Window
    sigacf   = step(hacf, sigwin);               % Autocorrelation
    [sigA, sigK] = step(hlevinson, sigacf);      % Levinson-Durbin
    siglpc   = step(hanalysis, sigpreem, sigK);        % Analysis filter

    % Synthesis
    hsynthesis.ReflectionCoefficients = sigK.';
    sigsyn = step(hsynthesis, siglpc);           % Synthesis filter
    sigout = step(hdeemphasis, sigsyn);          % De-emphasis

    step(haudioOut, sigout);                     % Play output audio

    % Update plots
    s = plotlpcdata(s, sigA, sigwin);
end

release(hfileIn);
pause(haudioOut.QueueDuration);    % Wait until audio finishes playing
release(haudioOut);
hfigslpc('cleanup',s);

end
