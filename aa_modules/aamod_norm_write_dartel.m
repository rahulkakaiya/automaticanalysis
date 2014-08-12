% AA module - write normalised input useing DARTEL
% [aap,resp]=aamod_norm_write_dartel(aap,task,subj,sess)
% Rhodri Cusack MRC CBU Cambridge Jan 2006-Aug 2007
% Tibor Auer MRC CBU Cambridge 2012-2013

function [aap,resp]=aamod_norm_write_dartel(aap,task,varargin)

resp='';

switch task
    case 'report' % [TA]
        subj = varargin{1};
        if nargin == 4
            sess = varargin{2};
            localpath = aas_getpath_bydomain(aap,aap.tasklist.currenttask.domain,[subj,sess]);
        else % subject
            localpath = aas_getpath_bydomain(aap,'subject',subj);
        end
        
        % find out what streams we should normalise
		streams=aas_getstreams(aap,'out');
        if isfield(aap.tasklist.currenttask.settings,'diagnostic') && isstruct(aap.tasklist.currenttask.settings.diagnostic)
            inds = aap.tasklist.currenttask.settings.diagnostic.streamind;
        else
            inds = 1:length(streams);
        end
        for streamind = inds
            streamfn = aas_getfiles_bystream(aap,aap.tasklist.currenttask.domain,cell2mat(varargin),streams{streamind},'output');
            streamfn = streamfn(1,:);
            streamfn = strtok_ptrn(basename(streamfn),'-0');
            fn = ['diagnostic_aas_checkreg_slices_' streamfn '_1.jpg'];
            if ~exist(fullfile(localpath,fn),'file')
                aas_checkreg(aap,aap.tasklist.currenttask.domain,cell2mat(varargin),streams{streamind},'structural');
            end
            % Single-subjetc
            fdiag = dir(fullfile(localpath,'diagnostic_*.jpg'));
            for d = 1:numel(fdiag)
                aap = aas_report_add(aap,subj,'<table><tr><td>');
                imgpath = fullfile(localpath,fdiag(d).name);
                aap=aas_report_addimage(aap,subj,imgpath);
                [p f] = fileparts(imgpath); avipath = fullfile(p,[strrep(f(1:end-2),'slices','avi') '.avi']);
                if exist(avipath,'file'), aap=aas_report_addimage(aap,subj,avipath); end
                aap = aas_report_add(aap,subj,'</td></tr></table>');
            end
            % Study summary
            aap = aas_report_add(aap,'reg',...
                ['Subject: ' basename(aas_getsubjpath(aap,subj)) '; Session: ' aas_getdirectory_bydomain(aap,aap.tasklist.currenttask.domain,varargin{end}) ]);
            aap=aas_report_addimage(aap,'reg',fullfile(localpath,fn));
        end
    case 'doit'
        subj = varargin{1};
        if nargin == 4, sess = varargin{2}; end
        
        % Is session specified in task header?
        if (isfield(aap.tasklist.currenttask.settings,'session'))
            sess = aap.tasklist.currenttask.settings.session;
        end
        
        % set up job
        % template
        template = aas_getfiles_bystream(aap, 'dartel_template');
        % flow fields..
        job.data.subj.flowfield{1} = aas_getfiles_bystream(aap, subj, 'dartel_flowfield');
        job.template{1} = template;
        job.bb = nan(2,3);
        job.vox = aap.tasklist.currenttask.settings.vox;    % voxel size
        job.fwhm = aap.tasklist.currenttask.settings.fwhm;              % smoothing
        job.preserve = aap.tasklist.currenttask.settings.preserve;      % modulation
        
		% find out what streams we should normalise
        streams=aap.tasklist.currenttask.outputstreams.stream;        
        for streamind=1:length(streams)
            if ~aas_stream_has_contents(aap,streams{streamind}), continue; end
            imgs = [];
            % Image to reslice
            if isstruct(streams{streamind}), streams{streamind} = streams{streamind}.CONTENT; end
            if exist('sess','var')
                P = aas_getfiles_bystream(aap,aap.tasklist.currenttask.domain,[subj,sess],streams{streamind});
            else
                P = aas_getfiles_bystream(aap,subj,streams{streamind});
            end
            % exclude image already normalised
            f = basename(P);
            P = P(f(:,1) ~= 'w',:);
            imgs = strvcat(imgs, P);
            % delete previous because otherwise nifti write routine doesn't
            % save disc space when you reslice to a coarser voxel
            for c=1:size(P,1)
                [pth fle ext]=fileparts(P(c,:));
                [s w] = aas_shell(['rm ' fullfile(pth,[aap.spm.defaults.normalise.write.prefix fle ext])],true); % quietly
            end;
            job.data.subj.images = cellstr(imgs);
            
            aas_log(aap, false, sprintf('Running with %s...', which('spm_dartel_norm_fun')));
            spm_dartel_norm_fun(job);
            
            % describe outputs (differ depending on modulation)
            if job.preserve==1
                prefix = 'smw';
            else
                prefix = 'sw';
            end

            wimgs=[];
            for ind=1:length(job.data.subj.images)
                [pth, nme, ext] = fileparts(job.data.subj.images{ind});
                % overwrite input with output if specified (e.g. for contrasts)
                if isfield(aap.tasksettings.(aap.tasklist.main.module(aap.tasklist.currenttask.modulenumber).name)(aap.tasklist.currenttask.index).outputstreams,'preservefilename') && ...
                        aap.tasksettings.(aap.tasklist.main.module(aap.tasklist.currenttask.modulenumber).name)(aap.tasklist.currenttask.index).outputstreams.preservefilename
                    movefile(fullfile(pth,[prefix nme ext]),job.data.subj.images{ind});
                    wimgs = strvcat(wimgs,job.data.subj.images{ind});
                else
                    wimgs = strvcat(wimgs,fullfile(pth,[prefix nme ext]));
                end
            end
            
            % binarise if specified
            if isfield(aap.tasklist.currenttask.settings,'PVE') && ~isempty(aap.tasklist.currenttask.settings.PVE)
                for e = 1:size(wimgs,1)
                    inf = spm_vol(deblank(wimgs(e,:)));
                    Y = spm_read_vols(inf);
                    Y = Y>=aap.tasklist.currenttask.settings.PVE;
                    nifti_write(deblank(wimgs(e,:)),Y,'Binarized',inf)
                end
            end
            
            % describe outputs with diagnostoc
            if (exist('sess','var'))
                aap=aas_desc_outputs(aap,aap.tasklist.currenttask.domain,[subj,sess],streams{streamind},wimgs);
                if strcmp(aap.options.wheretoprocess,'localsingle')
                    aas_checkreg(aap,aap.tasklist.currenttask.domain,[subj,sess],streams{streamind},'structural');
                end
            else
                aap=aas_desc_outputs(aap,subj,streams{streamind},wimgs);
                if strcmp(aap.options.wheretoprocess,'localsingle')
                    aas_checkreg(aap,subj,streams{streamind},'structural');
                end
            end
        end
        
    case 'checkrequirements'
        
    otherwise
        aas_log(aap,1,sprintf('Unknown task %s',task));
end;
end