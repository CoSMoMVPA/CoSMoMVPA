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
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    cosmo_check_dataset(ds,'meeg');

    % for now only support ft-like output
    builder=@build_ft;
    hdr=builder(ds);

    % if filename was provided, store to file
    if nargin>1
        fn_parts=cosmo_strsplit(fn,'.');
        if numel(fn_parts)<2
            error('Filename needs extension');
        end
        ext=fn_parts{end};

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


function write_ft(fn,hdr)
    % use matlab save
    save(fn, '-struct', 'hdr');


function tf=is_ft_timelock(ft)
    tf=isstruct(ft) && ...
            isfield(ft,'dimord') && ...
            cosmo_match({ft.dimord}, {'rpt_chan_time','chan_time'});



function samples_field=ft_detect_samples_field(ds, is_single_sample)
    nfreq=sum(cosmo_match(ds.a.fdim.labels,{'freq'}));
    ntime=sum(cosmo_match(ds.a.fdim.labels,{'time'}));
    nchan=sum(cosmo_match(ds.a.fdim.labels,{'chan'}));

    if is_ds_source_struct(ds)
        if is_single_sample
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
                samples_field='powspctrm';
            else
                if is_single_sample
                    samples_field='avg';
                else
                    samples_field='trial';
                end
            end
            return
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

    is_single_sample=size(ds.samples,1)==1;
    if is_single_sample
        samples_label=cell(0);
    elseif cosmo_isfield(ds,'a.meeg.samples_label')
        samples_label={ds.a.meeg.samples_label};
    else
        samples_label={'rpt'};
    end

    % store the data
    samples_field=ft_detect_samples_field(ds, is_single_sample);

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
            ft=get_ft_sensor_samples_from_array(ds, arr, ...
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

function ft=get_ft_sensor_samples_from_array(ds, arr, key)
    if size(ds.samples,1)==1
        arr_size=size(arr);
        arr_ft=reshape(arr,[arr_size(2:end) 1]);
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
    else
        % use regular grid to determine
        ds_vol=cosmo_vol_grid_convert(ds,'tovol');
        ft.dim=ds_vol.a.vol.dim(:)';
    end



function ft=build_ft(ds)
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



