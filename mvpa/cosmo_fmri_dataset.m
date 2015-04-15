function ds = cosmo_fmri_dataset(filename, varargin)
% load an fmri volumetric dataset
%
% ds = cosmo_fmri_dataset(filename, [,'mask',mask],...
%                                   ['targets',targets],...
%                                   ['chunks',chunks])
%
% Inputs:
%   filename     filename of fMRI dataset, it should end with one of:
%                   .nii, .nii.gz                   NIFTI
%                   .hdr, .img                      ANALYZE
%                   +{orig,tlrc}.{HEAD,BRIK[.gz]}   AFNI
%                   .vmr, .vmp, .vtc, .glm, .msk    BrainVoyager
%                   .mat                            SPM (SPM.mat)
%                   .mat:beta                       SPM beta
%                   .mat:con                        SPM contrast
%                   .mat:spm                        SPM stats
%   'mask', m    filename for mask to be applied (which must contain a
%                single volume), or one of:
%                   '-all'     exclude features where all values are
%                              nonzero or nonfinite
%                   '-any'     exclude features where any value is
%                              nonzero or nonfinite
%                   '-auto'    require that '-all' and '-any' exclude the
%                              same features; if not throw an error
%                   true       equivalent to '-auto'
%                   false      do not apply a mask
%                If 'mask' is not given, then no mask is applied and a
%                warning message (suggesting to use a mask) is printed if
%                at least 5% of the values are non{zero,finite}.
%   'targets', t optional Tx1 numeric labels of experimental
%                conditions (where T is the number of samples (volumes)
%                in the dataset)
%   'chunks, c   optional Tx1 numeric labels of chunks, typically indices
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
%     .a.fdim.labels   dimension labels, set to {'i','j','k'}
%     .a.fdim.values   dimension values, set to {1:X, 1:Y, 1:Z}
%     .a.vol.dim 1x3 vector indicating the number of voxels in the 3
%                spatial dimensions.
%     .a.vol.mat 4x4 voxel-to-world transformation matrix (base-1).
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
%                                     'targets', [1 2 3 1 2 3]', ...
%                                     'mask', 'masks/brain_mask+tlrc);
%
%     % load BrainVoyager VMR file in directory 'mydata', and apply an
%     % automask that removes all features (voxels) that are zero or
%     % non-finite for all samples
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
% part of the NIFTI code is based on code by Robert W Cox, 2003,
% dedicated to the public domain.
%
% ACC, NNO Aug, Sep 2013, 2014

    % Input parsing stuff
    defaults.mask=[];
    defaults.targets=[];
    defaults.chunks=[];

    params = cosmo_structjoin(defaults, varargin);

    if string_endswith(filename,'.mat')
        filename=fast_import_data(filename);
    end

    % special case: if it's already a dataset, just return it
    if cosmo_check_dataset(filename,'fmri',false);
        ds=filename;
    else
        % get the supported image formats use the helper defined below
        ds=convert_to_dataset(filename, params);
    end

    % set chunks and targets
    ds=set_sa_vec(ds,params,'targets');
    ds=set_sa_vec(ds,params,'chunks');

    % compute mask
    mask=get_mask(ds,params.mask);

    if ~isempty(mask)
        % apply mask
        ds=cosmo_slice(ds,mask,2);
    end

    cosmo_check_dataset(ds, 'fmri'); % ensure all kosher


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% general helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img_formats=get_img_formats(params)

    % define which formats are supports
    % .exts indicates the extensions
    % .matcher says whether a struct is of the type
    % .reader should read a filaname and return a struct
    % .externals are fed to cosmo_check_externals
    img_formats=struct();

    img_formats.nii.exts={'.nii','.nii.gz','.hdr','.img'};
    img_formats.nii.matcher=@isa_nii;
    img_formats.nii.reader=@(fn)read_nii(fn,params);
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

    img_formats.spm.exts={'mat:con','mat:beta','mat:spm'};
    img_formats.spm.matcher=@isa_spm;
    img_formats.spm.reader=@(fn)read_spm(fn,params);
    img_formats.spm.externals=img_formats.nii.externals;

    img_formats.afni.exts={'+orig','+orig.HEAD','+orig.BRIK',...
                           '+orig.BRIK.gz','+tlrc','+tlrc.HEAD',...
                           '+tlrc.BRIK','+tlrc.BRIK.gz'};
    img_formats.afni.matcher=@isa_afni;
    img_formats.afni.reader=@read_afni;
    img_formats.afni.externals={'afni'};

    img_formats.ft_source.exts=cell(0);
    img_formats.ft_source.matcher=@isa_ft_source;
    img_formats.ft_source.reader=@read_ft_source;
    img_formats.ft_source.externals=cell(0);
    img_formats.ft_source.convert_volume=false;

