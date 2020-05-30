clear;


FFTsize = 1024;
ncp = 72;
ncp0 = 16;
NsymPSS = 62;                                                       %Num. of PSS seq.
NsymSSS = 62;                                                       %Num. of SSS seq.

x = load('rxdump.dat');
xReal = convertToReal(x);


%1-1. PSS detection
%finding maximal NID2 and timing
%filling up :: max_Nid, max_timing
%metric value array ( metric(NID2 trial index, timing) )

%NID2 calculation
NID2 = max_Nid
max_timing

figure(1);
plot(metric(1,:));
hold on;
plot(metric(2,:),'r');
plot(metric(3,:),'g');



%1-2. boundary calculation
%filling up :: slotBoundary 
slotBoundary


%2-1. symbol selection & compensation
%SSS OFDM symbol boundary calculation
%filling up :: SSSsym (OFDM symbol of SSS)



%2-2. frequency offset compensation (optional)




%3. FFT implementation
%filling up :: SSSsymf (FFT of SSSsym)




%4-1. subcarrier selection & equalization
%SSS symbol selection
%filling up : SSSrx


%4-2. SSS detection
%find maximal NID1 and frame boundary
%filling up : NID2, max_seq (1 or 2)

NID = 3*max_Nid + NID2
max_seq

    
%4-3. Frame boundary calculation
%filling up : frameBoundary
frameBoundary




