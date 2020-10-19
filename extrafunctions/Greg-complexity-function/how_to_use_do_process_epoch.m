% Here's an example of how to use the do_process_epoch

% Imagine you get your ONE epoch of data from the EEG.data 
% (you'll need to do squeeze(EEG.data(:,:,whichepochnumberyoucareabout))
% (You can read about squeeze and why you might need that)

% Here just generate 30 channels of a 2 second epoch at 250Hz
X = rand(30, 2 * 250);

% Now run the function, giving it a structure as a second argument
% that defines important information it needs to know about the data
% (c.f. tools like hcsta that seem not to care!)
% (NB these options need to make sense, e.g. no point looking at freq
% bands outside your bandpass filter!)
% (NB to declare a struct line this 'inline' you need to wrap the
% cell array of bands in another {}). You could declare the struct
% before the function call, e.g. opts = struct; opts.srate=250; ...
res = do_process_epoch(X, ...
    struct(...
        'srate', 250, ... % sampling rate
        'nshuffs', 20, ... % number of shuffles to do (see code) 
        'bands', {{ [1,4], [4,8], [8,13], [13,30], [30,70] }})); % frequency bands of interest

