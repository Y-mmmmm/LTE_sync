# 01_basic
## 실습 내용
### ***통신 신호 및 시스템 & LTE개념***


### **MATLAB을 이용해서 RF 신호처리에 대해 실습**

**: 수신된 RF 신호에 대해 기저대역 IQ신호로 변환하고 보정**

**: 신호 처리 과정을 구현된 코드분석을 통해 재해석**

**: 각 신호의 주파수 특성 경향을 관찰**

**: Frequency Offset 보정 실습**




## 실습 (MATLAB)

**1. 코드 분석**
**: TX process의 3.2 RF signal generation 코드 분석**
```
%  -- 3.2 RF signal generation (product modulator)

RF_I = real(sym_oversample).*cos(2*pi*fc*t_sim);

RF_Q = imag(sym_oversample).*sin(2*pi*fc*t_sim);

RF_signal = RF_I - RF_Q; 
```
=> cos 신호와 sin 신호는 직교하는 형태임. Product modulator에서 송신단(TX)에서는 신호에 직교하는 Carrier를 곱함.

=> I-Channel에는 실수부분을 나타냄(cos을 곱해줌)

=> Q-Channel에는 허수부분을 나타냄(sin을 곱해줌)

=> RF_signal = RF_I - RF_Q 로 정의됨


**: RX process의 1.RF signal demodulation 코드 분석**
```
%1. RF signal demodulation (frequency offset exists, RF signal -> baseband%signal)

%  -- 1.1 I channel
rx_I = Rx_signal .* cos(2*pi*fc*(1+freqOffset/100)*t_sim);

%  -- 1.2 Q channel
rx_Q = Rx_signal .* sin(2*pi*fc*(1+freqOffset/100)*t_sim);
```
=> RF(수신측)에서는 약간의 Frequency Offset을 가지고 신호를 받음

=> 이러한 이유로 bit_error가 발생함

=> 이 부분을 나중에 수정해줘야 함



**2.  통신 신호의 주파수 특성 관찰**
[원래신호 Figure]	=>bit_error=0.5
파라미터 setting 상태
```
%Parameter setting ------------------------------------

Nbit = 1000;  %number of bits to send

Snr = 10;  %signal to noise ratio, dB

freqOffset = 0.03;  %frequency offset (unit : %)
```
![](https://github.com/prizesilvers2/Communication_Theorem/blob/master/1/figs/original_figure.jpg)


**3. 수신신호 환경에 따른 bit error 관찰**

![](https://github.com/prizesilvers2/Communication_Theorem/blob/master/Figs/1/figure0.png)


**4. Frequency Offset 보정**

=> freqOffset = 0.03으로 바꿨을 때, bit error 관찰

=> RX process 3번에 보정코드를 넣어서 bit error 안나오도록 수정하기


```
(현재 parameter setting)					=> bit error=0.4990
%Parameter setting ------------------------------------
Nbit = 1000;                    %number of bits to send
Snr = 10;                       %signal to noise ratio, dB
freqOffset = 0.03;              %frequency offset (unit : %)
fc = 10^4;                      %carrier frequency
fs = 100;                       %baseband rate
```

(현재 그래프)

![](https://github.com/prizesilvers2/Communication_Theorem/blob/master/Figs/1/figure1.png)

여기에 RX process 3번에 아래와 같은 코드를 추가하게 되면 bit error=0으로 보내줄 수 있게 된다.
```
(추가된 코드)
rx_demod_comp  =rx_demod_filtered.*exp(i*2*pi*fc*(freqOffset/100)*t_sim);
```

(코드 수정 후 그래프) => bit error=0
![](https://github.com/prizesilvers2/Communication_Theorem/blob/master/Figs/1/figure2.png)

> Written with [StackEdit](https://stackedit.io/).

