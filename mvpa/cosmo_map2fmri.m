function hdr=cosmo_map2fmri(dataset, fn)
% maps a dataset structure to a nifti structure or file
% 
% Usage 1: hdr=cosmo_map2fmri(dataset) returns a header structure
% Usage 2: cosmo_map2fmri(dataset, fn) saves dataset to a volumetric file.
%
% - for NIFTI files, it requires the following toolbox:
%   http://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
%   (note that his toolbox is included in CoSMoMVPA in /externals)
% - for Brainvoyager files (.vmp and .vtc), it requires the NeuroElf
%   toolbox, available from: http://neuroelf.net
% - for AFNI files (+{orig,tlrc}.{HEAD,BRIK[.gz]}) it requires the AFNI
%   Matlab toolbox, available from: http://afni.nimh.nih.gov/afni/matlab/
%
% NNO Aug 2013
    cosmo_check_dataset(dataset, 'fmri');

    img_formats=get_img_formats();
    img_format=get_img_format(dataset, img_formats);
    
    externals=img_formats.(img_format).externals;
    cosmo_check_external(externals);
    
    builder=img_formats.(img_format).builder;
    hdr=builder(dataset);
    
    if nargin>1
        writer=img_formats.(img_format).writer;
        writer(fn, hdr);
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% general helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function unfl_ds=unflatten(ds)
    % puts the time dimension last, instead of first
    unfl_ds=shiftdim(cosmo_unflatten(ds),1);

function img_formats=get_img_formats()
    img_formats=struct();
    
    img_formats.nii.builder=@build_nii;
    img_formats.nii.writer=@write_nii;
    img_formats.nii.externals={'nifti'};
    
    img_formats.bv_vmp.builder=@build_bv_vmp;
    img_formats.bv_vmp.writer=@write_bv;
    img_formats.bv_vmp.externals={'neuroelf'};
    
    img_formats.bv_glm.builder=@build_bv_glm;
    img_formats.bv_glm.writer=@write_bv;
    img_formats.bv_glm.externals={'neuroelf'};
    
    img_formats.afni.builder=@build_afni;
    img_formats.afni.writer=@write_afni;
    img_formats.afni.externals={'afni'};
    
    
function img_format=get_img_format(ds, img_formats)
    
    fns=fieldnames(img_formats);
    n=numel(fns);
    
    count=0;
    for k=1:n
        fn=fns{k};
        if isfield(ds.a, ['hdr_' fn])
            img_format=fn;
            count=count+1;
        end
    end
    
    if count~=1
        error('Found %d image formats, expected 1', count)
    end
    
function check_endswith(fn,ext)
    b=isempty(cosmo_strsplit(fn,ext,-1));
    if ~b
        error('%s should end with %s', fn, ext);
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% format-specific helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Nifti
    
