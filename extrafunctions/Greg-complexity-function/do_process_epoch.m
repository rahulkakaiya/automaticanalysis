%%file do_process_epoch.m
function res = do_process_epoch(X, opts)
% DO_PREPROCESS_EPOCH Calculate measures on a single channels x time epoch
%   X is the data (channels x time)
%   opts is a structure that hold one or more fields required for the
%   measures to be able to work propertly:
%       srate = sampling rate e.g. 250
%       shuffs = number of shuffles to do
%

% NOTE: pay attention to the order of dimensions in X. Bad mistakes have
% (and will?) be made because of a failure to do so.
%
% TO DO: make a system to have a default structure/options
%   (but perhaps limited value in doing this given e.g. sampling rate
%   should be specified)
% Author: Gregory Scott (gregory.scott99@imperial.ac.uk)
% Email me about any of this...
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% make a blank results structure
res = struct;
res.opts = opts;

% derive some useful measures
nchans  = size(X,1);
npoints = size(X,2);

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Cast X to double type
X = double(X);
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% TODO: if there's' anything else we should be doing to the data
% before we start calculating measures, do it now...


% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% PREPROCESSING FOR BINARY/BINARY STRING-BASED COMPLEXITY MEASURES
% For several measures here we go through a rigmarole of 'converting' the
% data into a binarised time series; one should be cautious about the
% validity of these steps. They are based on papers like
% https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0133532
% There is probably a whole PhD's worth of research in just working out
% whether these steps make sense...
% NOTE: as above, you might want to double check whether the dimensions
% here make sense (and transposing...)

% De-trend each timeseries (channel)
Xd = detrend(X')';

% Hilbert transform and get the absolute value
Xh = hilbert(Xd')'; %hilbert() performs a column wise transformation
Xa = abs(Xh);

% Threshold each timeseries to > its mean
Xt = Xa > mean(Xa,2);

% Convert this binarised matrix to characters from their double() form
% We have to do that because some of these measures need characters
% rather than numbers
Xc = ctx_bi2str(Xt);

% Make a concatenated form of these (2D -> 1D), again based on
% Schartner et al., above (but used elsewhere also)
% NOTE: again you can check the concatenation is happening in the right
% order
Xccon = reshape(Xc, 1, []);
Xtcon = reshape(Xt, 1, []);

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%               BINARY/STRING-BASED COMPLEXITY MEASURES

% -> BDM2D - a 2D version of the Block Decomposition Method (Zenil)
% this can be done in one function call...
res.bdm2d = ctx_bdm2d(Xt);

% -> BDM and LZC concatenated (2D->1D) versions
% (see Schartner et al.)
% TO DO: add shuffling-based normalisation (see channelwise measures below)
res.bdmcon = ctx_stringbdm1d(Xccon);
res.lzccon = ctx_uschlzc1d(Xccon);

% -> channelwise measures, specifically BDM, (and 'normalised BDM'), ...
% and Lempel-Ziv Complexity (LZC), and normalised versions of those
% using the shuffling approach (see Schartner et al.)
%
% NOTE: this form of shuffling is not the only way of doing so, one could
% phase-shuffle (Schartner at al.)
for ch=1:nchans
    res.bdmch(ch)  = ctx_stringbdm1d(    Xc(ch,:));
    res.nbdmch(ch) = ctx_stringnormbdm1d(Xc(ch,:));
    res.lzcch(ch)  = ctx_uschlzc1d(      Xc(ch,:));

    % now make shuffled versions of BDM and LZC
    shuffvals = nan(1,res.opts.nshuffs);
    for sh=1:res.opts.nshuffs; ...
            shuffvals(sh) = ctx_uschlzc1d(Xc(ch,randperm(size(Xc,2))));
    end
    res.lzcchshuff(ch)  = res.lzcch(ch) ./ nanmean(shuffvals);

    shuffvals = nan(1,res.opts.nshuffs);
    for sh=1:res.opts.nshuffs; ...
            shuffvals(sh) = ctx_stringbdm1d(Xc(ch,randperm(size(Xc,2))));
    end
    res.bdmchshuff(ch)  = res.bdmch(ch) ./ nanmean(shuffvals);
end

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% TO DO: insert whatever measures you like...
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%                      POWER AND RELATIVE POWER
% We calculate power in specific frequency bands using EEGlab functions.
% (The spectopo function is wrapped in evalc to stop it producing gross
% output on the terminal). We calculate relative power by dividing by
% the sum of all bands.
% NOTE: the outputs will be called res.powerch_B and res.relpowerch_B
% where B is the index of the band defined in opts.band{}
%
fullpower = [];
for ch=1:size(X,1)
    evalres = evalc('[spectra, freqss] = spectopo(X(ch,:), 0, res.opts.srate, ''plot'', ''off'');');
    for b=1:numel(res.opts.bands)
        freqidx = find(freqss > res.opts.bands{b}(1) & ...
            freqss < res.opts.bands{b}(2));
        fullpower(ch,b) = mean(10.^(spectra(freqidx)/10));
        res.(['powerch_', num2str(b)])(ch) = fullpower(ch,b);
    end
   
    for b=1:numel(res.opts.bands)
        res.(['relpowerch_', num2str(b)])(ch) = ...
            {fullpower(ch,b)./nansum(fullpower(ch,:))};
    end
end

end