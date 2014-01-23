function ds = cosmo_fmri_dataset(filename, varargin)
% load an fmri dataset to facilitate MVPA analyses. Fashioned after
% the logic and semantics of PyMVPA. 
%
% ds = cosmo_fmri_dataset(filename, [,'mask',mask],...
%                                   ['targets',targets],...
%                                   ['chunks',chunks])
% 
% Inputs:
%   filename     filename for dataset. Currently supports NIFTI and ANALYZE
%   mask         filename for volume mask
%   targets      Nx1 array of numeric labels to be used as sample attributes
%   chunks       Nx1 array of numeric labels to be used as feature attributes
%
% Returns:
%   ds           dataset struct with the following fields:
%     .samples   NxM matrix containing the data loaded from filename, for
%                N samples (observations, volumes) and M features (spatial
%                locations, voxels).
%                If the original nifti file contained data with X,Y,Z,T
%                dimensions, and no mask was applied, then 'data' will have
%                dimensions N x M, where N = T, and M = X*Y*Z. If a mask was
%                applied then M = the number of non-zero voxels in the mask
%                input dataset.
%     .a         struct intended to contain dataset-relevent data.
%     .a.hdr_{F} header information for this dataset, required to map the data
%                back to a volumetric data file. Currently {F} can be 
%                'nii', 'bv_vmp', 'bv_glm', or 'afni'.
%     .a.vol.dim 1x3 vector indicating the number of voxels in the 3
%                spatial dimensions.
%     .sa        struct for holding sample attributes (e.g.,sa.targets,sa.chunks) 
%     .fa        struct for holding sample attributes 
%     .fa.voxel_indices   M * 3 indices of voxels (in volume space). 
%
% Dependencies:
% - for NIFTI files, it requires the following toolbox:
%   http://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
%   (note that his toolbox is included in CoSMoMVPA in /externals)
% - for Brainvoyager files (.vmp and .vtc), it requires the NeuroElf
%   toolbox, available from: http://neuroelf.net
% - for AFNI files (+{orig,tlrc}.{HEAD,BRIK[.gz]}) it requires the AFNI
%   Matlab toolbox, available from: http://afni.nimh.nih.gov/afni/matlab/
%
% ACC, NNO Aug, Sep 2013
     
    % Input parsing stuff
    defaults.mask=[];
    defaults.targets=[];
    defaults.chunks=[];
    
    p = cosmo_structjoin(defaults, varargin);
     
    % special case: if it's already a dataset, just return it
    if isstruct(filename) && isfield(filename,'samples')
        ds=filename;
        return
    end
    
    % get the supported image formats use the helper defined below
    img_formats=get_img_formats(); 
    
    % read the image
    [data,hdr,img_format,sa]=read_img(filename, img_formats);
     
    if ~isa(data,'double')
        data=double(data); % ensure data stored in double precision
    end
    
    % see how many diemsions there are, and their size
    data_size = size(data);
    ndim = numel(data_size);
    
    switch ndim
        case 3
            % simple reshape operation
            data=reshape(data,[1 data_size]);
        case 4
            % make temporal dimension the first one
            data=shiftdim(data,3);
        otherwise
            error('need 3 or 4 dimensions, found %d', ndims);
    end
    % number of values in 3 spatial + 1 temporal dimension
    [nt,ni,nj,nk]=size(data);
    
    % make a dataset
    ds=cosmo_flatten(data,{'i','j','k'},{1:ni,1:nj,1:nk});
    ds.sa=sa;
    
    header_name=['hdr_' img_format];
    ds.a.(header_name) = hdr; % store header
    
    % set chunks and targets 
    ds=set_sa_vec(ds,p,'targets');
    ds=set_sa_vec(ds,p,'chunks');
    
    % deal with the mask
    % for convenience compute an automask
    auto_mask=data~=0 & isfinite(data);
    if numel(size(auto_mask))==4
        % take as a mask anywhere where all features are zero
        % (convert boolean to numeric for older matlab versions)
        auto_mask=prod((~auto_mask)+0,4)==0; 
    end
        
    mask_indices=-1;
    if isempty(p.mask) || isequal(p.mask,true)
        % give a warning if there are many empty voxels
        nzero=sum(auto_mask(:));
        ntotal=prod(data_size);
        thr=.1;
        if nzero/ntotal > thr
            warning(['No mask supplied but %.0f%% of the data is ',...
                    'either zero or non-finite. To use a mask derived ',...
                    'from the input mask, use: %s(...,''mask'',true)'],...
                    100*nzero/ntotal,mfilename());
        end 
    else
        % if a mask was supplied, load it
        if ischar(p.mask)
            m = read_img(p.mask, img_formats);
        elseif isequal(p.mask, true)
            m = auto_mask;
        elseif isnumeric(mask) || islogical(mask)
            m = p.mask;
        else
            error('Weird mask, need string, array, or ''true''');
        end
     
        mdim = size(m);
     
        % mask has to be 3D or 4D
        switch numel(mdim)
            case 3
            case 4
                m=m(:,:,:,1);
                warning('Mask has %d volumes - using first', mdim(4));
            otherwise
                error('illegal mask: %d dimensions', mdim);
        end
     
        % sanity check to ensure the mask is properly shaped
        if ~isequal(data_size(1:3), mdim(1:3))
            error('mask size is different from data size');
        end
        
        mask_indices=m~=0;
    end
     
    if ~isequal(mask_indices,-1)
        ds=cosmo_slice(ds, mask_indices(:), 2);
    end
    
    cosmo_check_dataset(ds, 'fmri'); % ensure all kosher
     
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% general helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img_formats=get_img_formats()
    
    % define which formats are supports
    % .exts indicates the extensions
    % .matcher says whether a struct is of the type
    % .reader should read a filaname and return a struct
    % .externals are fed to cosmo_check_externals
    img_formats=struct();
    
    img_formats.nii.exts={'.nii','.nii.gz','.hdr','.img'};
    img_formats.nii.matcher=@isa_nii;
    img_formats.nii.reader=@read_nii; % this is a wrapper defined below
    img_formats.nii.externals={'nifti'};
    
    img_formats.bv_vmp.exts={'.vmp'};
    img_formats.bv_vmp.matcher=@isa_bv_vmp;
    img_formats.bv_vmp.reader=@read_bv_vmp;
    img_formats.bv_vmp.externals={'neuroelf'};
    
    img_formats.bv_glm.exts={'.glm'};
    img_formats.bv_glm.matcher=@isa_bv_glm;
    img_formats.bv_glm.reader=@read_bv_glm;
    img_formats.bv_glm.externals={'neuroelf'};
    
    img_formats.bv_msk.exts={'.msk'};
    img_formats.bv_msk.matcher=@isa_bv_msk;
    img_formats.bv_msk.reader=@read_bv_msk;
    img_formats.bv_msk.externals={'neuroelf'};
    
    
    img_formats.afni.exts={'+orig','+orig.HEAD','+orig.BRIK',...
                           '+orig.BRIK.gz','+tlrc','+tlrc.HEAD',...
                           '+tlrc.BRIK','+tlrc.BRIK.gz'};
    img_formats.afni.matcher=@isa_afni;
    img_formats.afni.reader=@read_afni;
    img_formats.afni.externals={'afni'};
    
