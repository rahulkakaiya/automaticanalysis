function [aap, resp] = aamod_meeg_extractdatabase(aap,task,subj,sess)

% --- USING extractdatabase FOR BEHAVIOURAL ANALYSIS OF EEG DATA ---
% - Extractdataframe allows you to extract behavioural information,
%   complexity, and store it in a dataframe.
% - This is compiled to a dataframe for each participant, and grouped for all
%   participants

% 1. For subject specific data, simply specify the structure with subject
%    specific information
%    | settings below are also outlined in 'aamod_meeg_extractdatabase.xml'
%    - '.subject': the subject for which to append information to
%    - '.session': session number
%    - '.extrafieldstruct': information to append to dataframe
%    - '.includecomplexityEpochTimeWindow': epoch time window for
%       algorhitmic complexity
%    - '.includecomplexityBaselineTimeWindow': epoch time window for
%       algorhitmic complexity for baseline
%
%    - '.includetrialnumber': true/false to append trial number 
%    - '.includeeegevents': true/false to append epoch event marker label

% below is an example code
% -----
% for subj = tab.participant_id' 
%     aap.tasksettings.aamod_meeg_extractdataframe.extrafields(end+1).subject = tabS{n}.participant_id; 
%     aap.tasksettings.aamod_meeg_extractdataframe.extrafields(end).session = '*';
%     aap.tasksettings.aamod_meeg_extractdataframe.extrafields(end).extrafieldsstruct = tabS{n};
% end
%
% aap.tasksettings.aamod_meeg_extractdataframe.includetrialnumber = true;
% aap.tasksettings.aamod_meeg_extractdataframe.includeeegevents = true;
% aap.tasksettings.aamod_meeg_extractdataframe(1).includecomplexityEpochTimeWindow = aap.tasksettings.aamod_meeg_epochs.timewindow;
% aap.tasksettings.aamod_meeg_extractdataframe(1).includecomplexityBaselineTimeWindow = aap.tasksettings.aamod_meeg_epochs.baselinewindow;
% -----


resp='';