function result=fast_import_data(fn)
    x=load(fn);
    keys=fieldnames(x);
    if numel(keys)~=1
        error('Cannot load .mat file %s with multiple variables: %s',...
                fn, cosmo_strjoin(keys,', '));
    end
    result=x.(keys{1});


function ds=convert_to_dataset(fn, params)
    img_formats_collection=get_img_formats(params);
    label=find_img_format(fn, img_formats_collection);

    % make sure the required externals exist
    img_format=img_formats_collection.(label);
    externals=img_format.externals;
    cosmo_check_external(externals);

    reader=img_format.reader;

    if isfield(img_format,'convert_volume') && ...
                ~img_format.convert_volume
        ds=reader(fn);
        return;
    end

    % read the data
    [data,vol,sa]=reader(fn);

    if ~isa(data,'double')
        data=double(data); % ensure data stored in double precision
    end

    % see how many dimensions there are, and their size
    data_size = size(data);
    ndim = numel(data_size);

    if ndim<4
        % simple reshape operation
        data=reshape(data,[1 data_size]);
    elseif ndim==4
        data=shiftdim(data,3);
    else
        error('need 3 or 4 dimensions, found %d', ndim);
    end

    % number of values in 3 spatial dimensions
    full_size=[size(data) 1 1];
    ni=full_size(2);
    nj=full_size(3);
    nk=full_size(4);

    % make a dataset
    ds=cosmo_flatten(data,{'i';'j';'k'},{1:ni;1:nj;1:nk});
    ds.sa=sa;
    ds.a.vol=vol;



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

function tf=string_endswith(s, tail)
    tf=ischar(s) && ~isempty(s) && isempty(cosmo_strsplit(s, tail, -1));


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
                if string_endswith(filename,ext)
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

    if ischar(filename)
        desc=sprintf('file ''%s''',filename);
    else
        desc=sprintf('<%s> input',class(filename));
    end
    error('Could not find image format for %s',desc);

function mask=get_mask(ds, mask_param)
    if isempty(mask_param)
        % not given; optionally give a suggestion about using an automask
        compute_auto_mask(ds.samples,'');
        mask=[];

    elseif (islogical(mask_param) && ~mask_param)
        % mask explicitly switched off
        mask=[];

    else
        if islogical(mask_param)
            assert(mask_param);
            mask_param='-auto';
        end

        if ~ischar(mask_param)
            error('mask must be a string');
        end

        assert(numel(mask_param)>0);
        if mask_param(1)=='-'
            mask=compute_auto_mask(ds.samples,mask_param(2:end));
        else
            me=str2func(mfilename()); % make immune to renaming

            % load mask (using recursion)
            ds_mask=me(mask_param,'mask',false);

            % if necessary, bring in the same space
            ds_orient=cosmo_fmri_orientation(ds);
            if ~isequal(ds_orient, cosmo_fmri_orientation(ds_mask))
                ds_mask=cosmo_fmri_reorient(ds_mask, ds_orient);
            end

            % ensure the mask is compatible with the dataset
            if ~isequal(ds_mask.fa,ds.fa) || ...
                            ~isequal(ds_mask.a.fdim,ds_mask.a.fdim)
                error(['feature attribute or size mismatch between '...
                                'data and mask']);
            end

            % check voxel-to-world mapping
            max_delta=1e-4; % allow for minor tolerance
            delta=max(abs(ds_mask.a.vol.mat(:)-ds.a.vol.mat(:)));
            if delta>max_delta
                error(['voxel dimension mismatch between data and mask:'...
                            'max difference is %.5f > %.5f'],...
                            delta,max_delta);
            end

            % only support single volume
            nsamples_mask=size(ds_mask.samples,1);
            if nsamples_mask~=1
                error('mask must have a single volume, found %d',...
                                                nsamples_mask);
            end

            % compute logical mask
            mask=ds_mask.samples~=0 & isfinite(ds_mask.samples);
        end
    end



