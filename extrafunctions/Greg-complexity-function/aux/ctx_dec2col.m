function b = ctx_dec2col(X, n)
if nargin < 2
    n = max(X(:));
end
b = zeros(length(X),n);
for i=1:length(X); b(i,X(i)) = 1; end
end
