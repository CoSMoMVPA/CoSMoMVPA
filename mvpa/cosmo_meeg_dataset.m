function ds=cosmo_meeg_dataset(filename, varargin)
% Returns a dataset structure based on MEEG data
%
% ds=cosmo_meeg_dataset(filename, varargin)
%
% Inputs:
%   filename          filename of MEEG data to be loaded. Currently this
%                     can be a .mat file (for FieldTrip) with timelocked or
%                     time-frequency data, or .txt (exported EEGLab) for
%                     timelocked data. Alternatively it can be a FieldTrip
%                     struct with timelocked or time-frequency data.
%   'targets', t      Px1 targets for P samples; these will be stored in
%                     the output as ds.sa.targets
%   'chunks', c       Px1 chunks for P samples; these will be stored in the
%                     the output as ds.sa.chunks
%
% Returns:
%   ds                dataset struct with the following fields
%     .samples        PxQ for P samples and Q features.
%     .sa.targets     Px1 sample targets (if provided)
%     .sa.chunks      Px1 sample chunks (if provided)
%     .a
%       .hdr_{F}           header information for format F. Currently
%                          F is always 'ft'.
%       .meeg
%         .sample_field   name of sample field. One of 'fourierspctrm',
%                         'powspctrm', or 'trial'.
%         .samples_type   'timelock' or 'timefreq'.
%         .samples_label  Usually 'rpt'; or the first field of .dimord
%                         for FieldTrip data
%       .dim
%         .labels     1xS cell struct with labels for the feature
%                     dimensions of the input. Usually this is
%                     {'chan','time'} or {'chan','freq','time'}.
%         .values     1xS cell struct with values associated with .labels.
%                     If the K-th value has N_K values, this means that
%                     the feature dimension .labels{K} takes the
%                     values in .values{K}. For example, if
%                     .labels{1}=='chan', then .values{1} contains the
%                     channel labels.
%     .fa
%       .{D}          if D==a.fdim.labels{K} is the label for the K-th
%                     feature dimension, then .{D} contains the
%                     indices referencing a.fdim.values. Thus, all values in
%                     .{D} are in the range 1:N_K if a.fdim.values{K} has
%                     N_K values, and the J-th feature has dimension value
%                     .dim.values{K}(.{D}(J)) in the K-th dimension.
%
% Notes:
%  - The resulting dataset can be mapped back to MEEG format using
%    cosmo_map2meeg.
%  - if the input contains data from a single sample (such as an average)
%    the .sample_field is set to .trial, and mapping back to MEEG format
%    adds a singleton dimension to the .trial data output field.
%  - Most MVPA applications require that .sa.targets (experimental
%    condition of each sample) and .sa.chunks (partitioning of the samples
%    in independent sets) are set, either by using this function or
%    manually afterwards.
%
% Dependency:
%  - Loading Fieldtrip structures requires the FieldTrip toolbox:
%      http://http://fieldtrip.fcdonders.nl
%
% See also: cosmo_map2meeg
%
% NNO Sep 2013

    % Input parsing stuff

    defaults=struct();
    defaults.targets=[];
    defaults.chunks=[];

    params = cosmo_structjoin(defaults, varargin);

    if cosmo_check_dataset(filename,'meeg',false)
        % it is already a dataset, so return it
        ds=filename;
        return
    end

    % get image format and verify it is supported
    img_format=get_img_format(filename);
    supported_image_formats=get_supported_image_formats();

    % check externals
    cosmo_check_external(supported_image_formats.(img_format).externals);

    % get the reader
    reader=supported_image_formats.(img_format).reader;

    % read the dataset
    ds=reader(filename);

    % set targets and chunks
    ds=set_vec_sa(ds,'targets',params.targets);
    ds=set_vec_sa(ds,'chunks',params.chunks);


    % check consistency
    cosmo_check_dataset(ds,'meeg');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% general helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ds=set_vec_sa(ds, label, values)
    if isempty(values)
        return;
    end
    if numel(values)==1
        nsamples=size(ds.samples,1);
        values=repmat(values,nsamples,1);
    end
    ds.sa.(label)=values(:);


function img_format=get_img_format(filename)
    % helper functgion to detect image format based on filename.
    % uses 'get_supported_image_formats'.
    img_formats=get_supported_image_formats();

    fns=fieldnames(img_formats);
    for k=1:numel(fns)
        fn=fns{k};

        img_spec=img_formats.(fn);
        if img_spec.file_matcher(filename)
            img_format=fn;
            return
        end
    end
    error('Unknown image format');

