function tr_xform=cosmo_fmri_convert_xform(fmt, xform)
% convert xform code between numeric and string in fmri dataset
%
% tr_xform=cosmo_fmri_convert_xform(fmt, xform)
%
% Inputs:
%   fmt              one of:
%                    - 'nii' (nifti)
%                    - 'afni' (afni)
%                    - 'bv' (BrainVoyager)
%   xform            either
%                    - a string, in which it must be one of
%                       'scanner_anat','aligned_anat','talairach',
%                       'mni_152', 'unknown'
%                    - a number, in which case it must be the view type for
%                       nii (sform or qform) or afni (the first elment of
%                       SCENE_TYPE). Any number in bv corresponds with
%                       'unknown'.
%
% Output:
%   tr_xform         if the input is a string, then the output is the
%                    corresponding view type (numeric); and vice versa
%                    if the viewtype cannot be found, the string 'unknown'
%                    or the corresponding view type is returned
%
% Examples
%     % Number to string:
%
%     % - NIFTI
%     cosmo_fmri_convert_xform('nii',1)
%     > scanner_anat
%     cosmo_fmri_convert_xform('nii',2)
%     > aligned_anat
%     cosmo_fmri_convert_xform('nii',3)
%     > talairach
%     cosmo_fmri_convert_xform('nii',4)
%     > mni_152
%     % any unknown number returns 'scanner_anat'
%     cosmo_fmri_convert_xform('nii',0)
%     > scanner_anat
%     cosmo_fmri_convert_xform('nii',NaN)
%     > scanner_anat
%
%     % - AFNI
%     cosmo_fmri_convert_xform('afni',0)
%     > scanner_anat
%     cosmo_fmri_convert_xform('afni',1)
%     > aligned_anat
%     cosmo_fmri_convert_xform('afni',2)
%     > talairach
%     % any unknown number returns 'scanner_anat'
%     cosmo_fmri_convert_xform('afni',10)
%     > scanner_anat
%     cosmo_fmri_convert_xform('afni',NaN)
%     > scanner_anat
%
%     % - BV
%     % any number returns 'talairach'
%     cosmo_fmri_convert_xform('bv',0)
%     > talairach
%     cosmo_fmri_convert_xform('bv',NaN)
%     > talairach
%
%     % String to number:
%
%     % - NIFTI
%     cosmo_fmri_convert_xform('nii','scanner_anat')
%     > 1
%     cosmo_fmri_convert_xform('nii','aligned_anat')
%     > 2
%     cosmo_fmri_convert_xform('nii','talairach')
%     > 3
%     cosmo_fmri_convert_xform('nii','mni_152')
%     > 4
%     cosmo_fmri_convert_xform('nii','unknown')
%     > 1
%
%     % - AFNI
%     cosmo_fmri_convert_xform('afni','scanner_anat')
%     > 0
%     cosmo_fmri_convert_xform('afni','aligned_anat')
%     > 1
%     cosmo_fmri_convert_xform('afni','talairach')
%     > 2
%     % treat as talairach
%     cosmo_fmri_convert_xform('afni','mni_152')
%     > 2
%     % unkown
%     cosmo_fmri_convert_xform('afni','unknown')
%     > 0
%
%     % - BV
%     % all are unknown in BV, because BV does not support this
%     cosmo_fmri_convert_xform('bv','scanner_anat')
%     > 0
%     cosmo_fmri_convert_xform('bv','aligned_anat')
%     > 0
%     cosmo_fmri_convert_xform('bv','talairach')
%     > 0
%     cosmo_fmri_convert_xform('bv','mni_152')
%     > 0
%     cosmo_fmri_convert_xform('bv','unknown')
%     > 0
%
%     % any other input gives an error
%     cosmo_fmri_convert_xform('unknown','talairach')
%     > error('unsupported format ''unknown''')
%     cosmo_fmri_convert_xform('unknown',1)
%     > error('unsupported format ''unknown''')
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #




    [x,y]=get_mapping(fmt);

    if isnumeric(xform)
        % convert numeric to string
        i=find(y==xform,1,'first');
        if isempty(i)
            tr_xform=get_default(x,y);
        else
            tr_xform=x{i};
        end

    elseif ischar(xform)
        % convert string to numeric
        i=find(cosmo_match(x,xform),1,'first');
        if isempty(i)
            [unused,tr_xform]=get_default(x,y);
        else
            assert(numel(i)==1);
            tr_xform=y(i);
        end
    else
        error('unsupported input');
    end

function [xd,yd]=get_default(x,y)
    i=find(isnan(y));
    assert(numel(i)==1);
    xd=x{i};

    msk=cosmo_match(x,xd);
    msk(i)=false;

    j=find(msk);
    assert(numel(j)==1);
    yd=y(j);



function [x,y]=get_mapping(fmt)
    if ~ischar(fmt)
        error('first argument must be a string');
    end

    % mapping from codes to indices
    switch fmt
        case 'nii'
            codes={'scanner_anat',1;...
                    'aligned_anat',2;...
                    'talairach',3;...
                    'mni_152',4;...
                    'scanner_anat',NaN}; % default

        case 'afni'
            codes={'scanner_anat',0;...
                   'aligned_anat',1;... % ACPC
                   'talairach',2;...
                   'mni_152',2;...
                   'scanner_anat',NaN}; % default

        case 'bv'
            codes={'talairach',0;...
                    'talairach',NaN}; %

        otherwise
            error('unsupported format ''%s''', fmt);
    end

    x=codes(:,1);
    y=cell2mat(codes(:,2));









