function hdr=cosmo_map2meeg(ds, fn)
% maps a dataset to a FieldTrip or EEGlab structure or file
%
% hdr=cosmo_map2meeg(ds[, fn])
%
% Inputs:
%    ds         dataset struct with field .samples with MEEG data
%    fn         optional filename to write output to. Supported extensions
%               are .txt (EEGlab time course) or .mat (FieldTrip data)
%
% Returns:
%    hdr        FieldTrip struct with the MEEG data
%
% Notes:
%    - a typical use case is to use this function to map the dataset to a
%      FieldTrip struct, then use FieldTrip to visualize the data
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
% NNO Jan 2014

    cosmo_check_dataset(ds,'meeg');

    % for now only support ft-like output
    builder=@build_ft;
    hdr=builder(ds);

    % if filename was provided, store to file
    if nargin>1
        ext=cosmo_strsplit(fn,'.',-1);
        if isempty(ext)
            error('Filename needs extension');
        end

        ext2writer=struct();
        ext2writer.txt=@write_eeglab_txt;
        ext2writer.mat=@write_ft;
        if ~isfield(ext2writer,ext);
            error('Unsupported extension %s', ext);
        end
        writer=ext2writer.(ext);
        % write the file
        writer(fn, hdr);
    end


function write_eeglab_txt(fn, hdr)

    dimords=cosmo_strsplit(hdr.dimord,'_');
    if numel(dimords)~=3 || ~isequal(dimords(2:3),{'chan','time'})
        error('Only support timelock data with dimord=..._chan_time');
    end

    data=hdr.trial;

    % make an array to contain output data in 2D eeglab form
    [ntrial, nchan, ntime]=size(data);
    arr=zeros(nchan+1,ntrial*ntime);

    % set time dimension - and convert seconds to miliseconds
    arr(1,:)=repmat(hdr.time(:)*1000,ntrial,1);

    % set channel data
    for k=1:nchan
        arr(k+1,:)=reshape(squeeze(data(:,k,:)),[],1);
    end

    % prepare header
    header=cosmo_strjoin([{''}, hdr.label(:)'],'\t');

    % prepare pattern to write data in array
    arr_pat=cosmo_strjoin(repmat({'%.4f'},1,nchan+1),'\t');

    % write data
    fid=fopen(fn,'w');
    fprintf(fid,[header '\n']);
    fprintf(fid,[arr_pat '\n'], arr);
    fclose(fid);


function write_ft(fn,hdr)
    % use matlab save
    save(fn, '-struct', hdr);


function samples_field=ft_detect_samples_field(ds)
    nfreq=sum(cosmo_match(ds.a.fdim.labels,{'freq'}));
    ntime=sum(cosmo_match(ds.a.fdim.labels,{'time'}));
    nchan=sum(cosmo_match(ds.a.fdim.labels,{'chan'}));
    if nchan>=1 && ntime>=1
        if nfreq>=1
            samples_field='powspctrm';
        else
            samples_field='trial';
        end
        return
    end

    samples_field=ds.a.meeg.samples_field;

function ft=build_ft(ds)

    % get fieldtrip-specific fields from header
    ft=ds.a.hdr_ft;

    % unflatten the array
    [arr, dim_labels]=cosmo_unflatten(ds);
    [arr, dim_labels]=cosmo_unflatten(ds,[],NaN);

    % store the data
    samples_field=ft_detect_samples_field(ds);
    ft.(samples_field)=arr;

    % set dimord
    samples_label=ds.a.meeg.samples_label;

    underscore2dash=@(x)strrep(x,'_','-');

    dimord_labels=[{samples_label} cellfun(underscore2dash,dim_labels,...
                                            'UniformOutput',false)];
    ft.dimord=cosmo_strjoin(dimord_labels,'_');

    % store each feature attribute dimension value
    ndim=numel(dim_labels);
    for dim=1:ndim
        dim_label=dim_labels{dim};
        if strcmp(dim_label,'chan')
            dim_label='label';
        end
        ft.(dim_label)=ds.a.dim.values{dim};
    end

    if isfield(ds.sa,'trialinfo')
        ft.trialinfo=ds.sa.trialinfo;
    end

    if isfield(ds.sa,'cumtapcnt')
        ft.cumtapcnt=ds.sa.cumtapcnt;
    end

    % if fieldtrip is present
    if cosmo_check_external('fieldtrip',false) && ...
                isequal(ft_datatype(ft),'unknown')
        cosmo_warning('fieldtrip does not approve of this dataset');
    end
