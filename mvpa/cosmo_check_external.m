function is_present=cosmo_check_external(external, error_if_not_present)
% Checks whether a certain external toolbox exists
%
% is_present=cosmo_check_external(external[, error_if_not_present])
%
% Inputs:
%   external               string or cell of strings. Currently supports: 
%                          'afni'      AFNI matlab toolbox
%                          'afni_bin'  AFNI binaries present (unix-only)
%                          'neuroelf'  Neuroelf toolbox
%                          'nifti'     NIFTI toolbox
%                          'fieldtrip' Fieldtrip
%                          'libsvm'    libSVM toolbox
%                          It can also be '-list', in which case it returns
%                          a cell of strings containing the available
%                          externals.
%   error_if_not_present   if true (the default), an error is raised if the
%                          external is not present. 
%
% Returns:
%   is_present             boolean indicating whether the external is
%                          present. If external is a cell if P elements, 
%                          then the output is a Px1 boolean vector. If
%                          externals=='-list', then is_present is a cell of
%                          strings containing the available externals
%
% Examples:
%   % see if the AFNI matlab toolbox is available, if not raise an error
%   >> cosmo_check_external('afni')
%   
%   % see if libsvm and neuroelf are available and store the result in 
%   % the 2x1 boolean array is_present. An error is not raised if 
%   % either is not present.
%   >> is_present=cosmo_check_external({'libsvm','neuroelf'},false);
%
%   % list the available externals
%   >> cosmo_check_external('-list')
%
% NNO Sep 2013  

    if nargin<2
        error_if_not_present=true;
    end

    if iscell(external)
        % cell input - check for each of them using recursion
        nexternals=numel(external);
        is_present=false(nexternals,1); % space for output
        me=str2func(mfilename()); % the present function
        for k=1:nexternals
            is_present(k)=me(external{k}, error_if_not_present);
        end
        return
    end

    externals=get_externals();
    
    if strcmp(external,'-list')
        % return a list of externals
        supported_externals=fieldnames(externals);
        me=str2func(mfilename()); % the present function
        msk=me(supported_externals,false);
        is_present=supported_externals(msk);
        return
    end

    if ~isfield(externals, external);
        error('Unknown external %s', external);
    end

    ext=externals.(external);
    is_present=ext.check();


    if ~is_present && error_if_not_present
        error(['The %s is required, but it was not found in the '...
                    'matlab path. If it is not present on your system, '...
                    'download it from:\n\n    %s\n\nthen, if '...
                    'applicable, add the necessary directories '...
                    'to the matlab path.'], ...
                    ext.label, ext.url);
    end



function externals=get_externals()
    % helper function that defines the externals.
    externals=struct();
    externals.afni.check=@() ~isempty(which('BrikLoad'));
    externals.afni.label='AFNI Matlab library';
    externals.afni.url='http://afni.nimh.nih.gov/afni/matlab/';
    
    externals.afni_bin.check=@() isunix() && ...
                          ~unix('which afni && afni --version >/dev/null');
    externals.afni_bin.label='AFNI suite';
    externals.afni_bin.url='http://afni.nimh.nih.gov/afni';

    externals.neuroelf.check=@() ~isempty(which('xff'));
    externals.neuroelf.label='NeuroElf toolbox';
    externals.neuroelf.url='http://neuroelf.net';

    externals.nifti.check=@() ~isempty(which('load_nii'));
    externals.nifti.label='NIFTI toolbox';
    externals.nifti.url=['http://www.mathworks.com/matlabcentral/',...
                         'fileexchange/8797-tools-for-nifti-and-analyze-image'];
    
    externals.fieldtrip.check=@() ~isempty(which('ft_read_data'));
    externals.fieldtrip.label='FieldTrip toolbox';
    externals.fieldtrip.url='http://fieldtrip.fcdonders.nl';

    externals.libsvm.check=@() ~isempty(which('svmpredict')) && ...
                                ~isempty(which('svmptrain'));
    externals.libsvm.label='LIBSVM';
    externals.libsvm.url='http://www.csie.ntu.edu.tw/~cjlin/libsvm';
    
    externals.surfing.check=@() ~isempty(which('surfing_voxelselection'));
    externals.surfing.label='Surfing toolbox';
    externals.surfing.url=['http://surfing.sourceforge.net'];
    
    