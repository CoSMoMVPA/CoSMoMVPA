function hdr=cosmo_map2meeg(ds, fn)
% maps a dataset to a FieldTrip or EEGlab structure or file
%
% hdr=cosmo_map2meeg(ds[, fn])
%
% Inputs:
%    ds               dataset struct with field .samples with MEEG data
%    fn               output filename or extension. If a filename,
%                     the following extentions are supported:
%                       .mat :        FieldTrip time-locked or
%                                     time-frequency  data at  either the
%                                     sensor or source level.
%                       .txt :        exported EEGLab with timelocked data.
%                       .daterp       time-locked               }
%                       .icaerp       ICA time-locked           } EEGLab
%                       .dattimef     time-freq                 }
%                       .icatimef     ICA time-freq             }
%                       .datitc       inter-trial coherence     }
%                       .icaitc       ICA inter-trial coherence }
%                     To avoid writing a file, but get output in the hdr
%                     field, use one of the extensions above but with the
%                     dot ('.') replaced by a hyphen ('-'), for example
%                     '-dattimef' for time-freq data.
%
% Returns:
%    hdr        FieldTrip or EEGLAB struct with the MEEG data
%
% Notes:
%    - a typical use case is to use this function to map the dataset to a
%      FieldTrip struct, then use FieldTrip to visualize the data
%    - there is currently no support for writing EEGLAB 'ersp' data.
%
% Examples:
%     % convert a dataset struct to a FieldTrip struct
%     ft=cosmo_map2meeg(ds);
%
%     % store a dataset in FieldTrip file
%     cosmo_map2meeg(ds,'fieldtrip_data.mat');
%
%     % store a timeseries dataset in an EEGlab text file
%     cosmo_map2meeg(ds,'eeglab_data.txt');
%
%     % convert a dataset structure to a FieldTrip structure
%     ft=cosmo_map2meeg(ds,'-mat');
%
%     % convert a time-lock dataset to an EEGLAB structure
%     eeglab_daterp=cosmo_map2meg(ds,'-daterp');
%
%     % write EEGLAB time-frequency data
%     cosmo_map2meeg(ds,'timefreq.dattimef');
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2
        fn='-mat';
    end

    cosmo_check_dataset(ds,'meeg');

    % for now only support ft-like output
    [ext,img_format,write_to_file]=find_img_format(fn);

    builder=img_format.builder;
    hdr=builder(ds,ext);

    % if filename was provided, store to file
    if write_to_file
        writer=img_format.writer;
        % write the file
        writer(fn, hdr);
    end


function [ext,img_format,write_to_file]=find_img_format(fn)
    if ~ischar(fn) || isempty(fn)
        error('filename must be non-empty string');
    end

    write_to_file=fn(1)~='-';
    if write_to_file
        ext=get_filename_extension(fn);
    else
        ext=fn(2:end);
    end

    all_formats=get_all_supported_img_formats();
    keys=fieldnames(all_formats);

    idx=find(cellfun(@(x)cosmo_match({ext},all_formats.(x).exts),keys));
    n_match=numel(idx);
    assert(n_match<=1); % cannot have multiple matches

    if n_match==0
        error('Image format not found for extension ''%s''',ext)
    end

    img_format=all_formats.(keys{idx});

function ext=get_filename_extension(fn)
    fn_parts=cosmo_strsplit(fn,'.');
    if numel(fn_parts)<2
        error('Filename needs extension');
    end
    ext=fn_parts{end};



function all_formats=get_all_supported_img_formats()
    all_formats=struct();

    % EEGLAB text
    all_formats.eeglab_txt.exts={'txt'};
    all_formats.eeglab_txt.builder=@build_ft;
    all_formats.eeglab_txt.writer=@write_eeglab_txt;

    % EEGLAB matlab
    all_formats.eeglab.exts={  'daterp',...
                               'icaerp',...
                               'dattimef',...
                               'icatimef',...
                               'datitc',...
                               'icaitc'};
    all_formats.eeglab.builder=@build_eeglab;
    all_formats.eeglab.writer=@write_struct_as_mat;

    all_formats.ft.exts={'mat'};
    all_formats.ft.builder=@build_ft;
    all_formats.ft.writer=@write_struct_as_mat;


