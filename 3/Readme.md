# 03_LTE Synchronization
## 실습 내용
### ***통신 신호 및 시스템 & LTE개념***


### **MATLAB을 이용해서 RF 신호처리에 대해 실습**

**: PSS detection**

**: SSS detection**


## 실습 (MATLAB)

**1. PSS detection**

=> Cross-correlation을 계산해서 가장 적합한 N1D2값 및 timing offset 산출
(코드의 제일 윗 부분에 off-set에 넣으면 어디서부터 시작 되게 해둠; 시작점)
(여기서 prob1, 2 코드 쓰기)
  
=> PSS 신호 생성

=> 수신된 신호 rx_demod의 각 timing에 대해서 correlation 계산
(correlation을 반복하여 cross-correlation해줌)
	
=> Correlation값이 최대가 되는 NID 및 timing(slot-boundary)를 찾음


Prob1, Prob2 . 추가된 코드 (정답)

```
%prob.1 :: Gene i'trate OFDM modulated wave of theh PSS sequence 
% - generate PSS sequence
% gen_PSS
% - OFDM modulation
for testNid = 0 : 2
    % used function(PSS, SSS)

       PSSpattern = gen_PSS(testNid);
       timePssPattern = zeros(1, FFTsize);
       timePssPattern(subOffset_SS + NsymZeroPadding : subOffset_SS + NsymZeroPadding+NsymPSS -1) = PSSpattern;  
       timePssPattern = ifft(timePssPattern);

%prob.2 :: cross correlation between the generated wave and the rx_demod
%find the maximal point of the correlation value
    for testTiming = 1 : Nsym-FFTsize
       metric = abs(dot(timePssPattern, rx_demod(testTiming: testTiming+FFTsize-1)));
       if max_metric < metric
           max_metric = metric ;
           max_timing = testTiming;
           max_Nid = testNid;
       end
    end 
end
```


**2. SSS detection**

=> 가장 유사한 SSS신호를 찾아서 NID1를 추정

=> 수신 신호(rx_demod)로 부터 SSS관련 symbol 추출

=> 각 NID1 후보 값에 따라 SSS신호를 생성하고, correlation 계산
(subframe 0/5 별로 서로 다른 sequence를 고려해야함 ; SSS1, SSS2값이 다르기 때문에)
	
=> 가장 correlation이 높은 NID1 값에 대해 이전에 구한 N1D2와 조합하여 전체 NID값 계산 (PCI)
	
=> 이때, frame이 시작되는 시작점 timing 계산하기


Prob3, Prob4 추가된 코드(정답)
```
%prob.3 :: demodulate the received part of the SSS sequences
% - sample selection
% - OFDM demodulation
% - subcarrier selection

SSSsym = rx_demod(estimated_timing_offset-FFTsize : estimated_timing_offset -1);
SSSsymf = fft(SSSsym, FFTsize);
SSSrx = SSSsymf(subOffset_SS + NsymZeroPadding : subOffset_SS + NsymZeroPadding+NsymSSS-1);


%prob.4 :: correlation of the SSS
for testNid = 0 : 167
    % - generate the original SSS sequence
    SSSpattern = gen_SSS(testNid, estimatedNID2);
    
    for seq = 1 : 2 %for two distinct sequence (slot 0 or slot 10)
        % - correlation and find the maximal sequence index
        if metric> max_metric
            max_metric = metric;
            max_Nid = testNid;
            max_seq = seq;
        end
    end
end
```

> Written with [StackEdit](https://stackedit.io/).

