function senstypes=cosmo_meeg_senstype_collection()
% return supported MEEG acquisition systems and their channel labels
%
% senstypes=cosmo_meeg_senstypes
%
% Output:
%   senstypes           struct where the fieldnames are the names
%                       of the supported MEEG acquisition systems.
%                       each field has fields:
%                       .label   channel labels
%                       .sens    short label for acquisition system
%                       .type    one of 'meg','meg_planar','meg_axial',
%                                or 'eeg'. '_combined' entries have the
%                                'meg' type.
%                       Each fieldname can have a postfix:
%                       '_planar_combined'  combined planar
%                                           labels; .label is Nx1 for N
%                                           sensor locations
%                       '_planar'           planar pair
%                                           labels; .label is Nx2
%                       '_mag'              magnetometers, .label
%                                           is Nx1. Currently this is only
%                                           provided for neuromag systems
%
% Example:
%     senstypes=cosmo_meeg_senstype_collection();
%     %
%     % show neuromag306 MEG magnetometers
%     cosmo_disp(senstypes.neuromag306alt_mag)
%     > .label
%     >   { 'MEG0111'
%     >     'MEG0121'
%     >     'MEG0131'
%     >        :
%     >     'MEG2621'
%     >     'MEG2631'
%     >     'MEG2641' }@102x1
%     > .sens
%     >   'neuromag306'
%     > .type
%     >   'meg_axial'
%     %
%     % show neuromag306 MEG planar gradiometers
%     cosmo_disp(senstypes.neuromag306alt_planar)
%     > .label
%     >   { 'MEG0112'  'MEG0113'
%     >     'MEG0122'  'MEG0123'
%     >     'MEG0132'  'MEG0133'
%     >        :          :
%     >     'MEG2622'  'MEG2623'
%     >     'MEG2632'  'MEG2633'
%     >     'MEG2642'  'MEG2643' }@102x2
%     > .sens
%     >   'neuromag306'
%     > .type
%     >   'meg_planar'
%     %
%     % show neuromag306 MEG combined planar gradiometers
%     cosmo_disp(senstypes.neuromag306alt_planar_combined)
%     > .label
%     >   { 'MEG0112+0113'
%     >     'MEG0122+0123'
%     >     'MEG0132+0133'
%     >           :
%     >     'MEG2622+2623'
%     >     'MEG2632+2633'
%     >     'MEG2642+2643' }@102x1
%     > .sens
%     >   'neuromag306'
%     > .type
%     >   'meg_planar_combined'
%     %
%     % show BTI 148 planar gradiometers
%     cosmo_disp(senstypes.bti148_planar)
%     > .label
%     >   { 'A1_dH'    'A1_dV'
%     >     'A2_dH'    'A2_dV'
%     >     'A3_dH'    'A3_dV'
%     >        :          :
%     >     'A146_dH'  'A146_dV'
%     >     'A147_dH'  'A147_dV'
%     >     'A148_dH'  'A148_dV' }@148x2
%     > .sens
%     >   'bti148'
%     > .type
%     >   'meg_planar'
%
% Note:
%   - this function requires FieldTrip, as it uses its collection of
%     layouts
%   - this function caches previously read layouts, for optimization
%     reasons. run "clear functions" to reset the cahce.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    senstypes=get_senstypes();