function auto_mask=compute_auto_mask(data, mask_type)
    % mask_type can be 'any', 'all', 'auto', or ''
    % When using 'auto', 'any' and 'all' should give the same mask
    % When using '', a warning is shown when the percentage of
    % non{zero,finite} features exceeds pct_thrshold

    pct_threshold=5;

    to_remove=data==0 | ~isfinite(data);

    % take as a mask anywhere where any feature is nonzero.
    if cosmo_match({mask_type},{'any','auto',''})
        to_remove_any=any(to_remove,1);
    end

    if cosmo_match({mask_type},{'all','auto',''})
        to_remove_all=all(to_remove,1);
    end

    switch mask_type
        case {'auto',''}
            %
            any_equals_all=isequal(to_remove_any, to_remove_all);

            n=numel(to_remove_any);
            n_any=sum(to_remove_any(:));
            n_all=sum(to_remove_all(:));

            pct_any=100*n_any/n;
            pct_all=100*n_all/n;

            do_mask_suggestion=pct_all>pct_threshold && ...
                                strcmp(mask_type,'');

            if any_equals_all
                if do_mask_suggestion
                    me_name=mfilename();
                    msg=sprintf(['%d (%.1f%%) features are non'...
                                '{zero,finite} in all samples (and no '...
                                'features have non-{zero,finite} '...
                                'values in some samples and not '...
                                'in others)\n'...
                                'To use a mask excluding these '...
                                'features: %s(...,''mask'',-auto'')\n'],...
                                n_all,pct_all,me_name);
                    cosmo_warning(msg);

                    to_remove=[];
                else
                    to_remove=to_remove_any;
                end
            else
                % give error or warning
                me_name=mfilename();

                msg=sprintf(['%d (%.1f%%) features are non{zero,'...
                            'finite} in all samples\n'...
                            '%d (%.1f%%) features are non{zero,'...
                            'finite} in at least one sample\n'...
                            'To use a mask excluding '...
                            'features:\n'...
                            '- where *all* values are non{zero,finite}:'...
                            ' %s(...,''mask'',-all'')\n'...
                            '- where *any* value  is  non{zero,finite}:'...
                            ' %s(...,''mask'',-any'')\n'],...
                            n_all,pct_all,n_any,pct_any,me_name,me_name);

                if strcmp(mask_type,'auto');
                    error('automatic mask failed:\n%s',msg);
                else
                    % give a warning
                    cosmo_warning(msg);
                    % set mask to empty, so that a mask will not be applied
                    to_remove=[];
                end
            end
        case 'any'
            to_remove=to_remove_any;
        case 'all'
            to_remove=to_remove_all;
        otherwise
            error('illegal mask specification ''-%s''', mask_type);
    end

    auto_mask=~to_remove(:)';


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

function nii=load_nii_helper(fn)
    nii=struct();
    nii.hdr=load_untouch_header_only(fn);
    nii.img=nifti_load_img(fn);


