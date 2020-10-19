function bdm = ctx_bdm2d(X)
persistent L
if(isempty(L))
    load('BDM2d_data.mat', 'L');
end
 [ ~ ,bdm] = cal_info_s(X,L);
end
