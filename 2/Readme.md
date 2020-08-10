# 02_Modulation
## 실습 내용
### ***통신 신호 및 시스템 & LTE개념***


### **MATLAB을 이용해서 RF 신호처리에 대해 실습**

**: Symbol modulation 구현**

**: SNR 별 modulation 성능 분석**

**:	OFDM symbol demodulation**



## 실습 (MATLAB)

**1. Symbol modulation 구현**

=> TS 36.211 의 7.1을 보고 TX process의 2.modulation부분 구현 완성

=> QPSK 구현을 참고하여 16QAM코드 구현

=> Qm: modulation order(2-QPSK, 4-16QAM)

```
(내가 추가한 코드)
elseif Qm == 4 % --- 16QAM
    Nsym = Nbit/Qm;
    sym_mapper = [1+i,1+3*i,3+i,3+3*i,
                  1-i,1-3*i,3-i,3-3*i,
                 -1+i,-1+3*i,-3+i,-3+3*i,
                  -1-i,-1-3*i,-3-i,-3-3*i]/sqrt(10); 
```

**: RX process의 3.3 symbol demapping 코드의 메커니즘 분석**
```
(코드)
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
```

여기 parameter SNR=30을 넣고 구현 동작을 확인해보면

=> Qm = 2, 4, 6을 조절하였을 때, bit error가 거의 나지 않아야 함(여기에서는 2,4인 경우만 그래프를 첨부함)

![](https://github.com/prizesilvers2/Communication_Theorem/blob/master/Figs/2/FIGURE0.png)


**2. SNR 별 modulation 성능 분석**

=> 각 modulation 기법 별로 SNR을 낮추고 성능 확인

=> Qm= 2,4,6에 대해 SNR을 서서히 낮추었을 때 bit error 확인
	
=> signal constellation 확인(figure1보기)

1) Qm=2일 때, SNR= 10, 5, 0. -5 성능을 그래프로 확인해보면

![](https://github.com/prizesilvers2/Communication_Theorem/blob/master/Figs/2/FIGURE1.png)

2) Qm=4일 때, SNR= 10, 5, 0. -5 성능을 그래프로 확인해보면

![](https://github.com/prizesilvers2/Communication_Theorem/blob/master/Figs/2/FIGURE2.png)

1)2) 상황을 보면 SNR의 크기를 낮춰줄수록 그래프가 더 퍼지게 나타났으며, bit error가 커지는 것을 볼 수 있었다.


**3. OFDM symbol demodulation**

=> 송신 측 OFDM modulation 코드 분석(TX process 3, OFDM modulation 부분)
```
(코드)
%3. OFDM modulation ----------------------------------------
if FFTsize > 0
    sym_send = [];
    for k = 1 : Nsym/FFTsize
        OFDM_mod = ifft(symf_send((k-1)*FFTsize + 1 : k*FFTsize));
        sym_send = [sym_send OFDM_mod((FFTsize-ncp+1):FFTsize) OFDM_mod];
    end
    NOfdmSym = Nsym/FFTsize*(FFTsize+ncp);                                 // FFTsize에 cp까지 더해줌( cp + 원래 신호)
else
    sym_send = symf_send;
    NOfdmSym = Nsym;
end

=> RX process의 3.2 OFDM demodulation 구현
(FFT point=8, cp길이(ncp)=2 로 가정)                                      // error 안나면 잘 구현된 것임
	                                                                       //(8개의 복소수가 들어가서 10개의 복소수가 나와야함)
(코드)                                                                   // RX인 받는 쪽에서는 cp는 빼고 받아줘야할 듯함.
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
```
=> FFTsize=8로 두고, bit errorrk FFTsize=0대비 동일한지 확인하여 구현 검증하기

1) FFTsize=8로 두었을 때, bit error =0.4977
```
[parameter setting]
%OFDM modulation
FFTsize = 8;                    %OFDM parameter (0 : no OFDM modulation)
ncp = 2;                        %cyclic prefix
fftOffset = 2;                  %sample offset for FFT process
```
```
(여기서 추가된 코드)
% -- 3.2 OFDM demodulation
if FFTsize > 0
    rxf_sym = [];
    for k = 1: Nsym/FFTsize
	ofdmSymOffset = (k-1)*(FFTsize +ncp) + fftOffset ;
	rxf_sym = [rxf_sym  fft(rx_sym(ofdmSymOffset +1 : ofdmSymOffset + FFTsize)) ];
    end
else
    rxf_sym = rx_sym;
end
```
코드를 고친 후 실행 결과 및 그래프 => bit error=0

![](https://github.com/prizesilvers2/Communication_Theorem/blob/master/Figs/2/FIGURE3.png)

2) FFTsize=0로 두었을 때, bit error = 0
```
[parameter setting]
%OFDM modulation
FFTsize = 0;                    %OFDM parameter (0 : no OFDM modulation)
ncp = 2;                        %cyclic prefix
fftOffset = 2;                  %sample offset for FFT process
```
실행 결과 및 그래프 => bit error=0

![](https://github.com/prizesilvers2/Communication_Theorem/blob/master/Figs/2/FIGURE4.png)


> Written with [StackEdit](https://stackedit.io/).

