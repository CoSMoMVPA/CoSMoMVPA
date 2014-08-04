function ds = cosmo_fmri_dataset(filename, varargin)
% load an fmri volumetric dataset
%
% ds = cosmo_fmri_dataset(filename, [,'mask',mask],...
%                                   ['targets',targets],...
%                                   ['chunks',chunks])
%
% Inputs:
%   filename     filename for dataset  } It should end with one of:
%   mask         optional filename for } .nii, .nii.gz        NIFTI
%                                      } .hdr, .img           ANALYZE
%                volume mask, or true    +{orig}.{HEAD,BRIK}  AFNI
%                to apply an automask    .vmr, .vmp, .vtc     } Brain-
%                                              .glm, .msk     } voyager
%                                        .mat                 SPM (SPM.mat)
%                                        .mat:beta            SPM beta
%                                        .mat:con             SPM contrast
%                                        .mat:spm             SPM stats
%   targets      optional Tx1 numeric labels of experimental
%                conditions (where T is the number of samples (volumes)
%                in the dataset)
%   chunks       optional Tx1 numeric labels of chunks, typically indices
%                of runs of data acquisition
%
%
% Returns:
%   ds           dataset struct with the following fields:
%     .samples   NxM matrix containing the data loaded from filename, for
%                N samples (observations, volumes) and M features (spatial
%                locations, voxels).
%                If the original nifti file contained data with X,Y,Z,T
%                elements in the three spatial and one temporal dimension
%                and no mask was applied, then .samples will have
%                dimensions N x M, where N = T and M = X*Y*Z. If a mask
%                was applied then M (M<=X*Y*Z) is the number of non-zero
%                voxels in the  mask input dataset.
%     .a         struct with dataset-relevent data.
%     .a.dim.labels   dimension labels, set to {'i','j','k'}
%     .a.dim.values   dimension values, set to {1:X, 1:Y, 1:Z}
%     .a.vol.dim 1x3 vector indicating the number of voxels in the 3
%                spatial dimensions.
%     .a.vol.mat 4x4 voxel-to-world transformation matrix (LPI, base-1).
%     .a.vol.dim 1x3 number of voxels in each spatial dimension
%     .sa        struct for holding sample attributes (e.g., sa.targets,
%                sa.chunks)
%     .fa        struct for holding feature attributes
%     .fa.{i,j,k} indices of voxels (in voxel space).
%
% Notes:
%  - Most MVPA applications require that .sa.targets (experimental
%    condition of each sample) and .sa.chunks (partitioning of the samples
%    in independent sets) are set, either by using this function or
%    manually afterwards.
%  - Data can be mapped to the volume using cosmo_map2fmri
%  - SPM data can also be specified as filename:format, where format
%    can be 'beta', 'con' or 'spm' (e.g. 'SPM.mat:beta', 'SPM.mat:con', or
%    'SPM.mat:spm') to load beta, contrast, or statistic images,
%    respectively. If format is omitted it is set to 'beta'.
%  - If SPM data contains a field .Sess (session) then .sa.chunks are set
%    according to its contents
%
% Dependencies:
% -  for NIFTI, analyze (.hdr/.img) and SPM.mat files, it requires the
%    following toolbox:
%    http://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
%    (note that his toolbox is included in CoSMoMVPA in /externals)
% -  for Brainvoyager files (.vmp, .vtc, .msk, .glm), it requires the
%    NeuroElf toolbox, available from: http://neuroelf.net
% -  for AFNI files (+{orig,tlrc}.{HEAD,BRIK[.gz]}) it requires the AFNI
%    Matlab toolbox, available from: http://afni.nimh.nih.gov/afni/matlab/
%
% Examples:
%     % load nifti file
%     ds=fmri_dataset('mydata.nii');
%
%     % load gzipped nifti file
%     ds=fmri_dataset('mydata.nii.gz');
%
%     % load ANALYZE file and apply brain mask
%     ds=fmri_dataset('mydata.hdr','mask','brain_mask.hdr');
%
%     % load AFNI file with 6 'bricks' (values per voxel, e.g. beta values);
%     % set chunks (e.g. runs) and targets (experimental conditions), and
%     % use a mask
%     ds=fmri_dataset('mydata+tlrc', 'chunks', [1 1 1 2 2 2]', ...
%                                     'targets', [1 2 3 1 2 3]',
%                                     'mask', 'masks/brain_mask+tlrc);
%
%     % load BrainVoyager VMR file in directory 'mydata', and apply an
%     % automask that removes all features (voxels) that are zero or
%     non-finite for all samples
%     ds=fmri_dataset('mydata/mydata.vmr', 'mask', true);
%
%     % load two datasets, one for odd runs, the other for even runs, and
%     % combine them into one dataset. Note that the chunks are set here,
%     % but the targets are not - for subsequent analyses this may have to
%     % be done manually
%     ds_even=fmri_dataset('data_even_runs.glm','chunks',1);
%     ds_odd=fmri_dataset('data_odd_runs.glm','chunks',2);
%     ds=cosmo_stack({ds_even,ds_odd});
%
%     % load beta values from SPM GLM analysis stored
%     % in a file SPM.mat.
%     % If SPM.mat contains a field .Sess (sessions) then .sa.chunks
%     % is set according to the contents of .Sess.
%     ds=cosmo_fmri_dataset('path/to/SPM.mat');
%
%     % as above, and apply an automask to remove voxels that
%     % are zero or non-finite in all samples.
%     ds=cosmo_fmri_dataset('path/to/SPM.mat','mask',true);
%
%     % load contrast beta values from SPM GLM file SPM.mat
%     ds=cosmo_fmri_dataset('path/to/SPM.mat:con');
%
%     % load contrast statistic values from SPM GLM file SPM.mat
%     ds=cosmo_fmri_dataset('path/to/SPM.mat:spm');
%
% See also: cosmo_map2fmri
%
% ACC, NNO Aug, Sep 2013

    % Input parsing stuff
    defaults.mask=[];
    defaults.targets=[];
    defaults.chunks=[];


    p = cosmo_structjoin('!',defaults, varargin);

    % special case: if it's already a dataset, just return it
    if isstruct(filename) && isfield(filename,'samples')
        ds=filename;
        cosmo_check_dataset(ds,'fmri');
        return
    end

    % get the supported image formats use the helper defined below
    img_formats=get_img_formats();

    % read the image
    [data,vol,img_format,sa]=read_img(filename, img_formats);

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
    [unused,ni,nj,nk]=size(data);

    % make a dataset
    ds=cosmo_flatten(data,{'i','j','k'},{1:ni,1:nj,1:nk});
    ds.sa=sa;

    %header_name=['hdr_' img_format];
    %ds.a.(header_name) = hdr; % store header
    ds.a.vol=vol;

    % set chunks and targets
    ds=set_sa_vec(ds,p,'targets');
    ds=set_sa_vec(ds,p,'chunks');

    % deal with the mask
    % for convenience compute an automask
    auto_mask=data~=0 & isfinite(data);
    if numel(size(auto_mask))==4
        % take as a mask anywhere where all features are zero
        % (convert boolean to numeric for older matlab versions)
        auto_mask=squeeze(prod((~auto_mask)+0,1)==0);
    end

    mask_indices=-1;
    if isempty(p.mask)
        % give a warning if there are many empty voxels
        nzero=sum(~auto_mask(:));
        ntotal=prod(data_size(1:3));
        thr=.1;
        if nzero/ntotal > thr
            warning(['No mask supplied but %.0f%% of the data is ',...
                    'either zero or non-finite (and thus potentially '...
                    'useless). To exlude that data ',...
                    'from the input, use: %s(...,''mask'',true)'],...
                    100*nzero/ntotal,mfilename());
        end
    else
        % if a mask was supplied, load it
        if ischar(p.mask)
            m = read_img(p.mask, img_formats);
        elseif islogical(p.mask)
            % if true, use automask
            % if false, use all features
            m = bsxfun(@or,auto_mask,~p.mask);
        elseif isnumeric(p.mask) || islogical(p.mask)
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

    img_formats.bv_vmr.exts={'.vmr'};
    img_formats.bv_vmr.matcher=@isa_bv_vmr;
    img_formats.bv_vmr.reader=@read_bv_vmr;
    img_formats.bv_vmr.externals={'neuroelf'};

    img_formats.bv_glm.exts={'.glm'};
    img_formats.bv_glm.matcher=@isa_bv_glm;
    img_formats.bv_glm.reader=@read_bv_glm;
    img_formats.bv_glm.externals={'neuroelf'};

    img_formats.bv_msk.exts={'.msk'};
    img_formats.bv_msk.matcher=@isa_bv_msk;
    img_formats.bv_msk.reader=@read_bv_msk;
    img_formats.bv_msk.externals={'neuroelf'};

    img_formats.bv_vtc.exts={'.vtc'};
    img_formats.bv_vtc.matcher=@isa_bv_vtc;
    img_formats.bv_vtc.reader=@read_bv_vtc;
    img_formats.bv_vtc.externals={'neuroelf'};

    img_formats.spm.exts={'.mat','mat:con','mat:beta','mat:spm'};
    img_formats.spm.matcher=@isa_spm;
    img_formats.spm.reader=@read_spm;
    img_formats.spm.externals=img_formats.nii.externals;

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
                if isempty(cosmo_strsplit(filename,ext,-1))
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


function [data,vol,img_format,sa]=read_img(fn, img_formats)
    % helper: returns data (3D or 4D), header, and a string indicating the
    % image format. It matches the filename extension with what is stored
    % in img_formats

    img_format=find_img_format(fn, img_formats);

    % make sure the required externals exist
    externals=img_formats.(img_format).externals;
    cosmo_check_external(externals);

    % read the data
    reader=img_formats.(img_format).reader;
    [data,vol,sa]=reader(fn);

function hdr=get_and_check_data(hdr, loader_func, check_func)
    % is hdr is a char, load it using loader; otherwise return the input.
    % in any case the output is checked using check_func
    if ischar(hdr)
        hdr=loader_func(hdr);
    end
    if ~check_func(hdr)
        error('Illegal input of type %s - failed to pass %s',...
                    class(hdr), func2str(check_func));
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% format-specific helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% nifti (nii)
function b=isa_nii(hdr)

    b=isstruct(hdr) && isfield(hdr,'img') && isnumeric(hdr.img) && ...
            isfield(hdr,'hdr') && isfield(hdr.hdr,'dime') && ...
            isfield(hdr.hdr.dime,'dim') && isnumeric(hdr.hdr.dime.dim);

function [data,vol,sa]=read_nii(fn, show_warning)
    if nargin<2
        % show_warning is used by read_spm for each volume separately.
        % This parameter allows read_spm to show warning messages just once
        % instead of for each volume
        show_warning=true;
    end

    hdr=get_and_check_data(fn, @load_nii, @isa_nii);

    data=hdr.img;
    sa=struct();
    vol=get_vol_nii(hdr, show_warning);

function vol=get_vol_nii(hdr, show_warning)
    if nargin<2
        show_warning=true;
    end
    % nifti volume info
    hdr=hdr.hdr;
    dim=hdr.dime.dim(2:4);

    hist=hdr.hist;
    mat=[hist.srow_x; hist.srow_y; hist.srow_z; 0 0 0 1];

    % make base1 friendly
    mat(1:3,4)=mat(1:3,4)+mat(1:3,1:3)*[-1 -1 -1]';

    % try to deal with old analyze-style files with flipped orientations.
    % this code is experimental and has been tried only on a few
    % nifti/analyze files, hence for now a warning is printed
    if isfield(hist, 'flip_orient') && ~isempty(hist.flip_orient)
        assert(isfield(hist,'rot_orient') && ~isempty(hist.rot_orient));
        if show_warning
            warning(['flip_orient field found - will flip orientation '...
                 'and/or swap spatial dimensions. This operation is '...
                 '*experimental*. You are advised to check your '...
                 'results visually. If the orientation is off, please '...
                 'get in touch with the CoSMoMVPA developers.']);
        end

        % spatial dimension permutation matrix
        permute_dim_mat=zeros(4);
        permute_dim_mat(4,4)=1;

        % dimension flip (reflection) matrix
        flip_mat=eye(4);
        for dim_index=1:3
            permute_dim_mat(hist.rot_orient(dim_index),dim_index)=1;
            if hist.flip_orient(dim_index)>0
                flip_mat(dim_index,dim_index)=-1;
            end
        end

        % after permutation each column and row should have exactly one 1
        one_vec=ones(1,4);
        assert(isequal(sum(permute_dim_mat,1),one_vec) && ...
                        isequal(sum(permute_dim_mat,2),one_vec'))


        % apply dimension permutation & reflections
        mat=permute_dim_mat*flip_mat*mat;
    end

    vol=struct();
    vol.mat=mat;
    vol.dim=dim;

%% Brainvoyager

% helpers
function z=xff_struct(x)
    % helper function: applies xff and returns a struct
    % this avoids clearing of the object (which xff seems like doing)
    y=xff(x);
    z=getcont(y);

    % BoundingBox is a method; copy its output to the struct
    z.BoundingBox=y.BoundingBox;

function vol=get_vol_bv(hdr)
    % bv vol info
    bbox=hdr.BoundingBox;
    mat=bvcoordconv([],'bvx2tal',bbox);
    dim=bbox.DimXYZ;

    % deal with offset at (.5, .5, .5) [CHECKME]
    mat(1:3,4)=mat(1:3,4)+mat(1:3,1:3)*.5*[1 1 1]';

    vol=struct();
    vol.mat=mat;
    vol.dim=dim;

% BV volumetric map
function b=isa_bv_vmp(hdr)

    b=(isa(hdr,'xff') || isstruct(hdr)) && ...
            isfield(hdr,'Map') && isstruct(hdr.Map) && ...
            isfield(hdr,'VMRDimX') && isfield(hdr,'NrOfMaps');

function [data,vol,sa]=read_bv_vmp(fn)
    hdr=get_and_check_data(fn, @xff_struct, @isa_bv_vmp);

    nsamples=hdr.NrOfMaps;
    voldim=size(hdr.Map(1).VMPData);

    data=zeros([voldim nsamples]);
    labels=cell(nsamples,1);
    for k=1:nsamples
        map=hdr.Map(k);
        data(:,:,:,k)=map.VMPData;
        labels{k}=map.Name;
    end

    vol=get_vol_bv(hdr);

    %bless(hdr); % avoid GC doing unwanted stuff

    sa=struct();
    sa.stats=cosmo_statcode(hdr);
    sa.labels=labels;

% BV volume (usually anatomical)
function b=isa_bv_vmr(hdr)
    b=(isa(hdr,'xff') || isstruct(hdr)) && isfield(hdr,'VMRData');

function [data,vol,sa]=read_bv_vmr(fn)
    hdr=get_and_check_data(fn, @xff_struct, @isa_bv_vmr);

    nsamples=1;
    voldim=size(hdr.VMRData);

    data=zeros([voldim nsamples]);
    data(:,:,:,1)=double(hdr.VMRData);

    vol=get_vol_bv(hdr);

    sa=struct();

% BV GLM
function b=isa_bv_glm(hdr)

    b=(isa(hdr,'xff') || isstruct(hdr)) && isfield(hdr,'Predictor') &&  ...
            isfield(hdr,'GLMData') && isfield(hdr,'DesignMatrix');

function [data,vol,sa]=read_bv_glm(fn)
    hdr=get_and_check_data(fn, @xff_struct, @isa_bv_glm);

    nsamples=hdr.NrOfPredictors;
    data=hdr.GLMData.BetaMaps(:,:,:,:);

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

    vol=get_vol_bv(hdr);

% BV mask
function b=isa_bv_msk(hdr)

    b=(isa(hdr,'xff') || isstruct(hdr)) && isfield(hdr, 'Mask');


function [data,vol,sa]=read_bv_msk(fn)
    hdr=get_and_check_data(fn, @xff_struct, @isa_bv_msk);

    sa=struct();
    data=hdr.Mask>0;
    vol=get_vol_bv(hdr);


% BV volume time course
function b=isa_bv_vtc(hdr)

    b=(isa(hdr,'xff') || isstruct(hdr)) && isfield(hdr, 'VTCData');

function [data,vol,sa]=read_bv_vtc(fn)
    hdr=get_and_check_data(fn, @xff_struct, @isa_bv_vtc);
    hdr=xff(fn);
    sa=struct();
    data=shiftdim(hdr.VTCData,1);
    vol=get_vol_bv(hdr);



%% AFNI
function b=isa_afni(hdr)
    b=iscell(hdr) && isfield(hdr,'DATASET_DIMENSIONS') && ...
            isfield(hdr,'DATASET_RANK');

function [data,vol,sa]=read_afni(fn)
    [err,data,hdr,err_msg]=BrikLoad(fn);
    if err
        error('Error reading afni file: %s', err_msg);
    end

    sa=struct();

    if isfield(hdr,'BRICK_LABS')
        % if present, get labels
        labels=cosmo_strsplit(hdr.BRICK_LABS,'~');
        nsamples=hdr.DATASET_RANK(2);
        if numel(labels)==nsamples+1 && isempty(labels{end})
            labels=labels(1:(end-1));
        end
        sa.labels=labels(:);
    end

    if isfield(hdr,'BRICK_STATAUX')
        % if present, get stat codes
        sa.stats=cosmo_statcode(hdr);
    end

    vol=get_vol_afni(hdr);

function vol=get_vol_afni(hdr)
    % afni volume info
    orient='LPI'; % always return LPI-based matrix

    % origin and basis vectors in world space
    k=[0 0 0;eye(3)];

    [err,i]=AFNI_Index2XYZcontinuous(k,hdr,orient);

    % basis vectors in voxel space
    e1=i(2,:)-i(1,:);
    e2=i(3,:)-i(1,:);
    e3=i(4,:)-i(1,:);

    % change from base0 (afni) to base1 (SPM/Matlab)
    o=i(1,:)-(e1+e2+e3);

    % create matrix
    mat=[e1;e2;e3;o]';

    % set 4th row
    mat(4,:)=[0 0 0 1];

    vol=struct();
    vol.mat=mat;
    vol.dim=hdr.DATASET_DIMENSIONS(1:3);


%% SPM
function b=isa_spm(hdr)
    b=isstruct(hdr) && isfield(hdr,'xX') && isfield(hdr.xX,'X') && ...
                isnumeric(hdr.xX.X) && isfield(hdr,'SPMid');

function [data,vol,sa]=read_spm(fn)
    if ischar(fn)
        pth=fileparts(fn);

        sep=':';
        input_type=cosmo_strsplit(fn,sep,-1);
        switch input_type
            case {'beta','con','spm'}
                fn=fn(1:(end-numel(input_type)-numel(sep)));
            otherwise
                input_type='beta'; % the default; function will crash
                                   % if fn is not a proper filename
        end

        % 'load' is faster than 'importdata'
        % (use 'spm_' instead of 'spm' to avoid name space conflicts)
        spm_=load(fn);
        if ~isstruct(spm_) || ~isequal(fieldnames(spm_),{'SPM'})
            error('expected data with struct ''SPM''');
        end
        spm_=spm_.SPM;
    end

    % just do a check (ignore output)
    get_and_check_data(spm_, [], @isa_spm);

    % get data of interest
    switch input_type
            case 'beta'
                input_vols=spm_.Vbeta;
                input_labels=spm_.xX.name';
            case 'con'
                input_vols=[spm_.xCon.Vcon];
                input_labels={spm_.xCon.name}';
            case 'spm'
                input_vols=[spm_.xCon.Vspm];
                input_labels={spm_.xCon.name}';
        otherwise
            error('illegal data type %s', input_type);
    end

    ninput=numel(input_vols);
    assert(numel(input_labels)==ninput);

    sa=struct();

    if isfield(spm_,'Sess') && strcmp(input_type,'beta')
        % single subject GLM with betas; will use only betas of interest
        % and set chunks based on runs
        nruns=numel(spm_.Sess);
        nbeta=numel(spm_.Vbeta);
        sessions=zeros(nbeta,1);
        beta_index=zeros(nbeta,1);
        for k=1:nruns
            sess=spm_.Sess(k);
            sess_idxs=[sess.Fc.i];
            row_idxs=sess.col(sess_idxs);

            sessions(row_idxs)=k;
            beta_index(row_idxs)=row_idxs;
        end

        keep_vol_msk=sessions>0;
        sa.chunks=sessions(keep_vol_msk);
        sa.beta_index=beta_index(keep_vol_msk);
    else
        % anything else: use all volumes
        keep_vol_msk=true(ninput,1);
    end

    sa.labels=input_labels(keep_vol_msk);
    nkeep=sum(keep_vol_msk);

    if nkeep==0
        error('No input volumes found in %s', fn);
    end

    nsamples=sum(keep_vol_msk);
    sample_counter=0;

    for k=1:ninput
        if ~keep_vol_msk(k)
            continue;
        end
        vol_fn=fullfile(pth,input_vols(k).fname);
        if ~exist(vol_fn)
            error('Volume #%d not found: %s',k,vol_fn);
        end

        % show at most one warning, only at the beginning
        show_warning=sample_counter==0;

        [vol_data_k, vol_k]=read_nii(vol_fn, show_warning);

        if sample_counter==0
            % first volume

            % store volume information
            vol=vol_k;

            % allocate space for output
            data=zeros([vol.dim nsamples]);
            sa.fname=cell(nkeep,1);
        else
            % ensure volume information is same across all volumes
            if ~isequal(vol, vol_k)
                error(['Different volume orientation in volumes '...
                            '#1 (%s) and #%d (%s)'],...
                            sa.fname{1},k,vol_fn);
            end
        end
        sample_counter=sample_counter+1;
        data(:,:,:,sample_counter)=vol_data_k;
        sa.fname{sample_counter}=vol_fn;
    end

    assert(sample_counter==nsamples);

