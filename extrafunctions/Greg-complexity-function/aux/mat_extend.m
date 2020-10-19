function [B,l,k ] = mat_extend( A,it )
m=size(A,1);
n=size(A,2);
kk=ceil(m/4);
ll=ceil(n/4);
k=abs(kk*4-m);
l=abs(ll*4-n);
if it
col_add=ones(m,l);
row_add=ones(k,n+l);
C=[A,col_add];
B=[C;row_add];
else
col_add=zeros(m,l);
row_add=zeros(k,n+l);
C=[A,col_add];
B=[C;row_add];
end

end