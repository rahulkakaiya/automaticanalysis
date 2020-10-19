function ld = ctx_stringbdmld1d(str, sz, shift)
if nargin < 3
    shift = 12;
end
if nargin < 2
    sz = 12;
end

persistent LDtab
if(isempty(LDtab))
    load('LDtab.mat', 'LDtab');
    if usejava('jvm')
        LDtab = containers.Map(LDtab.Properties.RowNames, ...
            LDtab.Var1);
    end
end

if(length(str) > 12)
    parts = ctx_partition(str, sz, shift);
else
    parts = {str};
end
tal = ctx_tally(parts);

if usejava('jvm')
    ld = sum(cellfun(@(a,b) LDtab(a) * b, tal(:,1), tal(:,2)));
else
    ld = sum(cellfun(@(a,b) LDtab{a,:} * b, tal(:,1), tal(:,2)));
end
end