function ds=set_sa_vec(ds,p,fieldname)
    % helper: sets a sample attribute as a vector
    % throws an error if it has the wrong size
    v=p.(fieldname);
    if isequal(size(v),[0 0])
        % ignore '[]', but not zeros(10,0)
        return;
    end
    nsamples=size(ds.samples,1);
        
    n=numel(v);
    if n==1
        % singleton element - repeat nsamples times.
        v=repmat(v,nsamples,1);
        n=nsamples;
    end
    if ~(n==0 || n==nsamples)
        error('size mismatch for %s: expected %d values, found %d', ...
                        fieldname, nsamples, n);
    end
    ds.sa.(fieldname)=v(:);
     
function img_format=find_img_format(filename, img_formats)
    % helper: find image format of filename fn
    
    fns=fieldnames(img_formats);
    n=numel(fns);
    for k=1:n
        fn=fns{k};
        
        if ischar(filename)
            exts=img_formats.(fn).exts;
            m=numel(exts);
            for j=1:m
                ext=exts{j};
                d=numel(ext)-1;
                if numel(filename) <= d 
                    continue % filename is too short
                end
                if strcmpi(filename(end+(-d:0)), ext)
                    img_format=fn;
                    return
                end
            end
        else
            % it could be a struct - try that
            matcher=img_formats.(fn).matcher;
            if matcher(filename)
                img_format=fn;
                return
            end
        end
    end
    error('Could not find image format for "%s"', filename)
     
    
