function [ ID_info] = get_mat_ID_INFO( AA,L)
subgraph=zeros(4,4);
kk=1;
A=AA;
ll=size(A,1)/4;
ss=size(A,2)/4;
ID_info=ones(2,ll*ss);

for i=0:ll-1
    for j=0:ss-1
             for ii=1:4
             for jj=1:4
             subgraph(ii, jj)= A(ii + i*4, jj + j*4);
             end
             end
             ID_info(1,kk)=find_subgraph_ID(subgraph);
              ID_info(2,kk)=L(L(:,1)==ID_info(1,kk),2);
             kk=kk+1;
             
    end
end
            
end