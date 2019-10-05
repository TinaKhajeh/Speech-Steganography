function lsf_co = lpc_analysis(x,p)

[lpc_co,] = lpc(x,p); %determine LPC coefficients
H = dsp.LPCToLSF;
lsf_co = step(H,lpc_co'); %convert LPC to LSF
end