function senstypes=get_senstypes()
    persistent cached_senstypes;
    if isnumeric(cached_senstypes)
        cosmo_check_external('fieldtrip');

        sens_type_names=get_initial_sens_type_names();
        senstypes=get_initial_senstypes(sens_type_names);

        % because senslabel treats neuromag systems in a special way,
        % fix the output for a more common naming scheme
        % also rename 'planar_combined' to 'combined'
        processors={@fix_alt_name_senstypes,...
                    @fix_neuromag306_planar_combinations,...
                    @fix_ctf275_planar_old_fieldtrip,...
                    @fix_eeg10XX_channels_old_fieldtrip,...
                    @fix_yokogawa440_planar_old_fieldtrip,...
                    @fix_egiX_channels_old_fieldtrip,...
                    @fix_neuromag122_planar_name,...
                    @fix_eeg10XX_senstype,...
                    @add_biosemiXXX_abc_names,...
                    @add_modalities,...
                    @check_siblings,...
                    };
        nprocessors=numel(processors);
        for k=1:nprocessors
            processor=processors{k};
            senstypes=processor(senstypes);
        end

        senstypes=orderfields(senstypes);

        cached_senstypes=senstypes;
    else
        senstypes=cached_senstypes;
    end



function sens_type_names=get_initial_sens_type_names()
    h=help('ft_senslabel');
    match=regexp(cosmo_strsplit(h,'\n'),'\s*''(\w*)''\s*','tokens');
    msk=~cellfun(@isempty,match);

    d=diff(msk);
    first=find(d==1,1)+1;
    last=find(d==-1,1);

    sens_types_cell=match(first:last);
    sens_type_names=cellfun(@(x)x{:},sens_types_cell);

function senstypes=get_initial_senstypes(sens_type_names)
    senstypes=struct();
    postfixes={'','_combined'};
    for k=1:numel(sens_type_names)
        sens_type_name=sens_type_names{k};
        for j=1:numel(postfixes)
            key=[sens_type_name postfixes{j}];

            label=[];
            try
                label=ft_senslabel(key);
            catch

            end

            if isempty(label)
                continue;
            end

            % if the name ends with '_combined' but not with
            % '_planar_combined', make it end with '_planar_combined'
            % (necessary for neuromag)
            sp=cosmo_strsplit(key,'_');
            if numel(sp)>1 && strcmp(sp{end},'combined') && ...
                            ~strcmp(sp{end-1},'planar')
                sp{end}=['planar_' sp{end}];
                key=cosmo_strjoin(sp,'_');
            end

            sens_type_name=remove_alt_postfix(sens_type_name);

            senstypes.(key).label=label;
            senstypes.(key).sens=cosmo_strsplit(sens_type_name,'_',1);
        end
    end

function s=remove_alt_postfix(s)
    sp=cosmo_strsplit(s,'alt');
    if numel(sp)>1 && isempty(sp{end});
        s=cosmo_strjoin(sp(1:(end-1)),'alt');
    end

function s=sort_cellstr_rows(s)
    % helper function: sorts each row in a cell with strings
    % used to get the planar channels in order even when old FT
    % returns a weird random order
    n=size(s,1);
    for k=1:n
        s(k,:)=sort(s(k,:));
    end

function senstypes=fix_alt_name_senstypes(senstypes)
    % fixer for neuromag, newer fieldtrip versions only
    % ft_senslabel returns the label for this system in two
    % varietes, with and without spaces (e.g. 'MEG 2442' and 'MEG2442')
    % this function adds *alt
    keys=fieldnames(senstypes);
    n=numel(keys);
    for k=1:n
        key=keys{k};
        label=senstypes.(key).label;

        % first half of the label rows are without spaces,
        % second half are with spaces
        % detect whether that's the case here
        nrows=size(label,1);
        if mod(nrows,2)~=0
            continue;
        end
        half_nrows=nrows/2;

        with_spaces=label(1:half_nrows,:);
        without_spaces=label(half_nrows+(1:half_nrows),:);

        % transform e.g. 'MEG 2442' to 'MEG2442'
        spaces_removed=cellfun(@(x) strrep(x,' ',''),...
                                with_spaces,'UniformOutput',false);

        if isequal(without_spaces,spaces_removed)
            % insert 'alt' infix
            orig_senstype=senstypes.(key);

            sp=cosmo_strsplit(key,'_');
            sp{1}=[sp{1} 'alt'];
            alt_key=cosmo_strjoin(sp,'_');

            % add new senstype for alternative name
            senstypes.(alt_key)=orig_senstype;
            senstypes.(alt_key).label=without_spaces;
            % update label for original name

            senstypes.(key)=orig_senstype;
            senstypes.(key).label=with_spaces;
        end
    end