function [data,hdr,img_format,sa]=read_img(fn, img_formats)
    % helper: returns data (3D or 4D), header, and a string indicating the
    % image format. It matches the filename extension with what is stored
    % in img_formats
    
    img_format=find_img_format(fn, img_formats);
    
    % make sure the required externals exist
    externals=img_formats.(img_format).externals;
    cosmo_check_external(externals);
    
    % read the data
    reader=img_formats.(img_format).reader;
    [data,hdr,sa]=reader(fn);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% format-specific helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% nifti (nii)
function b=isa_nii(hdr)
    
    b=isstruct(hdr) && isfield(hdr,'img') && isnumeric(hdr.img) && ...
            isfield(hdr,'hdr') && isfield(hdr.hdr,'dime') && ...
            isfield(hdr.hdr.dime,'dim') && isnumeric(hdr.hdr.dime.dim);
     
function [data,hdr,sa]=read_nii(fn)
    if ischar(fn)
        hdr=load_nii(fn);  
    elseif isa_nii(fn)
        hdr=fn;
    else
        error('illegal input');
    end
    
    data=hdr.img;
    hdr=rmfield(hdr,'img');

    sa=struct();
    
%% Brainvoyager VMP (vmp)
    
function b=isa_bv_vmp(hdr)
    
    b=isa(hdr,'xff') && isfield(hdr,'Map') && isstruct(vmp.Map) && ... 
            isfield(hdr,'VMRDimX') && isfield(hdr,'NrOfMaps');
        
function [data,hdr,sa]=read_bv_vmp(fn)
    if ischar(fn)
        hdr=xff(fn);
    elseif isa_bv_vmp(fn)
        hdr=fn;
    else
        error('illegal input');
    end
    
    nsamples=hdr.NrOfMaps;
    voldim=size(hdr.Map(1).VMPData);
    
    data=zeros([voldim nsamples]);
    
    for k=1:nsamples
        data(:,:,:,k)=hdr.Map(k).VMPData;
    end
    
    bless(hdr); % avoid GC doing unwanted stuff
   
    sa=struct();
    
    
function b=isa_bv_glm(hdr)
    
    b=isa(hdr,'xff') && isfield(hdr,'Predictor') &&  ... 
            isfield(hdr,'GLMData') && isfield(hdr,'DesignMatrix');
    
function [data,hdr,sa]=read_bv_glm(fn)
    if ischar(fn)
        hdr=xff(fn);
    elseif isa_bv_glm(fn)
        hdr=fn;
    else
        error('illegal input');
    end
    
    nsamples=hdr.NrOfPredictors;
    data=hdr.GLMData.BetaMaps(:,:,:,:);
    
    bless(hdr);
    
    name1=cell(nsamples,1);
    name2=cell(nsamples,1);
    rgb=zeros(nsamples,3);
    for k=1:nsamples
        p=hdr.Predictor(k);
        name1{k}=p.Name1;
        name2{k}=p.Name2;
        rgb(k,:)=p.RGB(1,:);
    end
    
    sa=struct();
    sa.Name1=name1;
    sa.Name2=name2;
    sa.RGB=rgb;
    
function b=isa_bv_msk(hdr)    
    
    b=isa(hdr,'xff') && isfield(hdr, 'Mask');

    
function [data,hdr,sa]=read_bv_msk(fn)
    hdr=xff(fn);
    a=[];
    fa=[];
    sa=[];
    
    data=hdr.Mask>0;
    hdr=[]; % set to empty - may crash (as it should) when used as dataset
    
%% AFNI     
function b=isa_afni(hdr)
    b=iscell(hdr) && isfield(hdr,'DATASET_DIMENSIONS') && ...
            isfield(hdr,'DATASET_RANK');

function [data,hdr,sa]=read_afni(fn)  
    [err,data,hdr,err_msg]=BrikLoad(fn);
    if err
        error('Error reading afni file: %s', err_msg);
    end
    
    sa=struct();
    
    if isfield(hdr,'BRICK_LABS')
        labs=['~' hdr.BRICK_LABS '~'];
        pos=find(labs=='~');
        ntilde=numel(pos-1);
        nsamples=hdr.DATASET_RANK(2);
        if ntilde >= nsamples
            sa.labels=cell(nsamples,1);
            for k=1:nsamples
                sa.labels{k}=labs((pos(k)+1):(pos(k+1)-1));
            end
        end
    end