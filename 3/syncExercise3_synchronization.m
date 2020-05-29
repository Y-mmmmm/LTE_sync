clear;


%LTE cell parameters ----------------------------------
timing_offset = -200;                                 %timing offset
NID = 355;                                          %Physical Cell ID
Snr = 20;                                           %signal to noise ratio, dB
freqOffset = 0;                                     %frequency offset (unit : %)


%Other system parameters --- ((should be fixed)) ------

%LTE frame structure parameters
Nslot = 20;                                         %Num. of slots
NOFDMsym = 7;                                       %Num. of OFDM symbols in a slot
FFTsize = 1024;                                     %FFT size (10MHz)

%LTE PSS / SSS parameters
NsymPSS = 62;                                                       %Num. of PSS seq.
NsymSSS = 62;                                                       %Num. of SSS seq.
NsymZeroPadding = 5;                                                %Num. of 0-padding around SSs
subOffset_SS = FFTsize/2-(NsymPSS+NsymZeroPadding*2)/2 + 1;         %frequency position of the SS
symOffset_pss0 = (NOFDMsym-1)*FFTsize + subOffset_SS;               %slot 0, last OFDM symbol
symOffset_pss5 = (NOFDMsym*10+NOFDMsym-1)*FFTsize + subOffset_SS;   %slot 10, last OFDM symbol


%other parameters (data modulation, simulation parameters)
Qm = 2;                                             %QPSK symbol for data
Nsym = FFTsize*NOFDMsym*(Nslot+2);                  %number of samples
Nbit = Nsym*Qm;                                     %number of bits to be sent



%RF parameters
rate_LowPass = 3/20;            %Low pass ratio
Noversample = 8;                %oversampling rate
RFfreq = 2*pi/Noversample;      %RF frequency (rad)


%TX Process ---------------------------------
% Filling random data (QPSK) and then fill the synchronization signal

%1. random bit generation
bit_send = randi(2,1,Nbit) - ones(1,Nbit);


%2. modulation (QPSK mapper)------------------------ 
Nsym = Nbit/Qm;                             % number of symbols determination
sym_mapper = [1+i 1-i -1+i -1-i]/sqrt(2);   %symbol mapper definition (Table in TS 36.211) 

%symbol mappging
sym_send = zeros(1,Nsym);
for k = 1 : Nsym
    sym_send(k) = sym_mapper(bin2dec(num2str(bit_send(Qm*(k-1)+1:Qm*k)))+1 );
end



%3. synch signal insertion
%Calculating NID1, 2
NID2 = mod(NID,3);
NID1 = (NID-NID2)/3;

%PSS generation
sig_PSS = gen_PSS(NID2);
%mapping to RE
sym_send(symOffset_pss0 : symOffset_pss0+(NsymPSS+2*NsymZeroPadding)-1 ) = [zeros(1,NsymZeroPadding) sig_PSS zeros(1,NsymZeroPadding)];
sym_send(symOffset_pss5 : symOffset_pss5+(NsymPSS+2*NsymZeroPadding)-1 ) = [zeros(1,NsymZeroPadding) sig_PSS zeros(1,NsymZeroPadding)];

%SSS generation
[sig_SSS] = gen_SSS(NID1, NID2);
%mapping to RE
symOffset_sss0 = symOffset_pss0 - FFTsize;
symOffset_sss5 = symOffset_pss5 - FFTsize;
sym_send(symOffset_sss0 : symOffset_sss0+(NsymSSS+2*NsymZeroPadding)-1 ) = [zeros(1,NsymZeroPadding) sig_SSS(1,:) zeros(1,NsymZeroPadding)];
sym_send(symOffset_sss5 : symOffset_sss5+(NsymSSS+2*NsymZeroPadding)-1 ) = [zeros(1,NsymZeroPadding) sig_SSS(2,:) zeros(1,NsymZeroPadding)];



%4. OFDM modulation (IFFT)
if FFTsize > 0
    symf_send = [];
    for k = 1 : Nsym/FFTsize
        symf_send = [symf_send ifft(sym_send((k-1)*FFTsize + 1 : k*FFTsize))];
    end
end


%5 timing offset insertion (wrap around)
%inserting 1 slot + timing offset at the front
N1slotSym = FFTsize*NOFDMsym+timing_offset;
symf_send = [symf_send(Nsym-N1slotSym+1:Nsym) symf_send(1:Nsym-N1slotSym)];

%printing the actual timing of the frame boundary
timing_offset_insertion = timing_offset + 1 + FFTsize*NOFDMsym






%Channel modeling ---------------------------------

%1. AWGN Noise insertion
N0 = randn(1,Nsym)/(10^(Snr/10));
rx_demod = symf_send + N0;

%2. frequency offset insertion
n = 1:Nsym;
rx_demod = rx_demod .* exp(i*RFfreq*freqOffset/100*n);







%RX Process -------------------------
%1. frequency offset compensation
%rx_sym = rx_demod .* exp(-i*RFfreq*freqOffset/100*n);

%PSS detection
max_timing = -1;
max_metric = -100000;
max_Nid = 0;
for testNid = 0 : 2
    %prob.1 :: Generate OFDM modulated wave of the i'th PSS sequence 
    % - generate PSS sequence
    % gen_PSS
    % - OFDM modulation
    
    
    
    
    %prob.2 :: cross correlation between the generated wave and the rx_demod
    for testTiming = 1 : Nsym-FFTsize
        %find the maximal point of the correlation value
        
        
        
    end
end

estimated_timing_offset = max_timing; %result 1 : estimated timing of the PSS start
estimatedNID2 = max_Nid;              %result 2 : estimated NID

%SSS detection
max_seq = 1;
max_metric = -100000;
max_Nid = 0;

%prob.3 :: demodulate the received part of the SSS sequences
% - sample selection
% - OFDM demodulation
% - subcarrier selection

     SSSsymOffset = PSSsymOffset - FFTsize ;
     RXsss = RXdata[SSSsymOffset : +FFTsize-1] ;
     RXsss = FFT(RXsss) ;
     FsssOffset = FFTsize/2 - Nsss/2 -1: +61 ;


%prob.4 :: correlation of the SSS
for testNid = 0 : 167
    % - generate the original SSS sequence
    SSSseq = gen_SSS()
    
    for seq = 1 : 2 %for two distinct sequence (slot 0 or slot 10)
        % - correlation and find the maximal sequence index
    end
end

estimatedNID = max_Nid*3 + estimatedNID2 %result 3 : eventual NID value

%result 4 : finding the eventual frame boundary
if max_seq == 1
    estimated_timing_offset = estimated_timing_offset - (NOFDMsym-1)*FFTsize
else
    estimated_timing_offset = estimated_timing_offset - (NOFDMsym*10+NOFDMsym-1)*FFTsize
end