function senstypes=fix_neuromag122_planar_name(senstypes)
    % add '_planar' suffix to neuromag122
    [keys,sens]=get_keys_sens(senstypes);
    idxs=find(cosmo_match(sens,'neuromag122'));
    for k=1:numel(idxs)
        key=keys{idxs(k)};
        label=senstypes.(key).label;
        if size(label,2)==2
            new_key=[key '_planar'];
            assert(~isfield(senstypes,new_key));
            senstypes.(new_key)=senstypes.(key);
            senstypes=rmfield(senstypes,key);
        end
    end

function senstypes=add_biosemiXXX_abc_names(senstypes)
    % adds the 10/20 labels for biosemi16, 32, 64

    for nch=[16 32 64]
        chs=struct();
        switch nch
            case 16
                chs.C={ '3' '4' 'z' };
                chs.F={ '3' '4' 'z' };
                chs.Fp={ '1' '2' };
                chs.O={ '1' '2' 'z' };
                chs.P={ '3' '4' 'z' };
                chs.T={ '7' '8' };

            case 32
                chs.AF={ '3' '4' };
                chs.C={ '3' '4' 'z' };
                chs.CP={ '1' '2' '5' '6' };
                chs.F={ '3' '4' '7' '8' 'z' };
                chs.FC={ '1' '2' '5' '6' };
                chs.Fp={ '1' '2' };
                chs.O={ '1' '2' 'z' };
                chs.P={ '3' '4' '7' '8' 'z' };
                chs.PO={ '3' '4' };
                chs.T={ '7' '8' };

            case 64
                chs.AF={ '3' '4' '7' '8' 'z' };
                chs.C={ '1' '2' '3' '4' '5' '6' 'z' };
                chs.CP={ '1' '2' '3' '4' '5' '6' 'z' };
                chs.F={ '1' '2' '3' '4' '5' '6' '7' '8' 'z' };
                chs.FC={ '1' '2' '3' '4' '5' '6' 'z' };
                chs.FT={ '7' '8' };
                chs.Fp={ '1' '2' 'z' };
                chs.I={ 'z' };
                chs.O={ '1' '2' 'z' };
                chs.P={ '1' '10' '2' '3' '4' '5' '6' '7' '8' '9' 'z' };
                chs.PO={ '3' '4' '7' '8' 'z' };
                chs.T={ '7' '8' };
                chs.TP={ '7' '8' };
        end

        key=sprintf('biosemi%d', nch);
        if ~isfield(senstypes,key) || cosmo_overlap(...
                        {senstypes.(key).label},{{'A1','A2','A3'}})==1
            prefixes=fieldnames(chs);
            nprefix=numel(prefixes);
            label_cell=cell(nprefix,1);
            for k=1:nprefix
                prefix=prefixes{k};
                postfixes=chs.(prefix);
                npostfix=numel(postfixes);
                prefix_labels=cell(npostfix,1);
                for j=1:npostfix
                    postfix=postfixes{j};
                    prefix_labels{j}=[prefix postfix];
                end
                label_cell{k}=prefix_labels;
            end
            labels=cat(1,label_cell{:});
            alt_key=sprintf('biosemi%dalt',nch);

            senstype=struct();
            senstype.type='eeg';
            senstype.sens=key;
            senstype.label=labels;
            senstypes.(alt_key)=senstype;
        end
    end



