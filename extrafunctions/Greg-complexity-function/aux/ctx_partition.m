function parts = ctx_partition(str, n, d)
parts = arrayfun(@(l) str(l:l+(n-1)), 1:d:(length(str)-(n-1)), ...
    'UniformOutput', false);
end
