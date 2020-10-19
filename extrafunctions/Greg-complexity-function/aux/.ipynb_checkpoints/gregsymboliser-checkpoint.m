function [ S, C, N, Bx ] = gregsymboliser(X, method, k, Tstep)
%% GREGSYMBOLISER Convert a time series into 'symbols' with a range of methods
switch method
    case 'wsmi1d'
        % Based on https://www.sciencedirect.com/science/article/pii/S0960982213009366#app2
        % This seems as if it ignores amplitudes and rather focuses on the
        % pattern of increases and decreases
        % iterate over channels
        Xsub = X(1:Tstep:end);
        sstop = (length(Xsub)-k)+1;
        S = [];
        for s=1:k:sstop
            [~,I] = sort(Xsub(s:(s+k-1)));
            S = [ S; I];
        end
        [Bx, IA, C]=unique(S,'rows');
        N = size(Bx,1);
    otherwise
        error(['Method ', method, ' not implemented.']);
end
end