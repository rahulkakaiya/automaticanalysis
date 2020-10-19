function [lzc,d] = ctx_stringlzc1d_schartner(X,d)
if nargin < 2
    d = {};
else
    d={'0', '1'};
end
w = '';
i=1;
for ch=1:length(X)
    c = X(ch);
    wc = [w, c];
    if ismember(wc,d)
        w = wc;
    else
        d{end+1} = wc; %#ok<AGROW>
        w = c;
    end
    i = i+1;
end
lzc = numel(d);
end


% ##########
% '''
% LZc - Lempel-Ziv Complexity, column-by-column concatenation
% '''
% ##########
%
% def cpr(string):
%  '''
%  Lempel-Ziv-Welch compression of binary input string, e.g. string='0010101'. It outputs the size of the dictionary of binary words.
%  '''
%  d={}
%  w = ''
%  i=1
%  for c in string:
%   wc = w + c
%   if wc in d:
%    w = wc
%   else:
%    d[wc]=wc
%    w = c
%   i+=1
%  return len(d)