function write_struct_as_mat(fn,hdr)
    % use matlab save
    save(fn,'-mat','-struct','hdr');

function tf=choose_equal_or_exception(value,if_true,if_false,desc)
    if isequal(value,if_true)
        tf=true;
    elseif isequal(value,if_false)
        tf=false;
    else
        error('value for %s is not supported', desc);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EEGLAB text
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function write_eeglab_txt(fn, hdr)
    if ~is_ft_timelock(hdr)
        error('Only time-lock data is supported for EEGlab data');
    end

    % prepare header
    header=[cosmo_strjoin([{' '}, hdr.label(:)',{''}],'\t') '\n'];

    % prepare body
    data=hdr.trial;
    [ntrial, nchan, ntime]=size(data);
    arr=zeros(ntrial*ntime,nchan+1);

    % set time dimension - and convert seconds to miliseconds
    arr(:,1)=repmat(hdr.time(:)*1000,ntrial,1);
    arr(:,2:end)=reshape(shiftdim(data,2),ntime*ntrial,nchan);

    % prepare pattern to write data in array
    arr_pat=[cosmo_strjoin(repmat({'%.4f'},1,nchan+1),'\t') '\n'];

    % write data
    fid=fopen(fn,'w');
    fprintf(fid,header);
    fprintf(fid,arr_pat,arr'); % transpose because order is row then column
    fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EEGLAB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s=build_eeglab(ds,ext)
    fdim=ds.a.fdim;
    fdim_labels=fdim.labels(:);
    fdim_values=fdim.values(:);

    has_ica=choose_equal_or_exception(fdim_labels{1},'comp','chan',...
                                        'fdim channel label');
    has_freq=choose_equal_or_exception(fdim_labels(2:end),...
                                        {'freq';'time'},{'time'},...
                                        'fdim dimension labels');
    if has_ica
        chan_prefix='comp';
    else
        chan_prefix='chan';
    end

    % preparet output
    s=struct();

    % set frequency, if present
    if has_freq
        s.freqs=fdim_values{2};
        freq_sz=numel(s.freqs);

        datatype_candidates={'timef','itc'};
        msk=cellfun(@(x)contains_string(ext,x),datatype_candidates);
        idx=find(msk);

        assert(numel(idx)==1,'this should not happen') % weird data
        datatype=datatype_candidates{idx};

        chan_suffix=sprintf('_%s',datatype);
    else
        freq_sz=[];
        datatype='erp';
        chan_suffix='';
    end

    % set datatype
    s.datatype=upper(datatype);

    % deal with feature dimensions
    nsamples=size(ds.samples,1);
    ntime=numel(fdim_values{end});
    each_chan_sz=[nsamples,freq_sz,ntime]; % with or without freq

    chan_names=fdim_values{1};
    nchan=numel(chan_names);

    % unflattten the array
    arr=cosmo_unflatten(ds,2);
    assert(nchan==size(arr,2));

    for k=1:nchan
        chan_arr=reshape(arr(:,k,:),each_chan_sz);
        key=sprintf('%s%d%s',chan_prefix,k,chan_suffix);

        % it seems that for freq data, single trial data is the last
        % dimension, whereas for erp data, single trial data is the first
        % dimension.
        if has_freq
            chan_arr=shiftdim(chan_arr,1);
         % note: no shift for erp data, as time is already the first
         % dimension
        end
        s.(key)=chan_arr;
    end

    if ~has_ica
        s.chanlabels=chan_names;
    end

    s.times=fdim_values{end};
    s=set_parameters_if_present(s,ds);


function tf=contains_string(haystack,needle)
    tf=~isempty(strfind(haystack,needle));

function s=set_parameters_if_present(s,ds)
    if cosmo_isfield(ds,'a.meeg.parameters')
        s.parameters=ds.a.meeg.parameters;
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FieldTrip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tf=is_ft_timelock(ft)
    tf=isstruct(ft) && ...
            isfield(ft,'dimord') && ...
            cosmo_match({ft.dimord}, {'rpt_chan_time',...
                                        'subj_chan_time',...
                                        'chan_time'});



function samples_field=ft_detect_samples_field(ds, is_without_samples_dim)
    nfreq=sum(cosmo_match(ds.a.fdim.labels,{'freq'}));
    ntime=sum(cosmo_match(ds.a.fdim.labels,{'time'}));
    nchan=sum(cosmo_match(ds.a.fdim.labels,{'chan'}));

    has_samples_field=cosmo_isfield(ds,'a.meeg.samples_field');

    if is_ds_source_struct(ds)
        if is_without_samples_dim
            main_field='avg';
        else
            main_field='trial';
        end

        if cosmo_match({'mom'},ds.a.fdim.labels)
            sub_field='mom';
        else
            sub_field='pow';
        end

        samples_field=sprintf('%s.%s',main_field,sub_field);

        return
    else
        if nchan>=1 && ntime>=1
            if nfreq>=1
                % time-freq data
                samples_field='powspctrm';
                return;
            end

            if is_without_samples_dim
                % time-locked, single sample
                samples_field='avg';
                return;
            end


            if ~has_samples_field
                % time-locked, multiple trials
                samples_field='trial';
                return
            end
        end
    end


    % fallback option
    samples_field=ds.a.meeg.samples_field;


function tf=is_ds_source_struct(ds)
    tf=isfield(ds,'fa') && isfield(ds.fa,'pos') && ...
                cosmo_isfield(ds,'a.fdim.labels') && ...
                cosmo_match({'pos'},ds.a.fdim.labels);



function [ft, samples_label, dim_labels]=get_ft_samples(ds)
    [arr, dim_labels]=cosmo_unflatten(ds,[],'set_missing_to',NaN,...
                                            'matrix_labels',{'pos'});

    if cosmo_isfield(ds,'a.meeg.samples_label')
        samples_label={ds.a.meeg.samples_label};
    else
        if size(ds.samples,1)==1
            samples_label=cell(0);
        else
            samples_label={'rpt'};
        end
    end

    is_without_samples_dim=isempty(samples_label);

    % store the data
    samples_field=ft_detect_samples_field(ds, is_without_samples_dim);

    samples_field_keys=cosmo_strsplit(samples_field,'.');
    nsubfields=numel(samples_field_keys)-1;

    if xor(nsubfields>0,is_ds_source_struct(ds))
        error(['Found sample field %s, which is incompatible '...
                    'with the dataset being in source space or not. '...
                    'This is not supported'],samples_field);
    end

    switch nsubfields
        case 0
            % non-source data
            ft=get_ft_sensor_samples_from_array(arr, samples_label, ...
                                        samples_field_keys{1});

        case 1
            % source data
            ft=get_ft_source_samples_from_array(ds, arr, ...
                                        samples_field_keys{1},...
                                        samples_field_keys{2});

        otherwise
            error(['Found sample field %s with more than one '...
                        'subfield %s'],samples_field);
    end

function ft=get_ft_sensor_samples_from_array(arr, samples_label, key)
    if isempty(samples_label)
        arr_size=size(arr);
        size_at_least_2d=[arr_size(2:end) 1];
        arr_ft=reshape(arr,size_at_least_2d);
    else
        arr_ft=arr;
    end

    ft=struct();
    ft.(key)=arr_ft;


function ft=get_ft_source_samples_from_array(ds, arr, key, sub_key)
    ft=init_ft_source_fields(ds);

    arr_size=size(arr);
    nsamples=arr_size(1);
    remainder_size=arr_size(2:end);


    switch sub_key
        case 'pow'
            converter=@convert_ft_source_vector2array;

        case 'mom'
            converter=@convert_ft_source_vector2cell;

        otherwise
            error('unsupported key %s', sub_key);
    end

    arr_sample_mat=reshape(arr,nsamples,[]);
    struct_cell=cell(1,nsamples);

    for j=1:nsamples
        struct_cell{j}=converter(arr_sample_mat(j,:),remainder_size, ...
                                                ft.inside);
    end

    arr_struct=struct(sub_key,struct_cell);
    ft.(key)=arr_struct;

    key2method=struct();
    key2method.avg='average';
    key2method.trial='rawtrial';

    ft.method=key2method.(key);

function arr=convert_ft_source_vector2array(arr_vec, remainder_size, ...
                                                is_inside)
    arr=reshape(arr_vec,[remainder_size 1]);
    arr(~is_inside)=NaN;


function arr_cell=convert_ft_source_vector2cell(arr_vec,remainder_size,...
                                                is_inside)
    nsensors=remainder_size(1);
    remainder_remainder_size=[remainder_size(2:end) 1 1];

    arr_sens_mat=reshape(arr_vec,nsensors,[]);
    arr_cell=cell(nsensors,1);
    for k=1:nsensors
        if is_inside(k)
            arr_cell{k}=reshape(arr_sens_mat(k,:),...
                                        remainder_remainder_size);
        end
    end




function ft=ds_copy_fields_with_matching_sample_size(ft,ds,keys)
    if ~isfield(ds,'sa')
        return;
    end

    nsamples=size(ds.samples,1);
    for k=1:numel(keys)
        key=keys{k};
        if isfield(ds.sa,key)
            value=ds.sa.(key);
            if size(value,1)==nsamples
                ft.(key)=value;
            end
        end
    end

function ft=init_ft_source_fields(ds)
    ft=struct();
    % for MEEG source data, set the .inside field
    assert(is_ds_source_struct(ds));
    [dim,pos_index]=cosmo_dim_find(ds,'pos',true);

    % set the inside field
    inside_ds=cosmo_slice(ds,1,1);
    inside_ds.samples(:)=1;

    inside_arr=cosmo_unflatten(inside_ds,2,'matrix_labels',{'pos'});

    inside_arr_pos_first=shiftdim(inside_arr,pos_index);
    n=size(inside_arr_pos_first,1);
    inside_matrix_pos_first=reshape(inside_arr_pos_first,n,[]);
    ft.inside=any(inside_matrix_pos_first,2);

    if cosmo_isfield(ds,'a.meeg.dim')
        ft.dim=ds.a.meeg.dim;
    end

    if cosmo_isfield(ds,'a.meeg.tri');
        ft.tri=ds.a.meeg.tri;
    end


function ft=build_ft(ds,unused)
    % get fieldtrip-specific fields from header
    [ft, samples_label, dim_labels]=get_ft_samples(ds);


    % set dimord
    underscore2dash=@(x)strrep(x,'_','-');

    dimord_labels=[samples_label; ...
                    cellfun(underscore2dash,dim_labels(:),...
                                            'UniformOutput',false)];
    if ~is_ds_source_struct(ds)
        ft.dimord=cosmo_strjoin(dimord_labels,'_');
    end

    % store each feature attribute dimension value
    ndim=numel(dim_labels);
    for dim=1:ndim
        dim_label=dim_labels{dim};
        dim_value=ds.a.fdim.values{dim};
        switch dim_label
            case 'mom'
                % ignore
                continue
            case 'chan'
                dim_label='label';
            case 'pos'
                dim_value=dim_value';
            otherwise
                % time or freq; fieldtrip will puke with column vector
                dim_value=dim_value(:)';
        end
        ft.(dim_label)=dim_value;
    end

    ft=ds_copy_fields_with_matching_sample_size(ft,ds,...
                                    {'rpt','trialinfo','cumtapcnt'});

    % if fieldtrip is present
    if cosmo_check_external('fieldtrip',false) && ...
                isequal(ft_datatype(ft),'unknown')
        cosmo_warning('fieldtrip does not approve of this dataset');
    end



