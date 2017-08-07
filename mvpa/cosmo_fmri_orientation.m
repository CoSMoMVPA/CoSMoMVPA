function [orient,cano_rot]=cosmo_fmri_orientation(ds)
% get orientation of a dataset
%
% [orient,cano_rot]=cosmo_fmri_orientation(ds)
%
% Inputs:
%    ds             fmri dataset struct;
%
% Output:
%    orient         three letter string indicating the orientation of this
%                   dataset
%    cano_rot       canonical rotation matrix (relative to LPI)
%
% Example:
%     ds=cosmo_synthetic_dataset();
%     [orient,cano_rot]=cosmo_fmri_orientation(ds)
%     > orient = LPI
%     > cano_rot = 1 0 0 0
%     >            0 1 0 0
%     >            0 0 1 0
%     >            0 0 0 1
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
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    mx=get_affine_matrix(ds);

    rot_orig=mx(1:3,1:3);

    % normalize the rows
    rot_row_norms=sqrt(sum(rot_orig.^2,2));
    rot=bsxfun(@rdivide,rot_orig,rot_row_norms);

    cano_rot=get_canonical_matrix(rot);

    orient=get_orientation(cano_rot);

function cano_rot=get_canonical_matrix(rot)
    % find the three major axes of the rotation matrix
    visited=false(3);
    cano_rot=zeros(4);
    cano_rot(4,4)=1;

    for dim=1:3
        max_v=0;
        for row=1:3
            for col=1:3
                v=abs(rot(row,col));
                if ~visited(row,col) && v>max_v
                    max_row=row;
                    max_col=col;
                    max_v=v;
                end
            end
        end
        if max_v==0
            error('Illegal matrix');
        end
        visited(max_row,:)=true;
        visited(:,max_col)=true;

        cano_rot(max_row,max_col)=sign(rot(max_row,max_col));
    end

    assert(all(visited(:)));
    assert(all(sum(cano_rot~=0,1)==1));
    assert(all(sum(cano_rot~=0,2)==1));

function orient=get_orientation(cano_rot)
    labs=['LR';'PA';'IS'];

    orient='   ';
    for k=1:3
        col=find(cano_rot(1:3,k)~=0);
        assert(numel(col)==1);
        v=cano_rot(col,k);
        orient(k)=labs(col,1+(v<0));
    end


function mx=get_affine_matrix(ds)
    if cosmo_isfield(ds,'a.vol.mat')
        mx=ds.a.vol.mat;
    elseif isnumeric(ds) && size(ds,1)>=3 && size(ds,2)>=3
        mx=ds;
    else
        error('cannot find affine transformation matrix');
    end
