function ixy = gregsmi(X, Y,  k, Tstep)
%% GREGSMI Gregs implmentation of symbolic mutual information
% see https://www.sciencedirect.com/science/article/pii/S0960982213009366

[ ~, Jx, nx] = gregsymboliser(X, 'wsmi1d', k, Tstep);
[ ~, Jy, ny] = gregsymboliser(Y, 'wsmi1d', k, Tstep);

T = length(X);

temp=histc(Jx,0.5:(nx+0.5));
px=temp(1:end-1)/T;         %probability of each response
hx=-sum(px.*log2(px));      %entropy of the full set of responses

temp=histc(Jy,0.5:(ny+0.5));
py=temp(1:end-1)/T;         %probability of each stimulus
hy=-sum(py.*log2(py));      %entropy of the full set of stimuli

%p(x|y) probability of each response for each stimulus 
pxcy=zeros(nx,ny);
for k=1:ny
    temp=histc(Jx(Jy==k),0.5:(nx+0.5));
    pxcy(:,k)=temp(1:end-1)/sum(Jy==k);
end

%H(X|Y) = sum_y[py*H(X|Y=y)] 
temp=-pxcy.*log2(pxcy);
temp(isnan(temp))=0;
hxy=sum(temp*py);           %conditional entropy 

%I(X;Y)=H(X)-H(X|Y)  mutual information
pekfactor = 1/log2(factorial(k));

ixy=(hx-hxy) * pekfactor;

end