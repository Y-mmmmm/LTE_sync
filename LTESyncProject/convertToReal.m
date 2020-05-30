function out_r = convertToReal(a)

n_odd = [1 : 2 : length(a)];
n_even = [2 : 2 : length(a)];


out_r = a(n_odd)/32767 + j*a(n_even)/32767;
