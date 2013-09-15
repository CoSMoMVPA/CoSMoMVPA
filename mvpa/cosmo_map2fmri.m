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

    samples=dataset.samples;
    [nsamples, nfeatures]=size(samples);
    
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
    
    
function img_format=get_img_format(dataset, img_formats)
    
    fns=fieldnames(img_formats);
    n=numel(fns);
    
    count=0;
    for k=1:n
        fn=fns{k};
        if isfield(dataset.a, ['hdr_' fn])
            img_format=fn;
            count=count+1;
        end
    end
    
    if count~=1
        error('Found %d image formats, expected 1', count)
    end
    
function check_endswith(fn,ext)
    b=numel(fn)>=numel(ext) && strcmpi(fn(end+((1-numel(ext)):0)),ext);
    if ~b
        error('%s should end with %s', fn, ext);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % format-specific helper functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% Nifti
    
function hdr=build_nii(dataset)
    
    nsamples=size(dataset.samples,1);
    
    hdr=dataset.a.hdr_nii;
    
    hdr.hdr.dime.dim(5)=nsamples;
    hdr.hdr.dime.dim(2:4)=dataset.a.vol.dim;
    hdr.img=cosmo_map2array(dataset);
    
    function write_nii(fn, hdr)
    save_nii(hdr, fn);
    
    
    %% Brainvoyager VMP
function hdr=build_bv_vmp(dataset)
    samples=dataset.samples;
    nsamples=size(samples,1);
    
    hdr=dataset.a.hdr_bv_vmp;
    
    samples_cell=cell(1,nsamples);
    vols=cosmo_map2array(dataset);
    
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
            elseif ~isempty(strmatch(fn,set_zero))
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
function hdr=build_bv_glm(dataset)
    
    warning('cosmo:save','Output in BV .glm format not supported - storing as VMP instead');
    
    dataset.a.hdr_bv_vmp=xff('new:vmp');
    dataset.a=rmfield(dataset.a,'hdr_bv_glm');
    hdr=build_bv_vmp(dataset);
    

function hdr=build_afni(dataset)
    nsamples=size(dataset.samples,1);
    hdr=dataset.a.hdr_afni; 
    
    hdr.BRICK_TYPES=repmat(3,1,nsamples);
    hdr.DATASET_RANK(2)=nsamples;
    hdr.SCENE_DATA(2)=11; %brik
    hdr.SCALE=0;
    
    set_empty={'BRICK_LABS','BRICK_KEYWORDS','BRICK_STATS','BRICK_FLOAT_FACS'};
    for k=1:numel(set_empty)
        fn=set_empty{k};
        hdr.(fn)=[];
    end
    
    % store data in this non-afni field
    hdr.img=cosmo_map2array(dataset);
    
function write_afni(fn, hdr)    
    
    hdr.RootName=fn;
    data=hdr.img; % get the data
    hdr=rmfield(hdr,'img'); % remove the field

    afniopt=struct();
    afniopt.Prefix=fn; %the second input argument
    afniopt.OverWrite='y';
    afniopt.NoCheck=0;
    
    [err, ErrMessage]=WriteBrik(data, hdr, afniopt);
    if err
        error(ErrMessage);
    end
    
    
    