clc;
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

x = load('rxdump006.dat');
xReal = convertToReal(x);
Nsym = length(xReal);
rx_data = xReal;

%1-1. PSS detection
%finding maximal NID2 and timing
%filling up :: max_Nid, max_timing
%metric value array ( metric(NID2 trial index, timing) )

max_timing0 = -1;
max_metric0_f = -100000;

max_timing1 = -1;
max_metric1_f = -100000;

max_timing2 = -1;
max_metric2_f = -100000;


for testNid = 0
        seq_PSS = gen_PSS(testNid); % - generate PSS sequence
        %mapping to RE
        sym_receive = zeros(1,FFTsize); 
        sym_receive(FFTsize - NsymPSS/2  +1 : FFTsize) = seq_PSS(1:31); 
        sym_receive(2 : 2 + NsymPSS/2 - 1) = seq_PSS(32:62);
        symifft = ifft(sym_receive);
        
        % cross correlation between the generated wave and the rx_demod
        
        for testTiming = 1 : Nsym - FFTsize
            max_PSS0(testNid+1,testTiming) = abs( dot(symifft, rx_data(testTiming : testTiming + FFTsize -1)));
            
            if max_metric0_f < max_PSS0(testNid+1,testTiming)
                max_timing0 = testTiming;
                max_metric0_f = max_PSS0(testNid+1,testTiming);
            end
        end      
end

if max_timing0 < 76800
    max_metric0_b = max_PSS0(testNid+1,max_timing0+76800) ;
else
    max_metric0_b = max_PSS0(testNid+1,max_timing0-76800) ;
end

PSS0 = (max_metric0_f + max_metric0_b)/2 ;
 
for testNid = 1
        seq_PSS = gen_PSS(testNid); % - generate PSS sequence
        %mapping to RE
        sym_receive = zeros(1,FFTsize); 
        sym_receive(FFTsize - NsymPSS/2  +1 : FFTsize) = seq_PSS(1:31); 
        sym_receive(2 : 2 + NsymPSS/2 - 1) = seq_PSS(32:62);
        symifft = ifft(sym_receive);
        
        % cross correlation between the generated wave and the rx_demod
        
        for testTiming = 1 : Nsym - FFTsize
            max_PSS1(testNid+1,testTiming) = abs( dot(symifft, rx_data(testTiming : testTiming + FFTsize -1)));
            
            if max_metric1_f < max_PSS1(testNid+1,testTiming)
                max_timing1 = testTiming;
                max_metric1_f = max_PSS1(testNid+1,testTiming);
            end
        end      
end

if max_timing1 < 76800
    max_metric1_b = max_PSS1(testNid+1,max_timing1+76800) ;
else
    max_metric1_b = max_PSS1(testNid+1,max_timing1-76800) ;
end

PSS1 = (max_metric1_f + max_metric1_b)/2 ;

for testNid = 2
        seq_PSS = gen_PSS(testNid); % - generate PSS sequence
        %mapping to RE
        sym_receive = zeros(1,FFTsize); 
        sym_receive(FFTsize - NsymPSS/2  +1 : FFTsize) = seq_PSS(1:31); 
        sym_receive(2 : 2 + NsymPSS/2 - 1) = seq_PSS(32:62);
        symifft = ifft(sym_receive);
        
        % cross correlation between the generated wave and the rx_demod
        
        for testTiming = 1 : Nsym - FFTsize
            max_PSS2(testNid+1,testTiming) = abs( dot(symifft, rx_data(testTiming : testTiming + FFTsize -1)));
            
            if max_metric2_f < max_PSS2(testNid+1,testTiming)
                max_timing2 = testTiming;
                max_metric2_f = max_PSS2(testNid+1,testTiming);
            end
        end      
end

if max_timing2 < 76800
    max_metric2_b = max_PSS2(testNid+1,max_timing2+76800) ;
else
    max_metric2_b = max_PSS2(testNid+1,max_timing2-76800) ;
end

PSS2 = (max_metric2_f + max_metric2_b)/2 ;


if (PSS0 > PSS1)&& (PSS0 > PSS2)
    estimatedNID2 = 0;
    estimated_timing_offset = max_timing0 ;
end

if (PSS1> PSS0)&& (PSS1 > PSS2)
    estimatedNID2 = 1;
    estimated_timing_offset = max_timing1 ;
end

if (PSS2> PSS0)&& (PSS2 > PSS1)
    estimatedNID2 = 2;
    estimated_timing_offset = max_timing2 ;
end


figure(1);
plot(abs(max_PSS0(1,:)) );
hold on;
plot(abs(max_PSS1(2,:)),'r');
plot(abs(max_PSS2(3,:)),'g');
hold off;



%1-2. boundary calculation
%filling up :: slotBoundary ////////

%SSS detection
max_seq = 1;
max_metric = -100000;
max_Nid = 0;

%2-1. symbol selection & compensation
SSSsym = rx_data(estimated_timing_offset - FFTsize - ncp  : estimated_timing_offset - ncp -1);  %SSS OFDM symbol boundary calculation

%2-2. frequency offset compensation (optional)



%3. FFT implementation
SSSsymf = fft(SSSsym, FFTsize);


%4-1. subcarrier selection & equalization
SSSrx = [];
SSSrx= [SSSsymf(FFTsize - NsymSSS/2  +1 : FFTsize) SSSsymf(2 : 2 + NsymPSS/2 - 1)];   %SSS symbol selection

%4-2. SSS detection
for testNid = 0 : 167
    % - generate the original SSS sequence
    seq_SSS = gen_SSS(testNid,estimatedNID2);
    
     % - correlation and find the maximal sequence index
    for seq = 1 : 2
        max_value = abs( dot(SSSrx, seq_SSS(seq,:)));  
        if max_metric <  max_value
            max_metric = max_value;
            max_Nid = testNid;
            max_seq = seq;
        end
     end
end

NID1 = max_Nid
NID2 = estimatedNID2
estimatedNID = NID1*3 + NID2

%4-3. Frame boundary calculation
%filling up : frameBoundary
if max_seq == 1
    estimated_timing_offset = estimated_timing_offset - ((NOFDMsym-2)*(FFTsize+ncp) + (ncp+ncp0+FFTsize) + ncp);
    if estimated_timing_offset < 0
       frameBoundary = estimated_timing_offset+(Nslot)*((FFTsize+ncp)*7+ncp0);
   else
       frameBoundary = estimated_timing_offset ;
   end
else
    estimated_timing_offset = estimated_timing_offset - ((NOFDMsym*10)+(NOFDMsym-1))*FFTsize - ((ncp*11*(NOFDMsym-1))+(ncp+ncp0)*11 + (FFTsize+ncp)*7 +ncp0);
     if estimated_timing_offset < 0
       frameBoundary = estimated_timing_offset+(Nslot)*((FFTsize+ncp)*7+ncp0);
   else
       frameBoundary = estimated_timing_offset ;
   end
end 

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
        metric = abs( dot(SSSrx, seq_SSS(seq,:))); 
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




