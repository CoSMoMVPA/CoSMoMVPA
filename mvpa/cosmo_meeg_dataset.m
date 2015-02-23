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
    [data, data_field]=get_data_ft(ft);

    [dim_labels, dim_values, has_sample_field]=get_fdim_ft(ft);

    if ~has_sample_field
        data=reshape(data,[1 size(data)]);
    end

    ds=cosmo_flatten(data, dim_labels, dim_values);
    ds.a.meeg.samples_field=data_field;

    nsamples=size(ds.samples,1);
    ds.sa=copy_fields(ft,nsamples,{'rpt','trialinfo','cumtapcnt'});


function [data, data_field]=get_data_ft(ft)
    % helper function to get the data from a fieldtrip struct
    data_fields={'trial','avg','fourierspctrm','powspctrm','pow'};
    ndata_fields=numel(data_fields);

    data=ft;
    data_field_cell=cell(ndata_fields,1);
    pos=0;
    for k=1:ndata_fields
        data_field=data_fields{k};
        if isfield(data, data_field)
            % deal with source data with multiple trials
            nsamples=numel(data);
            if isstruct(data) && nsamples>1
                sz=size(data(1).(data_field));
                data=reshape(cat(1,data.(data_field)),[nsamples sz]);
            else
                data=data.(data_field);
            end

            pos=pos+1;
            data_field_cell{pos}=data_field;
        end
    end

    if isempty(data_field_cell)
        error('Could not find data in fieldtrip struct');
    end

    data_field=cosmo_strjoin(data_field_cell(1:pos),'.');


function [dim_labels, dim_values, has_sample_field]=get_fdim_ft(ft)
    % helper function to get dimensions from fieldtrip .dimord

    % first column: .dimord label
    % second colum: fieldname in ft struct
    ft_data_labels={'chan','label';...
                    'freq','freq';...
                    'time','time'};
    if isfield(ft,'dimord')
        dimord_labels=cosmo_strsplit(ft.dimord,'_');
    else
        % source data, ignore the data labels
        dimord_labels=intersect(fieldnames(ft),ft_data_labels);
    end


    ndimord_labels=numel(dimord_labels);
    sample_fields={'rpt','trial'};

    has_sample_field=any(cosmo_match(sample_fields,dimord_labels));

    % allocate space for output
    dim_labels=cell(1,ndimord_labels);
    dim_values=cell(1,ndimord_labels);

    pos=0;
    for k=1:ndimord_labels
        label=dimord_labels{k};

        if cosmo_match({label},sample_fields)
            continue;
        end

        idx=find(cosmo_match(ft_data_labels(:,1),label));
        if numel(idx)~=1
            error('unsupported element in .dimord: %s', label);
        end

        pos=pos+1;

        % store label
        dim_labels{pos}=ft_data_labels{idx,1};

        % store values
        value=ft.(ft_data_labels{idx,2});
        dim_values{pos}=value(:);
    end

    if isfield(ft,'pos')
        pos=pos+1;
        dim_labels{pos}='pos';
        dim_values{pos}=1:size(ft.pos,1);
    end

    dim_labels=dim_labels(1:pos);
    dim_values=dim_values(1:pos);


function r=copy_fields(ft,nsamples,keys)
    % helper function to copy fields in keys if they have nsamples values
    r=struct();
    for k=1:numel(keys)
        key=keys{k};
        if isfield(ft,key)
            value=ft.(key);
            nrows=size(value,1);
            if nrows~=nsamples
                error('field %s has %d rows, expected %d', ...
                                key, nrows, nsamples)
            end
            r.(key)=value;
        end
    end


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