function senstypes=fix_neuromag306_planar_combinations(senstypes)
    % fixer for neuromag306
    % ft_senslabel does not have the name X_planar,
    % but instead has the name X with label in an Nx3 cell
    % with the first two columns for planar and the third for mag channels.
    % This function takes the first two columns and stores them as
    % a proper X_planar senstype, and takes the last column and stores them
    % as an X_mag senstype.
    keys=fieldnames(senstypes);
    n=numel(keys);
    for k=1:n
        key=keys{k};

        label=senstypes.(key).label;

        if size(label,2)==3
            planar_label=label(:,1:2);
            mag_label=label(:,3);

            planar_key=[key '_planar'];
            mag_key=[key '_mag'];
            planar_combined_key=[planar_key '_combined'];
            if ~isfield(senstypes,planar_combined_key)
                senstypes=old_fieldtrip_add_combined_planar(senstypes,key);
            end
            assert(isfield(senstypes,planar_combined_key));

            % add planar and mag keys
            senstypes.(planar_key)=senstypes.(key);
            senstypes.(planar_key).label=sort_cellstr_rows(planar_label);

            senstypes.(mag_key)=senstypes.(key);
            senstypes.(mag_key).label=mag_label;

            % remove original key
            senstypes=rmfield(senstypes,key);
        end
    end

function senstypes=fix_ctf275_planar_old_fieldtrip(senstypes)
    % fixes missing channel in old fieldtrip versions
    key='ctf275_planar';
    if isfield(senstypes,key)
        label=senstypes.(key).label;
        % detect missing 'MRP31*' labels
        if isequal(size(label),[274 2]) && ...
                isequal(label([213 214],1),{'MRP23_dH';'MRP32_dH'})
            % allocate space
            label{275,1}='';

            % move one down
            label(215:end,:)=label(214:(end-1),:);

            % insert
            label(214,:)={'MRP31_dH','MRP31_dV'};
            senstypes.(key).label=label;
        end
    end

function senstypes=fix_yokogawa440_planar_old_fieldtrip(senstypes)
    % fixes missing channel in old fieldtrip versions
    key='yokogawa440_planar';
    if isfield(senstypes,key)
        label=senstypes.(key).label;
        % detect missing 'MRP31*' labels
        if isequal(size(label),[420 1]) && ...
                isequal(label([1 end],1),{'AG001_dH';'AG392_dV'})
            label=reshape(label,[],2);

            senstypes.(key).label=label;
        end
    end

function senstypes=fix_eeg10XX_senstype(senstypes)
    % set
    keys={'eeg1005','eeg1010','eeg1020'};
    for j=1:numel(keys)
        key=keys{j};
        if isfield(senstypes,key)
            senstypes.(key).sens='ext1020';
        end
    end


function senstypes=fix_eeg10XX_channels_old_fieldtrip(senstypes)
    % newer versions of fieldtrip add 8 channels to the eeg10XX series
    keys={'eeg1005','eeg1010','eeg1020'};
    nchans=[335 86 21 875];
    last_chan={'OI2','I2','O2'};
    for j=1:numel(keys)
        key=keys{j};
        if isfield(senstypes,key)
            label=senstypes.(key).label;
            nchan=nchans(j);
            if isequal(label(end),last_chan(j)) && numel(label)==nchan
                to_add={'A1' 'A2' 'M1' 'M2' 'T3' 'T4' 'T5' 'T6'}';
                senstypes.(key).label=[label;to_add];
            end
        end
    end

function senstypes=fix_egiX_channels_old_fieldtrip(senstypes)
    % newer versions of fieldtrip add 8 channels to the egiX series
    nchans=2.^(5:8)+1;
    for j=1:numel(nchans)
        nchan=nchans(j);
        key=sprintf('egi%d',nchan-1);
        if isfield(senstypes,key)
            label=senstypes.(key).label;
            wrong_last_label=sprintf('E%d',nchan);
            % append label to the end
            if numel(label)==nchan && strcmp(label{end},wrong_last_label)
                correct_last_label='Cz';
                label{end+1}=correct_last_label;
                senstypes.(key).label=label;
            end
        end
    end


