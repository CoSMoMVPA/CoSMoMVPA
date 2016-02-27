function hdr=cosmo_map2fmri(dataset, fn, varargin)
% maps a dataset structure to a NIFTI, AFNI, or BV structure or file
%
% Usage 1: hdr=cosmo_map2fmri(dataset, '-{FMT}) returns a header structure
% Usage 2: cosmo_map2fmri(dataset, fn) saves dataset to a volumetric file.
%
% In Usage 1, {FMT} can be one of 'nii','bv_vmp',bv_vmr','bv_msk','afni'.
% In Usage 2, fn should end with '.nii.gz', '.nii', '.hdr', '.img', '.vmp',
%             '.vmr', '.msk', '+orig','+orig.HEAD','+orig.BRIK',
%             '+orig.BRIK.gz','+tlrc','+tlrc.HEAD','+tlrc.BRIK', or
%             '+tlrc.BRIK.gz'.
%
% Use cosmo_map2fmri(...,'deoblique',true) to de-oblique the dataset. For
% information on this option, see cosmo_fmri_deoblique
%
% - for NIFTI files, it requires the following toolbox:
%   http://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
%   (note that his toolbox is included in CoSMoMVPA in /externals)
% - for Brainvoyager files (.vmp and .vtc), it requires the NeuroElf
%   toolbox, available from: http://neuroelf.net
% - for AFNI files (+{orig,tlrc}.{HEAD,BRIK[.gz]}) it requires the AFNI
%   Matlab toolbox, available from: http://afni.nimh.nih.gov/afni/matlab/
%
% See also: cosmo_fmri_deoblique
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    defaults=struct();
    defaults.deoblique=false;
    defaults.bv_force_fit=[];
    opt=cosmo_structjoin(defaults,varargin{:});

    cosmo_check_dataset(dataset, 'fmri');

    img_formats=get_img_formats();
    sp=cosmo_strsplit(fn,'-');
    save_to_file=~isempty(sp{1});

    if save_to_file
        fmt=get_format(img_formats, fn);
    else
        if numel(sp)~=2
            error('expected -{FORMAT}');
        end
        fmt=sp{2};
    end

    if ~isfield(img_formats,fmt)
        error('Unsupported format %s', fmt);
    end

    methods=img_formats.(fmt);
    externals=methods.externals;
    cosmo_check_external(externals);

    creator=methods.creator;

    % preprocess the data (de-oblique if necessary)
    dataset=preprocess(dataset,opt);

    % build header structure
    hdr=creator(dataset);

    if save_to_file
        writer=methods.writer;
        writer(fn, hdr);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% general helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ds=preprocess(ds,opt)
    if opt.deoblique
        ds=cosmo_fmri_deoblique(ds);
    end

    if opt.bv_force_fit
        ds=bv_force_fit(ds);
    end

function ds=bv_force_fit(ds)

    mat=ds.a.vol.mat;

    dim=[ds.a.vol.dim(:);1];
    rot=mat(1:3,1:3);
    vox_size=sqrt(sum(rot.^2,1)); %.*sign(sum(rot,1));
    resolution=prod(vox_size).^(1/3);

    % put the center defined by the original matrix close to the center
    % defined by the new matrix
    old_center=mat*(dim+1)/2;
    mat(1:3,1:3)=bsxfun(@times,mat(1:3,1:3),resolution./vox_size);

    new_center=mat*(dim+1)/2;
    mat(:,4)=round(mat(:,4)+old_center-new_center)+.5;

    ds.a.vol.mat=mat;



function check_plump_orientation(ds)
    rot=ds.a.vol.mat(1:3,1:3);
    nonzero=rot~=0;
    is_oblique=any(sum(nonzero,1)~=1) || any(sum(nonzero,2)~=1);
    if is_oblique
        error(['Dataset has oblique orientation, and the specified '...
                'output format does not support this. Options are:\n\n'...
                '(1) use %s(...,''deoblique'',true) to deoblique the '...
                'dataset automatically when writing it\n'...
                '(2) use cosmo_fmri_deoblique to deoblique the dataset '...
                'manually\n'...
                '(3) store the dataset in another file format (such as '...
                'NIFTI)\n\n'...
                'For options (1) and (2), the spatial location of the '...
                'voxels will change. It is recommended to inspect the '...
                'results visually when using one of these options.'],...
                mfilename());
    end

function check_isotropic_voxels(ds)
    rot=ds.a.vol.mat(1:3,1:3);
    vox_size=sqrt(sum(rot.^2,1));

    max_delta=1e-5;
    delta=max(vox_size)-min(vox_size);

    if delta>max_delta
        error(['Dataset has non-isotropic voxels, and the specified '...
                'output format does not support this. Options are:\n\n'...
                '(1) use %s(...,''bv_force_fit'',true) to set the '...
                'voxel size to be isotropic\n'...
                '(2) store the dataset in another file format (such as '...
                'NIFTI)\n\n'...
                'For option (1), the spatial location of the '...
                'voxels will change. It is recommended to inspect the '...
                'results visually when using one of these options.'],...
                mfilename());
    end




function unfl_ds_timelast=unflatten(ds)
    % puts the time dimension last, instead of first
    unfl_ds=cosmo_unflatten(ds);

    % make time dimension last instead of first
    unfl_ds_timelast=shiftdim(unfl_ds,1);

    % deal with singleton dimension
    sz=size(unfl_ds);
    dim_size=ones(1,4);
    dim_size(4)=sz(1);
    dim_size(1:(numel(sz)-1))=sz(2:end);

    nsamples=size(ds.samples,1);
    assert(isequal([ds.a.vol.dim nsamples],dim_size));

    if ~isequal(size(unfl_ds_timelast),dim_size)
        unfl_ds_timelast=reshape(unfl_ds_timelast,dim_size);
    end




function b=ends_with(end_str, str)
    if iscell(end_str)
        b=any(cellfun(@(x) ends_with(x,str),end_str));
    else
        b=isempty(cosmo_strsplit(str, end_str,-1));
    end

function fmt=get_format(img_formats, file_name)
    fns=fieldnames(img_formats);
    fmt=[];
    for k=1:numel(fns)
        fn=fns{k};
        exts=img_formats.(fn).exts;
        if ends_with(exts, file_name)
            fmt=fn;
        end
    end
    if isempty(fmt)
        error('Not found: format for %s', file_name);
    end

function img_formats=get_img_formats()
    img_formats=struct();

    img_formats.nii.creator=@new_nii;
    img_formats.nii.writer=@write_nii;
    img_formats.nii.externals={'nifti'};
    img_formats.nii.exts={'.nii','.nii.gz','.hdr','.img'};

    img_formats.bv_vmp.creator=@new_bv_vmp;
    img_formats.bv_vmp.writer=@write_bv;
    img_formats.bv_vmp.externals={'neuroelf'};
    img_formats.bv_vmp.exts={'.vmp'};

    img_formats.bv_vmr.creator=@new_bv_vmr;
    img_formats.bv_vmr.writer=@write_bv;
    img_formats.bv_vmr.externals={'neuroelf'};
    img_formats.bv_vmr.exts={'.vmr'};

    img_formats.bv_msk.creator=@new_bv_msk;
    img_formats.bv_msk.writer=@write_bv;
    img_formats.bv_msk.externals={'neuroelf'};
    img_formats.bv_msk.exts={'.msk'};

    img_formats.afni.writer=@write_afni;
    img_formats.afni.externals={'afni'};
    img_formats.afni.creator=@new_afni;
    img_formats.afni.exts={'+orig','+orig.HEAD','+orig.BRIK',...
                           '+orig.BRIK.gz','+tlrc','+tlrc.HEAD',...
                           '+tlrc.BRIK','+tlrc.BRIK.gz'};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% format-specific helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Nifti

function ni=new_nii(ds)
    a=ds.a;
    vol=a.vol;
    vol_data=unflatten(ds);
    dim_all=[4 ones(1,7)];
    vol_dim=size(vol_data);
    nvol_dim=numel(vol_dim);
    dim_all(1+(1:nvol_dim))=vol_dim;

    mat=vol.mat;
    mat(1:3,4)=mat(1:3,4)+mat(1:3,1:3)*[1 1 1]';
    pix_dim=sqrt(sum(mat(1:3,1:3).^2,1));
    hdr=struct();

    dime=struct();
    dime.datatype=16; %single
    dime.dim=dim_all;
    dime.pixdim=[0 abs(pix_dim(:))' 0 0 0 0]; % ensure positive values

    fns={'intent_p1','intent_p2','intent_p3','intent_code',...
        'slice_start','slice_duration','slice_end',...
        'scl_slope','scl_inter','slice_code','cal_max',...
        'cal_min','toffset'};

    dime=set_all(dime,fns);
    dime=cosmo_structjoin(dime, cosmo_statcode(ds,'nifti'));
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

    if isfield(ds.a.vol,'xform')
        xform=ds.a.vol.xform;
    else
        xform=''; % unknown
    end
    xform_code=cosmo_fmri_convert_xform('nii',xform);

    hist.sform_code=xform_code;
    % hist.originator=[1 1 1 1 0];
    hist=set_all(hist,{'descrip','aux_file','intent_name'},'');
    hist=set_all(hist,{'qform_code','quatern_b',...
                        'quatern_d',...
                        'qoffset_x','qoffset_y','qoffset_z'});
    hist=set_all(hist,{'intent_name'},'');
    hist.srow_x=mat(1,:);
    hist.srow_y=mat(2,:);
    hist.srow_z=mat(3,:);
    hist.quatern_c=0;

    % required to avoid complaints with hdr/img
    hist.originator=round(dim_all(2:5)/2);
    hdr.hist=hist;

    ni.img=single(vol_data);
    ni.hdr=hdr;

function write_nii(fn, hdr)
    save_nii(hdr, fn);


    %% BrainVoyager helper
function mat=neuroelf_bvcoordconv_wrapper(varargin)
    % converts BV bounding box to affine transformation matrix
    % helper functions that deals with both new neuroelf (version 1.0)
    % and older versions.
    % the old version provides a 'bvcoordconv' .m file
    % the new version privides this function in the neuroelf class
    has_bvcoordconv=~isempty(which('bvcoordconv'));

    % set function handle
    if has_bvcoordconv
        f=@bvcoordconv;
    else
        n=neuroelf();
        f=@n.bvcoordconv;
    end

    mat=f(varargin{:});

    %% Brainvoyager VMP
function [hdr,ds]=add_bv_mat_hdr(hdr,ds,bv_type)
    % ensure dataset is plump
    check_plump_orientation(ds);

    % automatically set orientation to ARS
    if ~strcmp(cosmo_fmri_orientation(ds),'ASR')
        ds=cosmo_fmri_reorient(ds,'ASR');
    end

    % helper to set matrix in header
    mat=ds.a.vol.mat;

    % ensure proper VMP/VMR orientation
    rot_asr=mat(1:3,1:3)*[0 0 -1; -1 0 0; 0 -1 0]';

    if ~isequal(rot_asr,diag(diag(rot_asr)))
        % should never get here because of the ASR orientation
        % forced earlier
        error('Unsupported orientation: need ARS');
    end

    % Set {X,Y,Z}{Start,End} values based on the transformation matrix
    % deal with offset at (.5, .5, .5) [CHECKME]
    mat(1:3,4)=mat(1:3,4)-mat(1:3,1:3)*.5*[1 1 1]';
    tal_coords=mat*[1 1 1 1; ds.a.vol.dim+1, 1]';
    bv_coords=neuroelf_bvcoordconv_wrapper(tal_coords(1:3,:), ...
                                        'tal2bvs',hdr.BoundingBox);

    switch bv_type
        case {'vmp','msk'}
            % require voxels to be isotropic
            check_isotropic_voxels(ds);
            dg=diag(rot_asr);
            resolution=prod(dg)^(1/3);

            labels={'ZStart','ZEnd','XStart','XEnd','YStart','YEnd'};
            for k=1:numel(labels)
                label=labels{k};
                hdr.(label)=bv_coords(k);
            end

            hdr.Resolution=resolution;

        case 'vmr'
            % this *should* be a 256^3 volume
            % XXX check for this?
            labels={'X','Y','Z'};
            dg=diag(rot_asr);
            for k=1:3
                label=labels{k};
                hdr.(['VoXRes' label])=dg(k);
                hdr.(['Dim' label])=round(bv_coords(2,k));
            end

        otherwise
            error('Unsupported type %s', bv_type);
    end

function hdr=new_bv_vmp(ds)
    hdr=xff('new:vmp');

    [hdr,ds]=add_bv_mat_hdr(hdr,ds,'vmp');

    % Store the data

    nsamples=size(ds.samples,1);
    maps=cell(1,nsamples);

    stats=cosmo_statcode(ds,'bv');

    for k=1:nsamples
        empty_hdr=xff('new:vmp');
        map=empty_hdr.Map;
        ds_k=cosmo_slice(ds,k);
        map.VMPData=unflatten(ds_k);
        if cosmo_isfield(ds_k,'sa.labels')
            map.Name=[ds_k.sa.labels{:}];
        end
        if ~isempty(stats)
            stats_k=stats{k};

            stats_k_fieldnames=fieldnames(stats_k);
            for j=1:numel(stats_k_fieldnames)
                key=stats_k_fieldnames{j};
                map.(key)=stats_k.(key);
            end
        end
        maps{k}=map;
        empty_hdr.ClearObject();
    end

    hdr.Map=cat(2,maps{:});
    hdr.NrOfMaps=nsamples;

    bless(hdr);

function write_bv(fn, hdr)
    % general storage function
    hdr.SaveAs(fn);
    hdr.ClearObject();


    %% Brainvoyager VMR
function hdr=new_bv_vmr(ds)
    hdr=xff('new:vmr');
    [hdr,ds]=add_bv_mat_hdr(hdr,ds,'vmr');

    nsamples=size(ds.samples,1);
    if nsamples~=1,
        error('Unsupported: more than 1 sample');
    end

    % scale to 0..255
    vol_data=unflatten(ds);
    hdr.VMRData=scale_uint8(vol_data(:,:,:,1));

    %% Brainvoyager mask
function hdr=new_bv_msk(ds)
    hdr=xff('new:msk');
    [hdr,ds]=add_bv_mat_hdr(hdr,ds,'msk');

    nsamples=size(ds.samples,1);
    if nsamples~=1,
        error('Unsupported: more than 1 sample');
    end

    vol_data=unflatten(ds);
    hdr.Mask=scale_uint8(vol_data);

function scaled_data=scale_uint8(data)
    mn=min(data(:));
    mx=max(data(:));
    if mn<0 || mx>255 || ~isequal(round(data),data)
        cosmo_warning(['.samples does not fit integer range 0..255 ',...
                            'data will be rescaled']);
        data=255*(data-mn)/(mx-mn);
    end

    scaled_data=uint8(data);



%% AFNI
function afni_info=new_afni(ds)
    check_plump_orientation(ds);

    a=ds.a;
    mat=a.vol.mat;

    % deal with orientation
    idxs=zeros(1,3);
    m=zeros(1,3);

    % this part should be necessary
    for k=1:3
        % for each spatial dimension, find which row transforms it
        idx=find(mat(1:3,k));
        assert(numel(idx)==1); % ds is plump

        % store index and transformation matrix
        idxs(k)=idx;
        m(k)=mat(idx,k);
    end

    % set voxel size and origin
    % as the header was stored in LPI but AFNI likes RAI,
    % convert coordinates to RAI
    lpi2rai=[-1 -1 1];

    delta=m.*lpi2rai(idxs);
    origin=mat(idxs,:)*[1 1 1 1]'.*lpi2rai(idxs)';

    % set orientation code.
    % thse are neither RAI or LPI, but RPI (when ordered logically)
    % No idea why Bob Cox made that decision.
    lpi2orient=[-1 1 1];
    offset=(1-sign(m).*lpi2orient(idxs))/2;
    orient=(idxs-1)*2+offset;

    [nsamples,nfeatures]=size(ds.samples);

    vol_data=unflatten(ds);
    dim=ds.a.vol.dim(:)';
    vol_dim=[size(vol_data) 1]; % in case of singleton in last dimension
    assert(isequal(vol_dim(1:3),dim));
    assert(prod(dim)>=nfeatures);


    brik_type=1; %functional head
    brik_typestring='3DIM_HEAD_FUNC';
    brik_func=11; % FUNC_BUCK_TYPE

    if isfield(ds.a.vol,'xform')
        xform=ds.a.vol.xform;
    else
        xform=''; % unknown
    end
    xform_code=cosmo_fmri_convert_xform('afni',xform);

    brik_view=xform_code; % default to +orig, but overriden by writer

    afni_info=struct();
    afni_info.SCENE_DATA=[brik_view, brik_func, brik_type];
    afni_info.TYPESTRING=brik_typestring;
    afni_info.BRICK_TYPES=3*ones(1,nsamples); % store in float format
    afni_info.BRICK_STATS=[];                 % ... and thus need no stats
    afni_info.BRICK_FLOAT_FACS=[];            % ... or multipliers
    afni_info.DATASET_RANK=[3 nsamples];      % number of volumes
    afni_info.DATASET_DIMENSIONS=dim(1:3);
    afni_info.ORIENT_SPECIFIC=orient;
    afni_info.DELTA=delta(:)';
    afni_info.ORIGIN=origin(:)';
    afni_info.SCALE=0;
    afni_info.NOTES_COUNT=0;
    afni_info.WARP_TYPE=[0 0];
    afni_info.FileFormat='BRIK';

    [unused, unused, endian_ness] = computer();
    afni_info.BYTEORDER_STRING = sprintf('%sSB_FIRST', endian_ness);

    set_empty={'BRICK_LABS','BRICK_KEYWORDS',...
                'BRICK_STATS','BRICK_FLOAT_FACS',...
                'BRICK_STATAUX','STAT_AUX'};
    for k=1:numel(set_empty)
        fn=set_empty{k};
        afni_info.(fn)=[];
    end

    % if labels for the samples, store them in the header
    if isfield(ds.sa,'labels') && ~isempty(ds.sa.labels)
        afni_info.BRICK_LABS=cosmo_strjoin(ds.sa.labels,'~');
    end

    if isfield(ds.sa,'stats') && ~isempty(ds.sa.stats)
        afni_info=cosmo_structjoin(afni_info,cosmo_statcode(ds,'afni'));
    end

    % store data in non-afni field 'img'
    afni_info.img=vol_data;

function write_afni(fn, hdr)

    hdr.RootName=fn;
    data=hdr.img; % get the data
    hdr=rmfield(hdr,'img'); % remove the non-afni field 'img'

    afniopt=struct();
    afniopt.Prefix=fn; %the second input argument
    afniopt.OverWrite='y';
    afniopt.NoCheck=0;
    afniopt.AppendHistory=false;
    afniopt.verbose=0;
    afniopt.Scale=0;
    afniopt.AdjustHeader='no';

    if ends_with({'+orig','+orig.HEAD','+orig.BRIK',...
                           '+orig.BRIK.gz'},fn)
        hdr.SCENE_DATA(1)=0;
        afniopt.View='+orig';
    elseif ends_with({'+tlrc','+tlrc.HEAD',...
                           '+tlrc.BRIK','+tlrc.BRIK.gz'},fn)
        hdr.SCENE_DATA(1)=2;
        afniopt.View='+tlrc';
    else
        error('Unsupported scene data for %s', fn);
    end

    [err, ErrMessage]=WriteBrik(data, hdr, afniopt);
    if err
        error(ErrMessage);
    end


 function s=set_all(s, fns, v)
    % sets all fields in fns in struct s to v
    % if v is omitted it is set to 0.
    if nargin<3, v=0; end
    n=numel(fns);
    for k=1:n
        fn=fns{k};
        s.(fn)=v;
    end
