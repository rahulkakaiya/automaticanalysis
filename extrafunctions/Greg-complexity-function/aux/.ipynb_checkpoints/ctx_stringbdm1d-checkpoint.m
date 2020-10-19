% Written by Dr. Gregory Scott from Imperial College London,
% Academic Clinical Lecturer, The Computational, Cognitive and Clinical
% Neuroimaging Laboratory (C3NL) Faculty of Medicine,
% Department of Medicine, https://www.imperial.ac.uk/people/gregory.scott99
%
% 1D BDM implementation of method as described in:
% A Decomposition Method for Global Evaluation of Shannon Entropy and Local Estimations of Algorithmic Complexity
% By Hector Zenil, Santiago Hern\[AAcute]ndez-Orozco, Narsis A. Kiani, Fernando Soler-Toscano, Antonio Rueda-Toicen
% preprint available at https://arxiv.org/abs/1609.00110
%
%% IMPORTANT NOTE: always use with len=1
function bdm = ctx_stringbdm1d(str, len)
if nargin < 2; len = 1; end

persistent BDMtab
if(isempty(BDMtab));
    load('BDMtab.mat', 'BDMtab');
    if usejava('jvm')
        BDMtab = containers.Map(BDMtab.Properties.RowNames, ...
            BDMtab.Var1);
    end
end

if(length(str) > 12)
    parts = ctx_partition(str, 12, len);
else
    parts = {str};
end
tal = ctx_tally(parts);

if usejava('jvm')
    bdm = sum(cellfun(@(a,b) BDMtab(a) + log2(b), tal(:,1), tal(:,2)));
else
    bdm = sum(cellfun(@(a,b) BDMtab{a,:} + log2(b), tal(:,1), tal(:,2)));
end
end
