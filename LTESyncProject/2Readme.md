# LTESyncProject_2
## 실습 내용
### ***통신 신호 및 시스템 & LTE개념***


### **MATLAB을 이용해서 1 frame 신호 동기화 실습(8개의 예제)**

**: LTESyncProject_1에서 해결하지 못한 6번코드 문제해결 코드 및 그래프**

## 실습 (MATLAB)

**1. LTESyncProject_1에서 해결하지 못한 6번코드 문제해결 코드**

=> PSS detection부분의 코드를 수정해주었다.

=> 이 코드의 포인트는 1frame에서 PSS패턴은 5ms을 간격으로 위치해있으므로 correlation한 값들을 두가지 배열로 나누어서 더해준 뒤 두 배열을 합해줘서 가장 큰 값이 나올 때를
Nid2로 생각해주었다.

```
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
        end 
        
            A_0 = [];
            B_0 = [];
            C_0 = [];
            A_0 = max_PSS0(1, 1:76288) ;
            B_0 = max_PSS0(1, 76288+1: 152576);
            C_0= A_0 + B_0 ;
            [i, j] = max(C_0);
            k = j+76800 ;
        
            PSS0 = i;
            
            if max_PSS0(1, j) > max_PSS0(1, k)
                max_timing0 = j;
            else
                max_timing0 = k;
            end
     
end

```


=> 수정한 코드를 통해 PCI는 올바르게 찾았으나, Frameboundary는 올바르게 찾지 못하였다.

=> 여기서 발생한 또 다른 문제점은 다른 예제들에 적용을 하면 적용이 되는 예제도 있고, 안되는 예제도 있다는 것이다.



**프로젝트를 통해 느낀점**

  신호및시스템과 통신이론수업, 심화 수업을 통해 배운 이론을 실제로 Matlab을 이용하여 1frame의 디지털 신호를 동기화해본 경험은 공학의 이론이 현실에서는 이렇게 적용될 수 있다는 것을
직접 깨달을 수 있게 해주었다. 또한 이론에서 배운 것은 현실 기술에서는 큰 뼈대일 뿐 통신을 저 정확하게 하기위해서는 다른 수학적인 기술들도 필요하다는 것을 알게 되었다.
  또한 통신을 할 때 노이즈제거가 정말 중요하다는 것을 알게 되었다. 노이즈를 어떻게 제거하고 이를 신호로 어떻게 복원하는지가 통신의 질을 결정해준다는 생각이 들었다.
모든 예제를 해결할 수 있는 코드를 만드는 것에는 실패했지만, 직접 논문과 다른 동기화코드를 찾아보는 과정은 나에게 비교과 활동을 통해서 더 많은 지식을 직접 찾아보게 만들어주었다.(cp가
frame에 어디에 어떤 형식으로 위치해 있는지, frame의 구조 등). 지금은 4g인 lte의 동기화 방법에 대해 알게 되었으니, 다음번에는 현재 쓰고 있는 5g, 그리고 미래의 6g는 어떠한 원리로 기술이 구성되어있는지 꾸준히 공부해야겠다 :)

.
> Written with [StackEdit](https://stackedit.io/).

