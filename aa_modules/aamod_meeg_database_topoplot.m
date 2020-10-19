function [aap, resp] = aamod_meeg_dataframe_topoplot(aap,task,subj,sess)

% --- USE OF dataframe_topoplot CURRENTLY LIMITED TO COMPLEXITY PLOTS ---

% below is an example code
% -----
% aap.tasksettings.aamod_meeg_database_topoplot(1).complexityheaders = {'lzc', 'bdm'};
% -----

resp='';

switch task
    case 'report'
        if ~isempty(aas_getsetting(aap,'complexityheaders'))
            cmpxhdrs = aas_getsetting(aap,'complexityheaders');
            for h=1:numel(cmpxhdrs) % loop over complexity headers
                hdr = cmpxhdrs{h};
                aap = aas_report_addimage(aap,subj,fullfile(aas_getsesspath(aap,subj,sess),[hdr '.tiff']));
            end
        end
        %% subject summary: FOR ALL SUBJECTS - RUN ONL OVER FINAL SUBJECT
        if (subj > 1) && (subj == numel(aap.acq_details.subjects)) % last subject
            %% csv (for extractdataframe)
            grouptable = table();
            for subj=1:numel(aap.acq_details.subjects) % for each subject
                subjtable = table();
                if aas_isfile_bystream(aap,'meeg_session',[subj sess],'dataframesqueezed')            
                    squeezeddataframeFn = cellstr(aas_getfiles_bystream(aap,'meeg_session',[subj sess],'dataframesqueezed'));
                    for i=1:numel(squeezeddataframeFn) % for each output stream
                        sqdf = squeezeddataframeFn{i};
                        load(sqdf);
                        sqdataframe = dataframe; sqdataframe = struct2table(sqdataframe);
                        subjtable = [subjtable;sqdataframe];
                    end
                end
                grouptable = [grouptable;subjtable];
            end
            grouptable = table2struct(grouptable);
            sqdf_path = fullfile(aas_getstudypath(aap),'full_langlean_complexitytable.mat');
            save(sqdf_path,'grouptable');
            
            %% group stats topotplot
            % group stats topoplot: collect
            for subj=1:numel(aap.acq_details.subjects) % for each subject
                if aas_isfile_bystream(aap,'meeg_session',[subj sess],'topoplotarrays')
                    allFn = cellstr(aas_getfiles_bystream(aap,'meeg_session',[subj sess],'topoplotarrays'));
                    for i=1:numel(allFn) % for each output stream
                        df = allFn{i};
                        load(df);
                    end
                    if exist('complexity','var') % complexity
                        answe = fieldnames(complexity);
                        for j=1:length(fieldnames(complexity))                        
                            hdr = answe{j};
                            subjtopo(subj).(hdr) = complexity.(hdr);
                        end
                        clear complexity
                    end
                end
            end

            % group stats: group by subject
            answet = fieldnames(subjtopo);
            for n=1:length(fieldnames(subjtopo))
                hdr = answet{n};
                if any(strcmp(hdr,aas_getsetting(aap,'complexityheaders')))
                    for subj=1:numel(aap.acq_details.subjects)
                        numtrials = size(subjtopo(subj).(hdr).full_complexity,2)
                        for k=1:numtrials % trial number
                            subjtopotrial(k).(hdr)(subj) = {subjtopo(subj).(hdr).full_complexity(:,k)}
                        end
                    end
                end
            end 

            meegdataFn = cellstr(aas_getfiles_bystream(aap,'meeg_session',[subj sess],'topoplotmeegdata'));
            load(meegdataFn{1});
            
            % group stats: average for each trial (31x1xntrials)
            answep = fieldnames(subjtopotrial);
            for n=1:length(fieldnames(subjtopotrial))
                hdr = answep{n};
                for trial=1:numel(subjtopotrial)
                    grouptopo.(hdr)(:,trial) = mean(cell2mat(subjtopotrial(trial).(hdr)),2);
                end
                % topoplot 
                cfgsub = [];
                %cfgsub.highlight = 'labels';
                cfgsub.zlim = [min(mean(grouptopo.(hdr),2)) max(mean(grouptopo.(hdr),2))];

                % diagnostics
                hfigure = figure();
                topo_path_plot = fullfile(aas_getstudypath(aap),[hdr '.tiff']);     
                for d=1:size(grouptopo.(hdr),2)
                    topo_array = grouptopo.(hdr)(:,d); meegdata.(hdr) = topo_array;
                    cfgsub.parameter = hdr;
                    printPlot.plotAxess(d) = subplot(5,6,d), ft_topoplotER(cfgsub,meegdata);
                end
                set(printPlot.plotAxess,'Parent',hfigure);
                set(hfigure,'PaperPositionMode','auto');
                print(hfigure,topo_path_plot,'-dtiff','-r500');
            end

            % aa report
            for n=1:length(fieldnames(subjtopotrial))
                hdr = answep{n};
                aap = aas_report_addimage(aap,[],fullfile(aas_getstudypath(aap),[hdr '.tiff']));
            end
        end
            
    case 'doit'
        [junk, FT] = aas_cache_get(aap,'fieldtrip');
        FT = aas_inittoolbox(aap,'fieldtrip');
        FT.addExternal('spm12');
        FT.load 
        
        %% get meeg and dataframe
        meegfn = cellstr(aas_getfiles_bystream(aap,'meeg_session',[subj sess],'meeg'));
        dataframefn = cellstr(aas_getfiles_bystream(aap,'meeg_session',[subj sess],'dataframe'));
        
        databasecsvfn = {};
        
        switch spm_file(meegfn{1},'ext')
            case 'mat'
                filetype = 'fieldtrip';
            case 'set' 
                filetype = 'eeglab';
                meegfn = meegfn(strcmp(spm_file(meegfn,'ext'),'set'));
            otherwise
                aas_log(aap,true,'Unsupported file format')
        end
        for seg = 1:numel(meegfn)
            switch filetype
                case 'fieldtrip'
                    dat = load(meegfn{seg});
                    data(seg) = dat.data;
                case 'eeglab'
                    FT.unload;
                    if seg == 1
                        [junk, EL] = aas_cache_get(aap,'eeglab');
                        EL = aas_inittoolbox(aap,'eeglab');
                        EL.load;
                    else
                        EL.reload;
                    end
                    EEG = pop_loadset(meegfn{seg});
                    if isempty(EEG.epoch)
                        aas_log(aap,false,sprintf('WARNING: segment # %d has no trial --> skipped',seg));
                        continue; 
                    end
                    FT.reload;    
                    data(seg) = eeglab2fieldtripER(EEG);
                    EL.unload; % FieldTrip's eeglab toolbox is incomplete
            end
            % dataframe
            load(dataframefn{seg});
            
            %% replace with function to squeeze dataframe
            % then run extractdataframe again to include segment
            % then add subject summary (fullcsv) to extractdataframe report
            for trial=1:numel(dataframe)
                dataframe(trial).segment = seg;
            end
            
            %%
            dataframecsv_path = fullfile(aas_getsesspath(aap,subj,sess),sprintf('squeezed_dataframe_seg%d.mat',seg))
            save(dataframecsv_path,'dataframe'); 
            databasecsvfn{end+1} = dataframecsv_path;
            
            dataframes(seg).df = dataframe;
        end

        %% main
        arraysfn = {}; % output structure
        if ~isempty(aas_getsetting(aap,'complexityheaders'))
            complexity_segs = struct();
            cmpxhdrs = aas_getsetting(aap,'complexityheaders');
            if ~isempty(aas_getsetting(aap,'complexityheadersbaseline')) 
                hdrbsl = aas_getsetting(aap,'complexityheadersbaseline');
            end
            for h=1:numel(cmpxhdrs) % loop over complexity headers
                hdr = cmpxhdrs{h};
                complexity_segs.(hdr) = struct();
                header = complexity_segs.(hdr);
                
                for i=1:numel(dataframes) % number of segments
                    meegdata = data(i); % define meeg
                    dfdata = dataframes(i); % define df
                    meegdata = keepfields(meegdata, {'elec' 'label'});
                    meegdata.dimord = 'chan';
                    for j=1:numel(dataframes(i).df) 
                        % Extract array
                        header.a = dfdata.df(j).complexity.([hdr 'ch'])';
                        if exist('hdrbsl','var')
                            if any(strcmp(hdrbsl,hdr))
                                header.a_baseline = dataframes(i).df(j).complexityBaseline.([hdr 'ch'])'; meegdata.([hdr '_baseline']) = header.a_baseline; % lz baseline complexity, 31x1
                            end
                            header.a = header.a;
                        end
                        meegdata.(hdr) = header.a; % lz complexity, 31x1

                        % Saving trial arrays
                        complexity_segs.(hdr)(i).trial(j) = {meegdata.(hdr)};
                    end
                    maxtrials(i) = j;
                end
                
                %% Topoplots
                for k=1:max(maxtrials)
                    for l=1:numel(complexity_segs.(hdr)) % segments
                        if k > numel(complexity_segs.(hdr)(l).trial)
                            continue;
                        end
                        complexity_segs.(hdr)(l).complexity  = complexity_segs.(hdr)(l).trial(k);
                    end
                    for l=1:numel(complexity_segs.(hdr))
                        if ~isempty(complexity_segs.(hdr)(l).complexity);
                            meany(:,l) = complexity_segs.(hdr)(l).complexity;
                        end
                    end
                    complexity.(hdr).full_complexity(:,k) =  mean(cell2mat(meany),2);
                    complexity_segs.(hdr) = rmfield(complexity_segs.(hdr),'complexity');
                    clear meany;
                end
                
                % topoplot 
                cfgsub = [];
                %cfgsub.highlight = 'labels';
                cfgsub.zlim = [min(mean(complexity.(hdr).full_complexity,2)) max(mean(complexity.(hdr).full_complexity,2))];

                % diagnostics
                hfigure = figure();
                topo_path_plot = fullfile(aas_getsesspath(aap,subj,sess),[hdr '.tiff']);     
                for d=1:size(complexity.(hdr).full_complexity,2)
                    topo_array = complexity.(hdr).full_complexity(:,d); meegdata.(hdr) = topo_array;
                    cfgsub.parameter = hdr;
                    printPlot.plotAxes(d) = subplot(5,6,d), ft_topoplotER(cfgsub,meegdata);
                end
                set(printPlot.plotAxes,'Parent',hfigure);
                set(hfigure,'PaperPositionMode','auto');
                print(hfigure,topo_path_plot,'-dtiff','-r500');

            end
            topo_path = fullfile(aas_getsesspath(aap,subj,sess),'complexitymeeg.mat');
            arraysfn{end+1} = topo_path;
            save(topo_path,'complexity');
        end

        meeg_path = fullfile(aas_getsesspath(aap,subj,sess),'meegdata.mat');
        meegdata = keepfields(meegdata, {'elec' 'label' 'dimord'});
        save(meeg_path,'meegdata');
        
        FT.rmExternal('spm12');
        FT.unload;
        
        % desc outputs
        aap = aas_desc_outputs(aap,subj,sess,'dataframesqueezed',databasecsvfn);
        aap = aas_desc_outputs(aap,subj,sess,'topoplotarrays',arraysfn);
        aap = aas_desc_outputs(aap,subj,sess,'topoplotmeegdata',meeg_path);
    case 'checkrequirements'
        if ~aas_cache_get(aap,'eeglab'), aas_log(aap,false,'EEGLAB is not found -> You will not be able process EEGLAB data'); end
        if ~aas_cache_get(aap,'fieldtrip'), aas_log(aap,true,'FieldTrip is not found'); end
end
end