function img_formats=get_supported_image_formats()
    % helper function to return the image format based on the filename
    img_formats=struct();

    % helper function to see if a filename ends with a certain string.
    % uses currying - who doesn't like curry?
    endswith=@(ext) @(fn) ischar(fn) && isempty(cosmo_strsplit(fn,ext,-1));

    % eeglab txt files
    img_formats.eeglab_txt.file_matcher=endswith('.txt');
    img_formats.eeglab_txt.reader=@read_eeglab_txt;
    img_formats.eeglab_txt.externals={};

    % fieldtrip
    % XXX any .mat file is currently assumed to be a fieldtrip struct
    img_formats.ft.file_matcher=endswith('.mat');
    img_formats.ft.reader=@read_ft;
    img_formats.ft.externals={'fieldtrip'};

    % fieldtrip matlab struct
    img_formats.ft_struct.file_matcher=@(x) isstruct(x) && ...
                                ~strcmp('unknown',isempty(ft_datatype(x)));
    img_formats.ft_struct.reader=@convert_ft;
    img_formats.ft_struct.externals={'fieldtrip'};




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fieldtrip helper function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ds=read_ft(filename)
    % reads it from a .mat data file
    ft=importdata(filename);
    ds=convert_ft(ft);


function ds=convert_ft(ft)
    %[data, sample_field]=get_data_ft(ft);
    %[dim_labels, dim_values, has_sample_field]=get_fdim_ft(ft,...
                                                    %sample_field);
    [data, samples_field, dim_labels, dim_values]=get_ft_data(ft);
    %if ~has_sample_field
    %    data=reshape(data,[1 size(data)]);
    %end

    %if numel(dim_labels)==1
    %    data=reshape(data,size(data,1),[]);
    %end

    ds=cosmo_flatten(data, dim_labels, dim_values,2,...
                                'matrix_labels',get_ft_matrix_labels());
    ds.a.meeg.samples_field=samples_field;

    if is_ft_source_struct(ft)
        ds=set_source_fa_inside(ds,dim_labels,dim_values,ft.inside);
    end

    nsamples=size(ds.samples,1);
    ft_fields={'rpt','trialinfo','cumtapcnt'};
    ds.sa=copy_fields_for_matching_sample_size(ft,nsamples,ft_fields);

function [data,samples_field,dim_labels,dim_values]=get_ft_data(ft)
    [data, samples_field]=get_data_ft(ft);
    [dim_labels,ft_dim_labels]=get_ft_dim_labels(ft);

    nlabels=numel(dim_labels);
    dim_values=cell(nlabels,1);
    matrix_labels=get_ft_matrix_labels();
    for k=1:nlabels
        label=ft_dim_labels{k};
        value=ft.(label);
        if cosmo_match({label},matrix_labels)
            dim_values{k}=value';
        else
            dim_values{k}=value(:)';
        end
    end


function labels=get_ft_matrix_labels()
    labels={'pos'}    ;

function [cosmo_dim_labels,ft_dim_labels]=get_ft_dim_labels(ft)
    cosmo_ft_dim_labels={ 'pos','pos'
                          'chan','label';...
                          'freq','freq';...
                          'time','time';
                                  };
    if isfield(ft,'dimord')
        dimord_labels=cosmo_strsplit(ft.dimord,'_');

        sample_field=get_sample_dimord_field(ft);
        sample_msk=cosmo_match(dimord_labels, sample_field);

        dimord_labels_without_sample=dimord_labels(~sample_msk);

        labels_msk=cosmo_match(cosmo_ft_dim_labels(:,1),...
                                dimord_labels_without_sample);
    else
        % source data
        keys=fieldnames(ft);
        labels_msk=cosmo_match(cosmo_ft_dim_labels(:,2),keys);

    end

    ft_dim_labels=cosmo_ft_dim_labels(labels_msk,2);
    cosmo_dim_labels=cosmo_ft_dim_labels(labels_msk,1);

function sample_field=get_sample_dimord_field(ft)
    sample_field='';

    sample_dimord_fields={'rpt'};
    if isfield(ft,'dimord')
        ft_dimord_fields=cosmo_strsplit(ft.dimord,'_');
        msk=cosmo_match(ft_dimord_fields,sample_dimord_fields);
        if any(msk)
            assert(sum(msk)==1)
            sample_field=sample_dimord_fields{msk};
        end
    end


function sa=copy_fields_for_matching_sample_size(ft,nsamples,keys)
    n=numel(keys);

    sa=struct();
    for k=1:n
        key=keys{k};
        if isfield(ft,key)
            value=ft.(key);
            if size(value,1)==nsamples
                sa.(key)=value;
            end
        end
    end







