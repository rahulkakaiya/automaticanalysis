function aa_build_standalone_2_build(config, outdir)
aa = aaClass('nopath','nogreet');
if isstruc(config) % aap (run-time compile)
    aap = config;
elseif ischar(config) % aap_parameters_defaults file (offline standalone)
    aap=xml_read(config,struct('ReadAttr',0));
end

% TBX: 
%   Statistics_Toolbox
%   Parallel_Computing_Toolbox
%   Image_Processing_Toolbox
tbx = {'-p',fullfile(matlabroot,'toolbox','stats'),...
    '-p',fullfile(matlabroot,'toolbox','images'),...
    '-p',fullfile(matlabroot,'toolbox','distcomp')};
spmtoolsdir = textscan(aap.directory_conventions.spmtoolsdir,'%s','delimiter',':'); spmtoolsdir = spmtoolsdir{1};
spmtoolsdir(2:2:numel(spmtoolsdir)*2) = spmtoolsdir(:);
spmtoolsdir(1:2:numel(spmtoolsdir)) = cellstr('-a');

mkdir(fullfile(outdir,[aa.Name strtok(aa.Version,'.')]));

mcc('-m', '-C', '-v',...
    '-o',aa.Name,...
    '-d',fullfile(outdir,[aa.Name strtok(aa.Version,'.')]),...
    '-N',tbx{:},...
    '-R','-singleCompThread',...
    '-a',aa.Path,...
    '-a',aap.directory_conventions.spmdir,...
    spmtoolsdir{:},...
    '-a',aap.directory_conventions.eeglabdir,...
    '-a',aap.directory_conventions.GIFTdir,...
    '-a',aap.directory_conventions.BrainWaveletdir,...
    '-a',aap.directory_conventions.ANTSdir,...
    '-a',aap.directory_conventions.DCMTKdir,...
    '-a',aap.directory_conventions.templatedir,...
    'aa_standalone.m');