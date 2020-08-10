# LTESyncProject
## 실습 내용
### ***통신 신호 및 시스템 & LTE개념***


### **MATLAB을 이용해서 1 frame 신호 동기화 실습(8개의 예제)**

**: PSS detection 코드**

**: SSS detection 코드**

**: Frameboundary 찾는 코드**

**: Matlab 코드를 통해 얻은 결과 및 그래프**




## 실습 (MATLAB)

**1. PSS detection 코드**
```
max_timing = -1;
max_metric = -100000;
max_Nid = 0;

for testNid = 0 : 2
       PSSpattern = gen_PSS(testNid);
       timePssPattern = zeros(1, FFTsize);
       timePssPattern(FFTsize-(NsymPSS/2)+1:FFTsize) = PSSpattern(1:31);  
       timePssPattern(2:(NsymPSS/2)+1)=PSSpattern(32:62);
       timePssPattern = ifft(timePssPattern);
    
    for testTiming = 1 : Nsym-FFTsize
       PSS_metric = [] ; 
       metric = abs(dot(timePssPattern, xReal(testTiming: testTiming+FFTsize-1)));
       PSS_metric = [ PSS_metric metric] ; 
        if max_metric < metric
           max_metric = metric ;
           max_timing = testTiming;
           max_Nid = testNid;
        end
    end 
end
```
+ 여기에서 PssPattern을 저렇게 나눠서 지정해준 이유를 살펴보면 아래 그림과 같이 DC=0을 기준으로 위 아래로 PSS가 존재한다. 이때, -부분에 있는 신호를 +쪽에 띄어서 붙여줘야하기 때문에 다음과 같이 앞부분과 뒷부분쪽에 PSS를 위치시킨 것을 알 수 있다.

![]()1



=> 이전 실습과 같이 PSS detection을 해준 결과, 노이즈가 많이 낀 신호에서는 정확한 PCI를 찾기가 어려웠음

=> 더 정교하게 PCI를 찾기 위해서 코드를 일부분 추가시켜줌

```
(바뀐 PSS코드 = Nid2=0인 부분의 코드만 가져옴, Nid2=1,2 일때도 아래의 코드를 반복해서 넣어줘야함)

max_timing0 = -1;
max_metric0_f = -100000;

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
```

```
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
```

![]()4

![]()5

=> 위의 코드를 살펴보면 각 Nid2마다 correlation값이 최고인 지점을 찾아서 그 값들 중에 가장 큰 값을 골라내는 코드이다.

=> 이때, 최고의 값을 갖는 것을 Nid2의 값으로 추정하고 timing offset을 찾고 이를 SSS detection을 할 때 사용해주었다.

=> 이를 통해, 이전보다 PSS detection을 보다 정교하게 할 수 있었다.


**2. SSS detection**
```
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
```


**3. Frameboundary 찾는 코드**
```
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
```

**4. Matlab 코드를 통해 얻은 결과 및 그래프**

=> 6번을 제외한 나머지 예시들은 정확한 PCI와 Frameboundary를 찾을 수 있었음.

![]()

![]()


+ 2번 그래프를 자세히 살펴보면 PSS부분에서 추가한 코드를 통해서 더 정교하게 찾을 수 있었음.

![]()

> Written with [StackEdit](https://stackedit.io/).