switch task
    case 'report'
         
    case 'doit'
        %% INITIALISE
        meegfn = cellstr(aas_getfiles_bystream(aap,'meeg_session',[subj sess],'meeg'));
        meegfn = meegfn(strcmp(spm_file(meegfn,'ext'),'set'));
        
        [junk, EL] = aas_cache_get(aap,'eeglab');
        EL.load;
        
        datafn = cell(1,numel(meegfn));
        datafnmeeg = {};
        for seg = 1:numel(meegfn)
            EEGLABFILE = meegfn{seg};
            EEG = pop_loadset(EEGLABFILE);

            % empty dataframe
            dataframe = struct();
            
            %% T/F:TRIAL NUMBER HEADER
        
            % append trial number to dataframe
            if ~isempty(aas_getsetting(aap,'includetrialnumber'))
                if aas_getsetting(aap,'includetrialnumber') == true
                    for t=1:numel(EEG.epoch)
                        dataframe(t).Trial = t;
                    end
                end
            end


            %% T/F:EEG MARKERS HEADERS
            if ~isempty(aas_getsetting(aap,'includeeegevents'))
                if (aas_getsetting(aap,'includeeegevents')) == true
                    allfieldnames1 = fieldnames(EEG.epoch);

                    % append EEG event info to dataframe
                    for g=1:numel(fieldnames(EEG.epoch))
                        fieldname1 = allfieldnames1{g};
                        for i=1:numel(EEG.epoch)
                            eegvalue = EEG.epoch(i).(fieldname1)(1);
                            if iscell(eegvalue)
                                eegvalue = cell2mat(eegvalue);
                            end
                            dataframe(i).(fieldname1) = eegvalue;
                        end
                    end

                end
            end       


            %% COMPLEXITY HEADERS
            if ~isempty(aas_getsetting(aap,'includecomplexityEpochTimeWindow')) 
                eeglength = (abs(diff(aas_getsetting(aap,'includecomplexityEpochTimeWindow'))))/1000; % ms -> s
                eeglength = EEG.srate * eeglength;
                if ~isempty(aas_getsetting(aap,'includecomplexityBaselineTimeWindow')) 
                    baselinelength = (abs(diff(aas_getsetting(aap,'includecomplexityBaselineTimeWindow'))))/1000;
                    baselinelength = EEG.srate * baselinelength;        
                end
                for p=1:numel(EEG.epoch)
                    X = EEG.data(:,1:eeglength,p);
                    opts = struct('srate', EEG.srate, 'nshuffs', 20, 'bands', {{ [1,4], [4,8], [8,15], [15,32], [32,80], [80, 120] }}); 

                    if ~isempty(aas_getsetting(aap,'includecomplexityBaselineTimeWindow')) 
                        X = EEG.data(:,baselinelength+1:eeglength,p);
                        X_prestim = EEG.data(:,1:baselinelength,p);

                        % append to dataframe
                        dataframe(p).complexityBaseline = do_process_epoch(X_prestim, opts);
                    end

                    % append to dataframe
                    dataframe(p).complexity = do_process_epoch(X, opts);
                end
            end

            %% EXTRA HEADERS
            if ~isempty(aas_getsetting(aap,'extrafields'))
                extraheadersSetting = aas_getsetting(aap,'extrafields');

                % retrieve subject specific cell
                extraheadersSubj = extraheadersSetting(strcmp({extraheadersSetting.subject},aas_getsubjname(aap,subj)));
                if isempty(extraheadersSubj)
                    extraheadersSubj = extraheadersSetting(strcmp({extraheadersSetting.subject},'*')); 
                end    

                % retrieve session specific cell
                extraheadersSess = extraheadersSubj(strcmp({extraheadersSubj.session},aas_getsessname(aap,sess)));
                if isempty(extraheadersSess)
                    extraheadersSess = extraheadersSubj(strcmp({extraheadersSubj.session},'*')); 
                end 

                % check size of cell array extraheaders
                if numel(extraheadersSess)>1
                    aas_log(aap,false,sprintf('ERROR: extrafields for %s too large.',aas_getsessdesc(aap,subj,sess))); % false = warning, true = error
                elseif isempty(extraheadersSess)
                    aas_log(aap,false,sprintf('ERROR: extrafields for %s is empty.',aas_getsessdesc(aap,subj,sess)))
                else
                    extraheaders = extraheadersSess.extrafieldsstruct;
                    allfieldnames = fieldnames(extraheaders);

                    % append extraheaders to dataframe
                    for f=1:numel(fieldnames(extraheaders))
                        fieldname = allfieldnames{f};
                        value = extraheaders.(fieldname);
                        for i=1:numel(EEG.epoch)  
                            dataframe(i).(fieldname) = value;
                        end
                    end
                end
            end
            
            %% save
            % add segments
            for trial=1:numel(dataframe)
                dataframe(trial).segment = seg;
            end
            
            datafn{seg} = fullfile(aas_getsesspath(aap,subj,sess), spm_file(strrep(spm_file(EEGLABFILE,'basename'),'epochs','dataframe'),'ext','mat'));
            save(datafn{seg},'dataframe');
            
            datafnmeeg{end+1} = fullfile(aas_getsesspath(aap,subj,sess),sprintf('epochs_STIM-2_seg-%d.set',seg));
            datafnmeeg{end+1} = fullfile(aas_getsesspath(aap,subj,sess),sprintf('epochs_STIM-2_seg-%d.fdt',seg));
            pop_saveset(EEG,datafnmeeg{end});
        end
        
        EL.unload;
        
        % Describe outputs      
        aap = aas_desc_outputs(aap,subj,sess,'meeg',datafnmeeg);
        aap = aas_desc_outputs(aap,subj,sess,'dataframe',datafn);
        
    case 'checkrequirements'
        if ~aas_cache_get(aap,'eeglab'), aas_log(aap,true,'EEGLAB is not found'); end
end
end