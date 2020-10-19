function A = megaeegavalanchedetector(raw, zthresh, ...
    threshdir, method, dt)
%MEGAEEGAVALANCHEDETECTOR Detect 'avalanches' in EEG data in different ways
% following the descriptions in various papers.
%
% For use in Wes's project!
%
% Example execution (but do not assume any parameters make sense!)
% X = normrnd(0, 2, 2500, 25);
% A = megaeegavalanchedetector(X, 2, '+', 'fagerholm', 4)
%
% Inputs
%   raw         input data (time x signals)
%   zthresh     threshold quantity in s.d. of signal
%   threshdir   threshold direction
%        '+'    only positive deflections
%        '-'    only negative deflections
%        '+-'   positive and negative deflections
%   method      specific method to use
%       'fagerholm' https://www.jneurosci.org/content/35/11/4626
%       'shriki'    https://www.jneurosci.org/content/33/16/7079
%           *NOT YET IMPLEMENTED*
%       'meiselcoh' https://www.jneurosci.org/content/jneuro/33/44/17363
%           *NOT YET IMPLEMENTED*
%       ....
%   dt          bin width/window length *in samples, not time*
%
% by Gregory Scott (gregory.scott99@imperial.ac.uk)
% ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
% ** NOTE! In this implementation the data is in the form time x channels
% i.e. channels are COLUMNS in the input data. This might be different
% to your normal data in which case you may need to transpose (i.e. X') **
% ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

% zscore the raw data along COLUMNS (i.e. channels independently)
% z-transformed absolute value time course of each channel
% ** NOTE! Check the dimension of this is correct! **
zraw = zscore(raw);

% threshold the zscored EEG according to whether above
% (or below if negative threshold) threshold
switch threshdir
    case '+'
        biraw = zraw > zthresh;
    case '-'
        biraw = zraw < -abs(zthresh);
    case '+-'
        biraw = zraw > abs(zthresh) | zraw < -abs(zthresh);
    otherwise
        error(['Threshold direction ', threshdir, ...
            ' not implemented.']);
end

% create a thresholded version of the z-scored raw data where
% thrzraw = zraw(t,c) if zraw(t,c) is 'suprathreshold', or = 0 otherwise
thrzraw = zraw .* biraw;

switch method
    case 'fagerholm'
        % "We thresholded the z-transformed absolute value time course of
        % each channel at greater than a certain SD and then binarized
        % the result. ... The binarized time courses were then summed
        % across all 30 channels to give a 1D time course that measures
        % the total number of channels for which the absolute-value
        % activity lies above the given threshold at each time point."
        
        % ** TO DO! Check the dimension is correct ** 
        % --> I believe it is correct
        % raw data has been transposed so (time x channels x (epoch(i)) 
        % and thresholding is done for all channels at each time point, 
        % so a row-wise (timepoints) analysis --> sum() is columnwise, sum('',2) is rowwise
        
        sumbiraw = sum(biraw,2);
        sumzraw  = sum(thrzraw,2);
        
        % "...this single time course was then binned into time windows of
        % a certain size.
        % ** TO DO! Probably a more elegant way of doing this **
        binnedbi = [];
        for t=1:dt:length(sumbiraw)
            binnedbi = [binnedbi sum(sumbiraw(t:min(t + dt-1, end)))]; %#ok<AGROW>
        end
        
        % (also bin the unthresholded zscore data too in case we need it)
        binnedz = [];
        for t=1:dt:length(sumzraw)
            binnedz = [binnedz sum(sumzraw(t:min(t + dt-1, end)))]; %#ok<AGROW>
        end
        
        % "The duration of a cascade was then defined as a continuous
        % period of nonzero bins in between two zero (quiescent) bins."
        %
        % "The size of a cascade was defined as the sum of all bins
        % comprising the cascade."
        
        % We can use the _imaging_ Matlab function bwconncomp to do a lot
        % of the work for us, as it will break up the binned (summed) time
        % series into components separated by 0s (if any) and what it
        % returns are useful variables which we can quite simply process
        CC = bwconncomp(binnedbi);
        
        A = [];
        % number of avas
        A.N  = CC.NumObjects;
        % lengths of each ava (in bins)
        A.Lbins = cellfun(@(c) length(c), CC.PixelIdxList);
        % sizes of each ava in number of 'suprathreshold' timepoints
        A.Sc   = cellfun(@(c) sum(binnedbi(c)), CC.PixelIdxList);
        % sizes of each ava in summed 'suprathreshold' zscore
        A.Sz    = cellfun(@(c) sum(binnedz(c)), CC.PixelIdxList);
        % onset time of each ava (in binned indices)
        A.Obins = cellfun(@(c) min(c), CC.PixelIdxList);
    otherwise
        error(['Method ', method, ' not implemented.']);
end
