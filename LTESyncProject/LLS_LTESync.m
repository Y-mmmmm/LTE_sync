clear;

%LTE frame structure parameters
Nslot = 20;                                                         %Num. of slots
NOFDMsym = 7;                                                       %Num. of OFDM symbols in a slot

%OFDM modulation
FFTsize = 1024;
ncp = 72;
ncp0 = 16;

%LTE PSS / SSS parameters
NsymPSS = 62;                                                       %Num. of PSS seq.
NsymSSS = 62;                                                       %Num. of SSS seq.
NsymZeroPadding = 5;                                                %Num. of 0-padding around SSs
subOffset_SS = FFTsize/2-(NsymPSS+NsymZeroPadding*2)/2 + 1;         %frequency position of the SS
symOffset_pss0 = (NOFDMsym-1)*FFTsize + subOffset_SS;               %slot 0, last OFDM symbol
symOffset_pss5 = (NOFDMsym*10+NOFDMsym-1)*FFTsize + subOffset_SS;   %slot 10, last OFDM symbol

x = load('rxdump.dat');
xReal = convertToReal(x);

%other parameters (data modulation, simulation parameters)
Qm = 2;                                                             %QPSK symbol for data
Nsym = Nslot*((FFTsize+ncp)*6+(FFTsize+ncp0));                      %number of samples
Nbit = Nsym*Qm;                                                     %number of bits to be sent


%1-1. PSS detection
%finding maximal NID2 and timing
%filling up :: max_Nid, max_timing
%metric value array ( metric(NID2 trial index, timing) )

max_timing = -1;
max_metric = -100000;
max_Nid = 0;

for testNid = 0 : 2
       PSSpattern = gen_PSS(testNid);
       timePssPattern = zeros(1, FFTsize);
       timePssPattern(subOffset_SS + NsymZeroPadding : subOffset_SS + NsymZeroPadding+NsymPSS -1) = PSSpattern;  
       timePssPattern = ifft(timePssPattern);
    
    for testTiming = 1 : Nsym-FFTsize
       metric = abs(dot(timePssPattern, xReal(testTiming: testTiming+FFTsize-1)));
        if max_metric < metric
           max_metric = metric ;
           max_timing = testTiming;
           max_Nid = testNid;
        end
    end 
end

%NID2 calculation
estimated_timing_offset = max_timing ;                          %result 1 : estimated timing of the PSS start
NID2 = max_Nid ;                                                      %result 2 : estimated NID


figure(1);
plot(abs(xReal));
hold on;
%plot(metric(2,:),'r');
%plot(metric(3,:),'g');



%1-2. boundary calculation
%filling up :: slotBoundary 

slotBoundary = Nsym/Nslot ;

%2-1. symbol selection & compensation
%SSS OFDM symbol boundary calculation
%filling up :: SSSsym (OFDM symbol of SSS)

SSSsym = xReal(estimated_timing_offset-FFTsize : estimated_timing_offset -1);

%2-2. frequency offset compensation (optional)




%3. FFT implementation
%filling up :: SSSsymf (FFT of SSSsym)

SSSsymf = fft(SSSsym, FFTsize);

%4-1. subcarrier selection & equalization
%SSS symbol selection
%filling up : SSSrx

SSSrx = SSSsymf(subOffset_SS + NsymZeroPadding : subOffset_SS + NsymZeroPadding+NsymSSS-1);


%4-2. SSS detection
%find maximal NID1 and frame boundary
%filling up : NID2, max_seq (1 or 2)

max_seq = 1;
max_metric = -100000;
max_Nid = 0;

for testNid = 0 : 167
    % - generate the original SSS sequence
    SSSpattern = gen_SSS(testNid,NID2);
    
    for seq = 1 : 2 %for two distinct sequence (slot 0 or slot 10)
        % - correlation and find the maximal sequence index
        if metric> max_metric
            max_metric = metric;
            max_Nid = testNid;
            max_seq = seq;
        end
    end
end

NID1 = max_Nid ;
NID = 3*NID1 + NID2;                                         %result 3 : eventual NID value

    
%4-3. Frame boundary calculation
%filling up : frameBoundary
if max_seq == 1
    estimated_timing_offset = estimated_timing_offset - (NOFDMsym-1)*(FFTsize+ncp);
else
    estimated_timing_offset = estimated_timing_offset - (NOFDMsym*10)*((FFTsize+ncp)*6+(FFTsize+ncp0))-(NOFDMsym-1)*(FFTsize+ncp);
end

% Because of frame strart time is estimated_timing_offset, 
% frame Boundary = start time + frame(20slot)

frameBoundary = estimated_timing_offset + Nsym; 




