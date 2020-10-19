function Y = gregsbdm2d(X, k, Tstep)
%% GREGSBDM2 Symbolic BDM 2d version
if(k~=3)
    error('Only implemented for k=3');
end
nbits = 6;
[ Sx, Jx, nx, Bx] = gregsymboliser(X, 'wsmi1d', k, Tstep);

Y = ctx_bdm2d(ctx_dec2col(Jx, 6));
end
