function test_suite = test_fmri_convert_xform()
% tests for cosmo_fmri_convert_xform
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite

function test_fmri_convert_xform_basics
    aeq=@(result,varargin)assertEqual(result,...
                            cosmo_fmri_convert_xform(varargin{:}));

    % - NIFTI
    aeq('scanner_anat','nii',1);
    aeq('aligned_anat','nii',2);
    aeq('talairach','nii',3);
    aeq('mni_152','nii',4);
    % any unknown number returns 'scanner_anat'
    aeq('scanner_anat','nii',0);
    aeq('scanner_anat','nii',NaN);

    % - AFNI
    aeq('scanner_anat','afni',0);
    aeq('aligned_anat','afni',1);
    aeq('talairach','afni',2);
    aeq('scanner_anat','afni',3);
    % any unknown number returns 'scanner_anat'
    aeq('scanner_anat','afni',10);
    aeq('scanner_anat','afni',NaN);

    % - BV
    % any number returns 'talairach'
    aeq('talairach','bv',0);
    aeq('talairach','bv',1);
    aeq('talairach','bv',2);
    aeq('talairach','bv',3);
    aeq('talairach','bv',NaN);

    % String to number:

    % - NIFTI
    aeq(1,'nii','scanner_anat')
    aeq(2,'nii','aligned_anat')
    aeq(3,'nii','talairach')
    aeq(4,'nii','mni_152')
    aeq(1,'nii','unknown')

    % - AFNI
    aeq(0,'afni','scanner_anat')
    aeq(1,'afni','aligned_anat')
    aeq(2,'afni','talairach')
    % treat as talairach
    aeq(2,'afni','mni_152')
    % unkown
    aeq(0,'afni','unknown')

    % - BV
    % all are unknown in BV, because BV does not support this
    aeq(0,'bv','scanner_anat')
    aeq(0,'bv','aligned_anat')
    aeq(0,'bv','talairach')
    aeq(0,'bv','mni_152')
    aeq(0,'bv','unknown')

    % any other input gives an error
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_fmri_convert_xform(varargin{:}),'');
    aet('unknown','talairach')
    aet('unknown',1)
    aet(struct(),1);
    aet(cell(1),1);