<<<<<<< Updated upstream
function nii=build_nii(ds)
=======
    mat=vol.mat;
    mat(1:3,4)=mat(1:3,4)+mat(1:3,1:3)*[1 1 1]';
    pix_dim=vol.mat(1:3,1:3)*[1 1 1]';
    hdr=struct();

    dime=struct();
    dime.datatype=16; %single
    dime.dim=[4 dim(:)' 1 1 1];
    dime.pixdim=[1 pix_dim(:)' 0 0 0 0];
    fns={'intent_p1','intent_p2','intent_p3','intent_code',...
        'slice_start','slice_duration','slice_end',...
        'scl_slope','scl_inter','slice_code','cal_max',...
        'cal_min','toffset'};

    dime=set_all(dime,fns);
    dime=cosmo_structjoin(dime,cosmo_statcode(ds,'nifti'));
    dime.xyzt_units=10;
    hdr.dime=dime;

    hk=struct();
    hk.sizeof_hdr=348;
    hk.data_type='';
    hk.db_name='';
    hk.extents=0;
    hk.session_error=0;
    hk.regular='r';
    hk.dim_info=0;
    hdr.hk=hk;

    hist=struct();
    hist.sform_code=2;
    hist.originator=[1 1 1 1 0];
    hist=set_all(hist,{'descrip','aux_file','intent_name'},'');
    hist=set_all(hist,{'qform_code','quatern_b',...
                        'quatern_d',...
                        'qoffset_x','qoffset_y','qoffset_z'});
    hist=set_all(hist,{'intent_name'},'');   
    hist.srow_x=mat(1,:);
    hist.srow_y=mat(2,:);
    hist.srow_z=mat(3,:);
    hist.quatern_c=1;                
    hdr.hist=hist;

    ni.img=single(vol_data);
    ni.hdr=hdr;

function write_nii(fn, hdr)
    save_nii(hdr, fn);
>>>>>>> Stashed changes
    
    nsamples=size(ds.samples,1);
    
    nii=ds.a.hdr_nii;
    nii.hdr.dime.dim(5)=nsamples;
    nii.img=unflatten(ds);
    
    function write_nii(fn, hdr)
    save_nii(hdr, fn);
    
    
    %% Brainvoyager VMP
function hdr=build_bv_vmp(ds)
    samples=ds.samples;
    nsamples=size(samples,1);
    
    hdr=ds.a.hdr_bv_vmp;
    
    vols=unflatten(ds);
    
    master_data=hdr.Map(1); 
    
    set_zero={'Type','LowerThreshold','UpperThreshold','ClusterSize',...
                'DF1','DF2','BonferroniValue','FDRThresholds'};
    
    fns=fieldnames(master_data);
    n=numel(fns);
    
    args=cell(1,n*2);
    for k=1:n
        fn=fns{k};
        args{k*2-1}=fn;
        data=cell(1,nsamples);
        for j=1:nsamples
            dataj=master_data.(fn);
            if strcmp(fn,'VMPData')
                dataj=vols(:,:,:,j);
            elseif ~isempty(strcmp(fn,set_zero))
                dataj(:)=0;
            end
            data{j}=dataj;
        end
        args{k*2}=data;
    end
    
    hdr.Map=struct(args{:});
    
function write_bv(fn, hdr)
    check_endswith(fn,'.vmp');
    hdr.SaveAs(fn);
    
    
    %% Brainvoyager GLM
function hdr=build_bv_glm(ds)
    
    warning(['Output in BV .glm format not supported '...
                '- storing as VMP instead']);
    
    ds.a.hdr_bv_vmp=xff('new:vmp');
    ds.a=rmfield(ds.a,'hdr_bv_glm');
    hdr=build_bv_vmp(ds);
    

function hdr=build_afni(ds)
    nsamples=size(ds.samples,1);
    hdr=ds.a.hdr_afni; 
    
    hdr.BRICK_TYPES=repmat(3,1,nsamples);
    hdr.DATASET_RANK(2)=nsamples;
    hdr.SCENE_DATA(2)=11; %brik
    hdr.SCALE=0;
    
    set_empty={'BRICK_LABS','BRICK_KEYWORDS',...
                'BRICK_STATS','BRICK_FLOAT_FACS',...
                'BRICK_STATAUX','STAT_AUX'};
    for k=1:numel(set_empty)
        fn=set_empty{k};
        hdr.(fn)=[];
    end
    
    % if labels for the samples, store them in the header
    if isfield(ds.sa,'labels') && ~isempty(ds.sa.labels)
        hdr.BRICK_LABS=cosmo_strjoin(ds.sa.labels,'~');
    end
    
    % store data in non-afni field 'img'
    hdr.img=unflatten(ds);
    
function write_afni(fn, hdr)    
    
    hdr.RootName=fn;
    data=hdr.img; % get the data
    hdr=rmfield(hdr,'img'); % remove the non-afni field 'img'

    afniopt=struct();
    afniopt.Prefix=fn; %the second input argument
    afniopt.OverWrite='y';
    afniopt.NoCheck=0;
    
    [err, ErrMessage]=WriteBrik(data, hdr, afniopt);
    if err
        error(ErrMessage);
    end
    
    
    