function [data,vol,sa]=read_nii(fn, params)
    nii=get_and_check_data(fn, @load_nii_helper, @isa_nii);
    hdr=nii.hdr;
    data=nii.img;

    % image dimensions
    dim=hdr.dime.dim(2:4);

    % get scaling factor
    scaling=nifti_get_scaling_factor(hdr);

    % apply scaling
    if ~isempty(scaling)
        data(:)=scaling(1)+scaling(2)*data(:);
    end


     % get original affine matrix
    [mat, xform]=get_nifti_transform(hdr, params);

    % make matrix base1 friendly
    mat(1:3,4)=mat(1:3,4)+mat(1:3,1:3)*[-1 -1 -1]';

    vol.mat=mat;
    vol.xform=xform;
    vol.dim=dim;
    sa=struct();

function [mx, xform]=get_nifti_transform(hdr, varargin)
    % Get LPI affine transformation from NIFTI file
    %
    % Input:
    %   fn          nifti filename
    %
    % Output:
    %   mx          4x4 affine transformation matrix from voxel to world
    %               coordinates. voxel indices as base0, not base1 as in
    %               CoSMoMVPA
    %   xform       string with xform based on sform or qform code
    %
    % Notes:
    %  - this function is experimental
    %  - at the moment it relies on the quaternion values in the NIFTI header,
    %    and ignores srow* fields. (support for srow is future work)
    %  - initial testing suggests agreement with MRIcron (thanks to Chris
    %    Rorden for providing this software)
    %  - functionality in the subfunctions are based on nftii1_io.h in
    %    AFNI, written Robert W Cox (2003), public domain dedication;
    %    http://afni.nimh.nih.gov/afni/doc/source/nifti1__io_8c-source.html
    %  - to convert voxel coordinates (i,j,k) to (x,y,z), compute
    %    lpi_mx*[x y z 1]'. For the reverse, compute inv(lpi_mx)*[i j k 1]'
    %
    % NNO Dec 2014

    defaults.nifti_form=[];
    opt=cosmo_structjoin(defaults,varargin);

    if isempty(opt.nifti_form)
        [mx, nifti_form]=nifti_matrix_from_auto(hdr);
    else
        [mx, nifti_form]=nifti_matrix_using_method(hdr,opt.nifti_form);
    end

    % prioritize sformch
    switch nifti_form
        case 'sform'
            key=hdr.hist.sform_code;
        case 'qform'
            key=hdr.hist.qform_code;
        otherwise
            key=0;
    end

    xform=cosmo_fmri_convert_xform('nii',key);


function [mx, nifti_form]=nifti_matrix_from_auto(hdr)
    % get matrix automatically, assumes that qform and sform (if present)
    % are identical
    max_delta_s_and_q=1e-3; % maximum allowed difference between s and q

    has_sform=hdr.hist.sform_code>0;
    has_qform=hdr.hist.qform_code>0;

    if has_sform;
        nifti_form='sform';
    elseif has_qform
        nifti_form='qform';
    else
        nifti_form='pixdim';
    end

    mx=nifti_matrix_using_method(hdr,nifti_form);

    if has_sform && has_qform
        mx_q=nifti_matrix_using_method(hdr,'qform');

        max_diff=max(abs(mx(:)-mx_q(:)));
        if max_diff>max_delta_s_and_q
            str_mx=matrix2string(mx);
            str_mx_s=matrix2string(mx_q);
            url=['http://nifti.nimh.nih.gov/nifti-1/documentation/'...
                    'nifti1fields/nifti1fields_pages/qsform.html'];
            error(['the affine matrices mapping voxel-to-world '...
                    'coordinates according to the sform and qform '...
                    'in the NIFTI header differ '...
                    'by %d, exceeding the treshold %d.\n\n'...
                    'The sform matrix is:\n\n%s\n\n',...
                    'The qform matrix is:\n\n%s\n\n'...
                    'To resolve this, set the ''nifti_form'' '...
                    'option to either:\n'...
                    '  ''pixdim'' (method 1), or\n'...
                    '  ''qform''  (method 2), or\n'...
                    '  ''sform''  (method 3).\n\n'...
                    'For more information, see:\n  %s\n\n',...
                    'If you have absolutely no idea what to use, '...
                    'try ''sform''\n\n'],...
                    max_diff, max_delta_s_and_q,...
                    str_mx_s, str_mx, url);
        end
    end

