function lzc = ctx_nlzc1d_matlabshuff(X)
if(ischar(X))
    error('Input should be a numerical vector');
end
lzc = calc_lz_complexity(X, 'exhaustive', false) ./ ...
    calc_lz_complexity(shuff(X), 'exhaustive', false);

    function Y = shuff(X)
       Y = X(randperm(length(X))); 
    end
end