function senstypes=check_siblings(senstypes)
    % helper to ensure all sensor types are kosher.
    % checks that "siblings" (different elements in senstypes with the same
    % 'sens' value) have the same number of sensor locations


    skip_test_for={'yokogawa440',... % has different number of
                                 ... % channels across its siblings
                    'ext1020'}; % for eeg1005, eeg1010, eeg1020

    [keys,labels]=get_keys_sens(senstypes);
    [idxs,unq_labels]=cosmo_index_unique({labels});
    nunq=numel(idxs);
    for k=1:nunq
        if any(cosmo_match(skip_test_for,unq_labels{1}(k)))
            continue
        end

        idx=idxs{k};

        first_key=keys{idx(1)};
        first_size=size(senstypes.(first_key).label);
        for j=1:numel(idx)
            key=keys{idx(j)};
            size_=size(senstypes.(key).label);

            % planar systems have two columns for channel labels,
            % all others have one
            if endswith(key,'_planar')
                ncol=2;
            else
                ncol=1;
            end

            if size_(2)~=ncol
                error('%s must have %d columns in .label',key,ncol);
            end

            % veryify that number of channel positions matches across
            % all siblings
            if ~isequal(first_size(1),size_(1))
                error(['size mismatch between %s and %s: number of '...
                        'channel positions mismatches (%d ~= %d)'],...
                        first_key,key,first_size(1),size_(1));
            end

        end

    end


function [keys,sens]=get_keys_sens(senstypes)
    keys=fieldnames(senstypes);
    sens=cellfun(@(label)senstypes.(label).sens,keys,...
                    'UniformOutput',false);

function tf=endswith(s,pf)
    tf=isempty(cosmo_strsplit(s,pf,-1));

function senstypes=add_modalities(senstypes)
    keys=get_keys_sens(senstypes);
    n=numel(keys);

    candidates={'meg_planar','meg_axial','meg','eeg',};
    ncandidates=numel(candidates);

    for k=1:n
        key=keys{k};
        type=[];

        if endswith(key,'_mag')
            type='meg_axial';
        elseif endswith(key,'_planar')
            type='meg_planar';
        elseif endswith(key,'_planar_combined')
            type='meg_planar_combined';
        else
            label=senstypes.(key).label;
            for j=1:ncandidates
                candidate=candidates{j};
                if ft_senstype(label,candidate)
                    type=candidate;
                    break
                end
            end
        end

        if isempty(type)
            warning('Could not find modality for %s', key);
            senstypes=rmfield(senstypes,key);
            continue;
        end

        senstypes.(key).type=type;
    end


function senstypes=old_fieldtrip_add_combined_planar(senstypes, key)
    % helper function to deal with old fieldtrip functions.
    % it's ugly because it resorts to cd-ing into FT's private directory to
    % run planarchannelset
    p=pwd();
    cleaner=onCleanup(@()cd(p));

    ft_dir=fileparts(which('ft_defaults'));
    ft_priv_dir=fullfile(ft_dir,'private');

    % prepare data
    label=senstypes.(key).label;
    label_planar=label(:,1:2);

    hdr=struct();
    hdr.Fs=[];
    hdr.label=label_planar(:);

    try
        % go into FT's private directory
        cd(ft_priv_dir);
        % try to get the planar channel set
        % (using private function; ugly)
        planar_channel_set=planarchannelset(hdr);
        planar_combined_key=[key '_planar_combined'];
        senstypes.(planar_combined_key)=senstypes.(key);
        senstypes.(planar_combined_key).label=planar_channel_set(:,3);
    catch
        caught_error=lasterror();
        if cosmo_wtf('is_matlab')
            ft_me=MException(caught_error.identifier,caught_error.message);
            base_me=MException('CoSMoMVPA:planarchannelset',...
                    'unable to get planar channel set with old Fieldtrip');
            both_me=addCause(base_me, ft_me);
            throw(both_me);
        else
            rethrow(caught_error);
        end
    end