function s=matrix2string(mx)
    float_pat='%6.3f';
    line_pat=repmat([float_pat ' '],1,4);
    line_pat(end)=sprintf('\n');
    mx_pat=repmat(line_pat,1,3);
    mx_3x4=mx(1:3,1:4);
    s=sprintf(mx_pat,mx_3x4');



function [mx, method]=nifti_matrix_using_method(hdr, method)

    switch method
        case 'pixdim'
            mx=nifti_matrix_from_pixdim(hdr);
        case 'qform'
            mx=nifti_matrix_from_qform(hdr);
        case 'sform'
            mx=nifti_matrix_from_sform(hdr);
        otherwise
            error('illegal method %s', method);
    end

    assert(isequal(size(mx),[4 4]));

function mx=nifti_matrix_from_pixdim(hdr)
    mx=[[diag(hdr.dime.pixdim(2:4)); 0 0 0] [0;0;0;1]];


function mx=nifti_matrix_from_qform(hdr)
    % convert quaternion to affine matrix
    qfac=hdr.dime.pixdim(1);
    dx=hdr.dime.pixdim(2);
    dy=hdr.dime.pixdim(3);
    dz=hdr.dime.pixdim(4);
    qb=hdr.hist.quatern_b;
    qc=hdr.hist.quatern_c;
    qd=hdr.hist.quatern_d;
    qx=hdr.hist.qoffset_x;
    qy=hdr.hist.qoffset_y;
    qz=hdr.hist.qoffset_z;

    % ported from MRIcron
    b=qb;
    c=qc;
    d=qd;
    a=1-(b^2+c^2+d^2);

    if a<1e-7
        a=1/sqrt(b^2+c^2+d^2);
        b=b*a;
        c=c*a;
        d=d*a;
        a=0;
    else
        a=sqrt(a);
    end

    if dx>0
        xd=dx;
    else
        xd=1;
    end

    if dy>0
        yd=dy;
    else
        yd=1;
    end

    if dz>0
        zd=dz;
    else
        zd=1;
    end

    if qfac<0
        zd=-zd;
    end

    % construct initial affine matrix
    mx=zeros(4,4);
    mx(1,1)=     (a*a+b*b-c*c-d*d) * xd ;
    mx(1,2)= 2 * (b*c-a*d        ) * yd ;
    mx(1,3)= 2 * (b*d+a*c        ) * zd ;
    mx(2,1)= 2 * (b*c+a*d        ) * xd ;
    mx(2,2)=     (a*a+c*c-b*b-d*d) * yd ;
    mx(2,3)= 2 * (c*d-a*b        ) * zd ;
    mx(3,1)= 2 * (b*d-a*c        ) * xd ;
    mx(3,2)= 2 * (c*d+a*b        ) * yd ;
    mx(3,3)=     (a*a+d*d-c*c-b*b) * zd ;
    mx(1,4)=qx;
    mx(2,4)=qy;
    mx(3,4)=qz;
    mx(4,:)=[0 0 0 1];

function mx=nifti_matrix_from_sform(hdr)
    % set the srow values
    mx=[hdr.hist.srow_x;...
        hdr.hist.srow_y;...
        hdr.hist.srow_z;...
        [0 0 0 1]];

function scaling=nifti_get_scaling_factor(hdr)
    % get scaling factor, if present for this dataset
    % scaling=[intercept slope] if present, otherwise []
    is_datatype=any(hdr.dime.datatype==[2,4,8,16,64,256,512,768]);
    is_nonidentity=hdr.dime.scl_inter~=0 || hdr.dime.scl_slope~=1;
    is_nonzero=hdr.dime.scl_slope~=0;

    if is_datatype && is_nonidentity && is_nonzero
        scaling=[hdr.dime.scl_inter hdr.dime.scl_slope];
    else
        scaling=[];
    end

function img=nifti_load_img(fn)
    nii=load_untouch_nii(fn);
    img=double(nii.img);



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
    mat=neuroelf_bvcoordconv_wrapper([],'bvx2tal',bbox);
    dim=bbox.DimXYZ;

    % deal with offset at (.5, .5, .5) [CHECKME]
    mat(1:3,4)=mat(1:3,4)+mat(1:3,1:3)*.5*[1 1 1]';

    vol=struct();
    vol.mat=mat;
    vol.dim=dim;
    vol.xform=cosmo_fmri_convert_xform('bv',NaN);

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
    data=hdr.Mask;
    vol=get_vol_bv(hdr);


% BV volume time course
function b=isa_bv_vtc(hdr)

    b=(isa(hdr,'xff') || isstruct(hdr)) && isfield(hdr, 'VTCData');

function [data,vol,sa]=read_bv_vtc(fn)
    hdr=get_and_check_data(fn, @xff_struct, @isa_bv_vtc);
    sa=struct();
    data=shiftdim(hdr.VTCData,1);
    vol=get_vol_bv(hdr);



%% AFNI
function b=isa_afni(hdr)
    b=isstruct(hdr) && isfield(hdr,'DATASET_DIMENSIONS') && ...
            isfield(hdr,'DATASET_RANK');

function [data,vol,sa]=read_afni(fn)
    if isa_afni(fn)
        if isfield(fn,'img')
            data=fn.img;
            hdr=fn;
            hdr=rmfield(hdr,'img');
        else
            error('AFNI struct has missing image data (field .img)');
        end
    else
        [err,data,hdr,err_msg]=BrikLoad(fn);
        if err
            error('Error reading afni file: %s', err_msg);
        end
    end

    sa=struct();

    if isfield(hdr,'BRICK_LABS') && ~isempty(hdr.BRICK_LABS);
        % if present, get labels
        labels=cosmo_strsplit(hdr.BRICK_LABS,'~');
        nsamples=hdr.DATASET_RANK(2);
        if numel(labels)==nsamples+1 && isempty(labels{end})
            labels=labels(1:(end-1));
        end
        sa.labels=labels(:);
    end

    if isfield(hdr,'BRICK_STATAUX') && ~isempty(hdr.BRICK_STATAUX);
        % if present, get stat codes
        sa.stats=cosmo_statcode(hdr);
    end

    vol=get_vol_afni(hdr);

function vol=get_vol_afni(hdr)
    % afni volume info
    orient='LPI'; % always return LPI-based matrix

    % origin and basis vectors in world space
    k=[0 0 0;eye(3)];

    [unused,i]=AFNI_Index2XYZcontinuous(k,hdr,orient);

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
    vol.xform=cosmo_fmri_convert_xform('afni',hdr.SCENE_DATA(1));


%% SPM
function b=isa_spm(hdr)
    b=isstruct(hdr) && isfield(hdr,'xX') && isfield(hdr.xX,'X') && ...
                isnumeric(hdr.xX.X) && isfield(hdr,'SPMid');

function [data,vol,sa]=read_spm(fn,params)
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
    else
        input_type='beta';
        spm_=fn;
        pth='';
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
        if ~exist(vol_fn,'file')
            error('Volume #%d not found: %s',k,vol_fn);
        end

        % show at most one warning, only at the beginning
        [vol_data_k, vol_k]=read_nii(vol_fn, params);

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

% FIeldTrip source struct
function  b=isa_ft_source(hdr)
    b=isstruct(hdr) && ((isfield(hdr,'inside') && isfield(hdr,'pos')) ||...
                        (cosmo_check_dataset(hdr,false) && ...
                         cosmo_isfield(hdr,'fa.pos')));

function ds=read_ft_source(ft)
    assert(isstruct(ft));

    if isfield(ft,'inside') && isfield(ft,'pos')
        % fieldtrip struct
        ds_meeg=cosmo_meeg_dataset(ft);
    else
        % must be dataset struct with field .fa.pos
        cosmo_isfield(ft,'fa.pos',true);
        ds_meeg=ft;
    end

    cosmo_check_dataset(ds_meeg,'meeg');

    ds=cosmo_vol_grid_convert(ds_meeg,'tovol');




