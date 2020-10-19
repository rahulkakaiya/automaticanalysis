function [ID ] = find_subgraph_ID( A )
x=reshape(A',16,1);
str_x = num2str(x);
str_x(isspace(str_x)) = '';
ID= bin2dec(str_x');
end