function ds=set_source_fa_inside(ds,dim_labels,dim_values,inside_mask)
    ndim=numel(dim_labels);
    dim_sizes=cellfun(@numel,dim_values);

    pos_idx=find(cosmo_match(dim_labels,'pos'),1);
    assert(~isempty(pos_idx),['this function should only be called '...
                                'with source datasets']);

    inside_vec_size=[1 ones(1,ndim)];
    inside_vec_size(1+pos_idx)=numel(inside_mask);
    inside_array_vec=reshape(inside_mask, inside_vec_size);

    other_dim_size=[1 dim_sizes(:)'];
    other_dim_size(1+pos_idx)=1;

    inside_array=repmat(inside_array_vec,other_dim_size);
    inside_ds=cosmo_flatten(inside_array, dim_labels, dim_values,2,...
                                         'matrix_labels',{'pos'});
    ds.fa.inside=inside_ds.samples;




function [data, sample_field]=get_data_ft(ft)
    % helper function to get the data from a fieldtrip struct
    sample_fields={'trial','avg','fourierspctrm','powspctrm','pow'};
    nsample_fields=numel(sample_fields);

    ft_data=ft;
    data_field_cell=cell(nsample_fields,1);
    pos=0;
    for k=1:nsample_fields
        sample_field=sample_fields{k};
        if isfield(ft_data(1), sample_field)
            if isstruct(ft_data(1).(sample_field))
                % field with subfield
                ft_data=ft_data.(sample_field);
            else
                % deal with source data with multiple trials
                if is_ft_source_struct(ft)
                    nsamples=numel(ft_data);
                    feature_size=size(ft_data(1).(sample_field));

                    data_cell=cell(nsamples,1);
                    for j=1:nsamples
                        data_arr=ft_data(j).(sample_field);
                        data_cell{j}=reshape(data_arr,[1 feature_size]);
                    end

                    data=cat(1,data_cell{:});
                else
                    assert(numel(ft_data)==1)

                    data=ft.(sample_field);
                    if isempty(get_sample_dimord_field(ft))
                        % no 'rpt_...'
                        data=reshape(data,[1 size(data)]);
                    end
                end
            end
            pos=pos+1;
            data_field_cell{pos}=sample_field;
        end
    end

    if pos==0
        error('Could not find data in fieldtrip struct');
    end

    sample_field=cosmo_strjoin(data_field_cell(1:pos),'.');


function tf=is_ft_source_struct(ft)
    tf=isfield(ft,'pos') && isfield(ft,'inside');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% eeglab helper function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ds=read_eeglab_txt(fn)
    % reads eeglab time series data. returns data in fieldtrip-like format
    fid=fopen(fn);

    header_line=fgetl(fid); % read header
    chan_labels=cosmo_strsplit(header_line,'\t');
    chan_labels=chan_labels(2:(end-1)); % omit first & last bogus element

    nchan=numel(chan_labels);
    data_pat=cosmo_strjoin(repmat({'%n'},1,nchan+1),'\t');

    % read data from file
    cell_data=textscan(fid,data_pat);

    % check all data was read
    neg_one=fgetl(fid);
    fgetl(fid);
    if neg_one~=-1
        error('Could not read all data from %s', fn);
    end

    %%%%%%%%%%%%%%%
    % data consistency checks

    % timepoints are in the first column, data in other columns
    timepoints=cell_data{1};
    nrows=numel(timepoints);

    % check that timepoints are increasing for each trial, and repeating
    t_start=min(timepoints);
    t_end=max(timepoints);

    pos_start=find(timepoints==t_start,1,'first');
    pos_end=find(timepoints==t_end,1,'first');

    % onsets of the first trial
    t_trial=timepoints(pos_start:pos_end);

    % number of timepoints per trial
    ntime=numel(t_trial);

    % number of trials
    ntrial=nrows/ntime;

    % ensure time points are set properly
    if pos_start~=1 || round(ntrial)~=ntrial || ...
            ~isequal(repmat(t_trial,ntrial,1), timepoints)
        error('Data not contiguous or unexpected order of time points');
    end


    %%%%%%%%%%%%%%%
    % put the data in 3D array
    data=zeros(ntrial,nchan,ntime);
    for chan=1:nchan
        chan_data=cell_data{chan+1}; % skip first column as it has timepoints
        data(:,chan,:)=reshape(chan_data,ntime,ntrial)';
    end

    %%%%%%%%%%%%%%%
    % flatten and make it a dataset
    % (convert miliseconds to seconds along the way)
    dim_labels={'chan','time'};
    dim_values={chan_labels, .001*t_trial'};

    % make a dataset
    ds=cosmo_flatten(data, dim_labels, dim_values);

    % set datatype to timelock-ish in fieldtrip-compatible way
    ds.a.meeg.samples_field='trial';
    ds.a.meeg.samples_type='timelock';
    ds.a.meeg.samples_label='rpt';

    % set sample info
    ds.sa.(ds.a.meeg.samples_label)=(1:ntrial)';

