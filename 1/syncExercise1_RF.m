clear;

%Parameter setting ------------------------------------
Nbit = 1000;                    %number of bits to send
Snr = 10;                       %signal to noise ratio, dB
freqOffset = 0.03;              %frequency offset (unit : %)
fc = 10^4;                      %carrier frequency
fs = 100;                       %baseband rate

%other parameters (should be fixed)
Noversample = 8;                %oversampling rate
Tsample = 1/fc/Noversample;     %sample duration

rate_LowPass = 1/50;            %Low pass ratio
Nplot = 4;                      %number of plots


%TX Process ---------------------------------

%1. bit generation (random)
bit_send = randi(2,1,Nbit) - ones(1,Nbit);

%2. modulation (I Q signal generation)
Nsym = Nbit/2;
QPSK_mapper = [1+i 1-i -1+i -1-i]/sqrt(2);
sym_send = zeros(1,Nsym);
for k = 1 : Nsym
    sym_send(k) = QPSK_mapper(2*bit_send(2*k) + bit_send(2*k-1) + 1 );
end


%3. RF modulation
t_sim = [Tsample : Tsample : Nsym/fs];
%  -- 3.1 IQ reconstruction
sym_oversample = [];
Nsample_sym = fc/fs*Noversample;
for k = 1 : Nsym
    sym_oversample = [sym_oversample sym_send(k)*ones(1,Nsample_sym)];
end
%  -- 3.2 RF signal generation (product modulator)
RF_I = real(sym_oversample).*cos(2*pi*fc*t_sim);
RF_Q = imag(sym_oversample).*sin(2*pi*fc*t_sim);
RF_signal = RF_I - RF_Q;






%Channel ---------------------------------

%1. AWGN Noise insertion
N0 = randn(1,length(t_sim))/10^(Snr/10);
Rx_signal = RF_signal + N0;







%RX Process -------------------------

%0. Low Pass Filter generation
hLowPass = ifft([ones(1,length(t_sim)*rate_LowPass) zeros(1,length(t_sim)*(1-2*rate_LowPass)) ones(1,length(t_sim)*rate_LowPass)]);


%1. RF signal demodulation (frequency offset exists, RF signal -> baseband
%signal)
%  -- 1.1 I channel
rx_I = Rx_signal .* cos(2*pi*fc*(1+freqOffset/100)*t_sim);
%  -- 1.2 Q channel
rx_Q = Rx_signal .* sin(2*pi*fc*(1+freqOffset/100)*t_sim);


%2. low pass filter
rx_I_filtered = conv(rx_I, hLowPass);
rx_I_filtered = rx_I_filtered(1:length(rx_I));
rx_Q_filtered = conv(rx_Q, hLowPass);
rx_Q_filtered = rx_Q_filtered(1:length(rx_Q));

%baseband representation
rx_demod_filtered = rx_I_filtered - rx_Q_filtered*i;

%3. frequency offset compensation : should be modified!!
rx_demod_comp = rx_demod_filtered;


%4. symbol detection (symbol to bit)
%  -- 4.1 sampling
for k=1:Nsym
    rx_sym(k) = median(rx_demod_comp((k-1)*Nsample_sym+1 : k*Nsample_sym ))/2;
end
%  -- 4.2 symbol demapping (complex number -> bits)
bit_rcv = [];
for k1=1:Nsym
    min_index = -1;
    min_value = 1000;
    for k2 = 1:4
        tmp_value = abs(rx_sym(k1) - QPSK_mapper(k2));
        if min_value > tmp_value
            min_index = k2;
            min_value = tmp_value;
        end
    end
    
    bit_rcv(2*k1) = (min_index > 2);
    bit_rcv(2*k1-1) = mod(min_index-1,2);
end




%Analysis -----------------------------------
%1. bit error detection (compare sent bits & received bits)
bit_error = sum(abs(bit_send - bit_rcv))/Nbit

figure(2)
title('Bit error map');
stem(abs(bit_send - bit_rcv))

%2. frequency domain analysis
Nfft = 4096*4;
sample_rate = fc*Noversample;
res_freq = sample_rate/Nfft;
f_sim = [-sample_rate/2 :res_freq : sample_rate/2-res_freq];

figure(1);
subplot(Nplot,1,1);
freq_anal = abs(fft(sym_oversample, Nfft));
freq_anal = [freq_anal(length(freq_anal)/2+1 : length(freq_anal)) freq_anal(1:length(freq_anal)/2)];
plot(f_sim, freq_anal);
title('TX baseband signal');
xlabel('frequency (Hz)');
axis([-1000 1000 0 max(freq_anal)*1.2]);

subplot(Nplot,1,2)
freq_anal = abs(fft(RF_signal, Nfft));
freq_anal = [freq_anal(length(freq_anal)/2+1 : length(freq_anal)) freq_anal(1:length(freq_anal)/2)];
plot(f_sim, freq_anal);
title('TX RF signal');
xlabel('frequency (Hz)');

subplot(Nplot,1,3)
freq_anal = abs(fft(rx_I, Nfft));
freq_anal = [freq_anal(length(freq_anal)/2+1 : length(freq_anal)) freq_anal(1:length(freq_anal)/2)];
plot(f_sim, freq_anal);
title('RX demodulated signal (baseband)');
xlabel('frequency (Hz)');

subplot(Nplot,1,4);
freq_anal = abs(fft(rx_demod_comp, Nfft));
freq_anal = [freq_anal(length(freq_anal)/2+1 : length(freq_anal)) freq_anal(1:length(freq_anal)/2)];
plot(f_sim, freq_anal);
title('RX demodulated signal (Low pass filtered)');
xlabel('frequency (Hz)');
%axis([-1000 1000 0 max(freq_anal)*1.2]);




