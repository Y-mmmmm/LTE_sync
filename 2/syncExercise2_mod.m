clear;

%Parameter setting ------------------------------------
%baseband parameters
Nbit = 4800;                    %number of bits to send
Snr = 30;                       %signal to noise ratio, dB

Qm = 2;                         %2 - QPSK, 4 - 16QAM, 6 - 64QAM

%OFDM modulation
FFTsize = 0;                    %OFDM parameter (0 : no OFDM modulation)
ncp = 2;                        %cyclic prefix
fftOffset = 2;                  %sample offset for FFT process


%RF parameters
fs = 100;                       %baseband signal sample rate
fc = 10^4;                      %carrier frequency
freqOffset = 0.03;                 %frequency offset (unit : %)
Noversample = 8;                %oversampling rate (sample -> RF phase)
Tsample = 1/fc/Noversample;     %RF sample duration
rate_LowPass = 1/256;            %Low pass ratio
N_hLowPass = 4096;              %IFFT point of the low pass filter




%TX Process ---------------------------------------------------------------

%1. bit generation (random) ------------------------------ 
bit_send = randi(2,1,Nbit) - ones(1,Nbit);


%2. modulation (bit to IQ signal) ------------------------ 
if Qm == 2 % --- QPSK
    Nsym = Nbit/Qm;
    sym_mapper = [1+i 1-i -1+i -1-i]/sqrt(2);
    
elseif Qm == 4 % --- 16QAM
    %Nsym = ;
    %sym_mapper = %TS 36.211 7.1.3   
    
elseif Qm == 6 % - 64QAM
    %Nsym = ;
    %sym_mapper = %TS 36.211 7.1.3
    
else % regard as QPSK
    printf("Qm is weird! setting Qm as 2...\n");
    Qm = 2;
    Nsym = Nbit/Qm;
    sym_mapper = [1+i 1-i -1+i -1-i]/sqrt(2);    
end

%symbol generation
symf_send = zeros(1,Nsym);
for k = 1 : Nsym
    symf_send(k) = sym_mapper(bin2dec(num2str(bit_send(Qm*(k-1)+1:Qm*k)))+1 );
end 


%3. OFDM modulation ----------------------------------------
if FFTsize > 0
    sym_send = [];
    for k = 1 : Nsym/FFTsize
        OFDM_mod = ifft(symf_send((k-1)*FFTsize + 1 : k*FFTsize));
        sym_send = [sym_send OFDM_mod((FFTsize-ncp+1):FFTsize) OFDM_mod];
    end
    NOfdmSym = Nsym/FFTsize*(FFTsize+ncp);
else
    sym_send = symf_send;
    NOfdmSym = Nsym;
end




% [[[[[[[[[[ ========= RF ========== ]]]]]]]]]]

%4. RF modulation ----------------------------------------
t_sim = [Tsample : Tsample : NOfdmSym/fs];
%  -- 3.1 IQ reconstruction
sym_oversample = [];
Nsample_sym = fc/fs*Noversample;
for k = 1 : NOfdmSym
    sym_oversample = [sym_oversample sym_send(k)*ones(1,Nsample_sym)];
end
%  -- 3.2 RF signal generation (product modulator)
RF_I = real(sym_oversample).*cos(2*pi*fc*t_sim);
RF_Q = imag(sym_oversample).*sin(2*pi*fc*t_sim);
RF_signal = RF_I - RF_Q;






%Channel ------------------------------------------------------------------

%1. AWGN Noise insertion
N0 = randn(1,length(t_sim))/10^(Snr/10);
Rx_signal = RF_signal + N0;






%RX Process ---------------------------------------------------------------

%0. Low Pass Filter generation--------------------------
hLowPass = ifft([ones(1,N_hLowPass*rate_LowPass) zeros(1,N_hLowPass*(1-2*rate_LowPass)) ones(1,N_hLowPass*rate_LowPass)]);
hLowPass = [hLowPass(N_hLowPass/2+1:N_hLowPass) hLowPass(1:N_hLowPass/2)];


%1. RF signal demodulation------------------------------
% -- 1.1 I channel
rx_I = Rx_signal .* cos(2*pi*fc*(1+freqOffset/100)*t_sim);
% -- 1.2 Q channel
rx_Q = Rx_signal .* sin(2*pi*fc*(1+freqOffset/100)*t_sim);


% -- 1.3 low pass filter
conv_offset = length(hLowPass)/2;
rx_I_filtered = conv(rx_I, hLowPass);
rx_I_filtered = rx_I_filtered(1+conv_offset:length(rx_I)+conv_offset);
rx_Q_filtered = conv(rx_Q, hLowPass);
rx_Q_filtered = rx_Q_filtered(1+conv_offset:length(rx_Q)+conv_offset);
%  -- 1.4 baseband conversion
rx_demod_filtered = rx_I_filtered - rx_Q_filtered*i;



%2. frequency offset compensation-----------------------
rx_demod_comp = rx_demod_filtered .* exp(i*2*pi*fc*freqOffset/100*t_sim);

% [[[[[[[[[[ ========= RF ========== ]]]]]]]]]]





%3. symbol hard decision (symbol to bit)----------------
% -- 3.1 sampling & gain compensation
gainComp = abs(mean(sym_oversample))./abs( mean(rx_demod_comp) );
for k=1:NOfdmSym
    rx_sym(k) = median(rx_demod_comp((k-1)*Nsample_sym+1 : k*Nsample_sym ))*gainComp;
end



% -- 3.2 OFDM demodulation
if FFTsize > 0
    %rxf_sym = [];
else
    rxf_sym = rx_sym;
end

figure(1);
scatter(real(rxf_sym), imag(rxf_sym));
axis([-1.2 1.2 -1.2 1.2]);
grid on;

%  -- 3.3 symbol demapping (complex number -> bits)
bit_rcv = [];
for k1=1:Nsym
        
    min_index = -1;
    min_value = 1000;
    
    %minimum distance calculation
    for k2 = 1:length(sym_mapper)
        tmp_value = abs(rxf_sym(k1) - sym_mapper(k2));
        if min_value > tmp_value
            min_index = k2;
            min_value = tmp_value;
        end
    end
    
    %bit conversion
    for k2 = 1 : Qm
        if bitand((min_index-1), 2^(Qm-k2)) > 0
            bit_rcv((k1-1)*Qm + k2) = 1;
        else
            bit_rcv((k1-1)*Qm + k2) = 0;
        end
    end
end

%Analysis -----------------------------------
%1. bit error detection (compare sent bits & received bits)
bit_error = sum(abs(bit_send - bit_rcv))/Nbit



