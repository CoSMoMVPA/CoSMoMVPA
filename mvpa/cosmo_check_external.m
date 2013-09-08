function is_present=cosmo_check_external(external, error_if_not_present)
% Checks whether a certain external toolbox exists
%
% is_present=cosmo_check_external(external[, error_if_not_present])
%
% Inputs:
%   external               string or cell of strings. Currently supports 
%                  '       'afni', 'neuroelf', 'nifti'.
%   error_if_not_present   if true (the default), an error is raised if the
%                          external is not present. 
%
% Returns:
%   is_present             boolean indicating whether the external is
%                          present. If external is a cell if P elements, 
%                          then the output is a Px1 boolean vector.
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
    
    if ~isfield(externals, external);
        error('Unknown external %s', external);
    end

    ext=externals.(external);
    is_present=ext.check();


    if ~is_present && error_if_not_present
        msg=sprintf(['The %s is required, but it was not found in the ',...
                    'matlab path. If it is not present on your system, ',...
                    'download it from:\n\n    %s\n\nthen add the ',...
                    'necessary directories to the matlab path.'], ...
                    ext.label, ext.url);
        error(msg);
    end



function externals=get_externals()
    % helper function that defines the externals.
    externals=struct();
    externals.afni.check=@() ~isempty(which('BrikLoad'));
    externals.afni.label='AFNI Matlab library';
    externals.afni.url='http://afni.nimh.nih.gov/afni/matlab/';


    externals.neuroelf.check=@() ~isempty(which('xff'));
    externals.neuroelf.label='NeuroElf toolbox';
    externals.neuroelf.url='http://neuroelf.net';

    externals.nifti.check=@() ~isempty(which('load_nii'));
    externals.nifti.label='NIFTI toolbox';
    externals.nifti.url=['http://www.mathworks.com/matlabcentral/',...
                         'fileexchange/8797-tools-for-nifti-and-analyze-image'];

                        


