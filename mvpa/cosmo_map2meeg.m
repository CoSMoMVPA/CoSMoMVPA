function hdr=cosmo_map2meeg(ds, fn)

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
    if numel(dimords)~=3 || ~isequal({dimords{2:3}},{'chan','time'})
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
    header=cosmo_strjoin({'', hdr.label{:}},'\t');

    % prepare pattern to write data in array
    arr_pat=cosmo_strjoin(repmat({'%.4f'},1,nchan+1),'\t');

    fid=fopen(fn,'w');
    fprintf(fid,[header '\n']);
    fprintf(fid,[arr_pat '\n'], arr);
    fclose(fid);
    

function write_ft(fn,hdr)   
    % use matlab save
    save(fn, '-struct', hdr);

        
function ft=build_ft(ds)

    % get fieldtrip-specific fields from header
    ft=ds.a.hdr_ft;

    % unflatten the array
    [arr, dim_labels]=cosmo_unflatten(ds);

    % store the data
    samples_field=ds.a.meeg.samples_field;
    ft.(samples_field)=arr;

    % set dimord 
    samples_label=ds.a.meeg.samples_label;
    dimord_labels={samples_label dim_labels{:}};
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
                ~isempty(strmatch(ft_datatype(ft),'unknown'))
        error('conversion error - fieldtrip does not approve of this dataset');
    end