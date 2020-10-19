function b = ctx_dec2bi1d(X, n)
    b = ctx_dec2bi(X,n);
    b = reshape(b',1,numel(b));
end
