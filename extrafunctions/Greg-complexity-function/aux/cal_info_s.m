function [ m ,bdm] = cal_info_s( A,L)
r=0;
c=0;
for it=0:1
[AA,rown,coln]=mat_extend(A,it);
if rown~=0 
    r=log2(rown)+2.43502031602103;
end
if coln~=0 
    c=log2(coln)+2.43502031602103;
end
[I_ID]=get_mat_ID_INFO(AA,L);
B=I_ID(1,:);
y = unique(B);
temp = sum(unique(I_ID(2,:)));
II=y;
   N = numel(y);
   count = zeros(1,N);
   for k = 1:N
      count(k) = sum(B==y(k));
   end
   m=[II; count ];
 ohhhf(it+1)=(temp+sum(log2(count)))-r-c;
end
bdm= min(ohhhf);
end
% [ m ,bdm] = cal_info_s( Test1,L);

