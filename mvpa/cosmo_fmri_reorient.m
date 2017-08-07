function ds=cosmo_fmri_reorient(ds, new_orient)
% Change the orientation of an fmri dataset
%
% ds_reorient=cosmo_fmri_reorient(ds, new_orient)
%
% Inputs
%     ds                fmri-dataset
%     new_orient        new orientation for the dataset (see below for a
%                       full list)
%
% Example:
%     ds=cosmo_synthetic_dataset();
%     cosmo_disp(ds.a);
%     > .fdim
%     >   .labels
%     >     { 'i'  'j'  'k' }
%     >   .values
%     >     { [ 1         2         3 ]  [ 1         2 ]  [ 1 ] }
%     > .vol
%     >   .mat
%     >       [ 2         0         0        -3
%     >         0         2         0        -3
%     >         0         0         2        -3
%     >         0         0         0         1 ]
%     >   .dim
%     >     [ 3         2         1 ]
%     >     .xform
%     >       'scanner_anat'
%     cosmo_disp(ds.fa);
%     > .i
%     >   [ 1         2         3         1         2         3 ]
%     > .j
%     >   [ 1         1         1         2         2         2 ]
%     > .k
%     >   [ 1         1         1         1         1         1 ]
%     ds_reorient=cosmo_fmri_reorient(ds,'AIR');
%     cosmo_disp(ds_reorient.a);
%     > .fdim
%     >   .labels
%     >     { 'i'  'j'  'k' }
%     >   .values
%     >     { [ 1         2 ]  [ 1 ]  [ 1         2         3 ] }
%     > .vol
%     >   .mat
%     >     [   0         0        -2         5
%     >        -2         0         0         3
%     >         0         2         0        -3
%     >         0         0         0         1 ]
%     >   .dim
%     >     [ 2         1         3 ]
%     >     .xform
%     >       'scanner_anat'
%     cosmo_disp(ds_reorient.fa);
%     > .i
%     >   [ 1         2         1         2         1         2 ]
%     > .j
%     >   [ 1         1         1         1         1         1 ]
%     > .k
%     >   [ 1         1         2         2         3         3 ]
%
%     % Many orientations are invalid, for example
%     ds=cosmo_synthetic_dataset();
%     cosmo_reorient(ds,'ALR');
%     error('illegal orientation');
%
% Notes:
%   - there are 3!*3^2 valid orientations, these are:
%         'SAR'  'SAL'  'SPR'  'SPL'  'IAR'  'IAL'  'IPR'  'IPL'
%         'SRA'  'SLA'  'SRP'  'SLP'  'IRA'  'ILA'  'IRP'  'ILP'
%         'ASR'  'ASL'  'PSR'  'PSL'  'AIR'  'AIL'  'PIR'  'PIL'
%         'ARS'  'ALS'  'PRS'  'PLS'  'ARI'  'ALI'  'PRI'  'PLI'
%         'RAS'  'LAS'  'RPS'  'LPS'  'RAI'  'LAI'  'RPI'  'LPI'
%         'RSA'  'LSA'  'RSP'  'LSP'  'RIA'  'LIA'  'RIP'  'LIP'
%     For example, 'LPI' (used in Talairach/MNI) means that
%       * the first dimension goes from left to right
%       * the second dimension goes from posterior to anterior
%       * the third dimension goes from inferior to superior
%   - this function chances the orientation information by adjusting
%     information in .fa and .a.fdim; contents of .samples remains
%     unchanged.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    cosmo_check_dataset(ds,'fmri');

    ds_orient=cosmo_fmri_orientation(ds);
    upper_new_orient=upper(new_orient);
    [perm, flip]=get_transform(ds_orient,upper_new_orient);

    fmri_dim_labels={'i','j','k'};

    ds_fa=ds.fa;

    % initialize output
    fa=ds_fa;
    mat=zeros(4);
    mat(4,4)=1;
    dim_size=zeros(1,3);
    dim_values=cell(3,1);

    for dim=1:3
        dim_label=fmri_dim_labels{perm(dim)};
        v=ds_fa.(dim_label);

        [unused,idx,unused,dim_name,values]=cosmo_dim_find(ds,dim_label);
        nvalues=max(values);
        if flip(dim)
            v=nvalues+1-v;
            mat(perm(dim),4)=nvalues+1;
            mat(perm(dim),dim)=-1;
        else
            mat(perm(dim),dim)=1;
        end

        dim_size((dim))=nvalues;

        new_dim_label=fmri_dim_labels{(dim)};
        fa.(new_dim_label)=v;
        dim_values{dim}=1:nvalues;
    end

    ds.a.fdim.values=dim_values;
    ds.a.vol.mat=ds.a.vol.mat*(mat);
    ds.a.vol.dim=dim_size;
    ds.fa=fa;

    ind=sub2ind(dim_size,ds.fa.i, ds.fa.j, ds.fa.k);
    [foo,i]=sort(ind);
    ds=cosmo_slice(ds,i,2,false);

    assert(isequal(cosmo_fmri_orientation(ds),upper_new_orient));



function [perm, flip]=get_transform(src, trg)
    is_valid=true;

    labs=['LR';'PA';'IS'];
    perm=zeros(1,3);
    flip=false(1,3);
    for dim=1:3
        [src_i,src_j]=find(src(dim)==labs);
        [trg_i,trg_j]=find(bsxfun(@eq,trg',labs(src_i,:)));
        if numel(trg_i)~=1
            is_valid=false;
            break;

        end
        perm(trg_i)=dim;
        flip(trg_i)=src_j~=trg_j;
    end

    if ~isequal(sort(perm),1:3)
        is_valid=false;
    end

    if ~is_valid
        error(['illegal target orientation; run\n'...
               '   help %s\nto see a list of valid orientations'],...
                    mfilename());
    end



