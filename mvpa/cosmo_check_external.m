function is_present=cosmo_check_external(external, error_if_not_present)
% Checks whether a certain external toolbox exists, or list citation info
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
%                          'surfing'   surfing toolbox
%                          'gifti'     GIfTI library for matlab
%                          It can also be '-list', in which case it returns
%                          a cell of strings containing the available
%                          externals.
%   error_if_not_present   if true (the default), an error is raised if the
%                          external is not present. 
%
% Returns:
%   is_present             boolean indicating whether the external is
%                          present. If external is a cell if P elements, 
%                          then the output is a Px1 boolean vector. 
%                          Special switches allowed are:
%                            '-list':   returns a cell of strings with
%                                       the available externals
%                            '-tic':    reset list of cached externals
%                                       (see note below)
%                            '-toc':    returns a cell of string of
%                                       all externals queried so far
%                            '-cite':   prints a list of publications to
%                                       cite based on the output from
%                                       '-toc'
%
% Examples:
%   % see if the AFNI matlab toolbox is available, if not raise an error
%   cosmo_check_external('afni')
%   
%   % see if libsvm and neuroelf are available and store the result in 
%   % the 2x1 boolean array is_present. An error is not raised if 
%   % either is not present.
%   is_present=cosmo_check_external({'libsvm','neuroelf'},false);
%
%   % list the available externals
%   cosmo_check_external('-list')
%
%   % reset the list of cached externals, so that using '-cite' below
%   % will only show externals checked since this reset
%   cosmo_check_external('-tic')
%
%   % check two externals
%   cosmo_check_external({'afni','neuroelf'});
%
%   % list the externals checked for since the last '-tic'
%   cosmo_check_external('-toc')
%
%   % list the publications associated with the externals
%   cosmo_check_external('-cite');
%
% Notes:
%   - For performance reasons, keep a persistent variable with the names
%     of externals that have already been checked for.
%     Benchmarking suggests a speedup of at least a factor of 30.
%     
%     If the user changes the path in between successive calls of this
%     function and removes a toolbox from the path, then this function may
%     incorrectly report the external present when
%     using cosmo_check_external, with a less user-friendly error message
%     as a result
%
% NNO Sep 2013  


    persistent cached_external_names

    if nargin<2
        error_if_not_present=true;
    end

    if strcmp(external,'-tic')
        % clear cache
        cached_external_names=[];
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

    if ~iscell(cached_external_names)
        % not set, initialize to empty
        cached_external_names=cell(0);
    end
    
    if external(1)=='-'
        % process special user switch
        switch external(2:end)
            case 'list'
                % return a list of externals
                supported_externals=fieldnames(get_externals());
                me=str2func(mfilename()); % the present function
                
                cached_external_names_copy=cached_external_names;
                msk=me(supported_externals,false);
                cached_external_names=cached_external_names_copy;
                
                is_present=supported_externals(msk);
                
            case 'tic'
                cached_external_names=cell(0);
                
            case 'toc'
                is_present=cached_external_names;
                
            case 'cite'
                citation_str=get_citation_str(cached_external_names);
                fprintf(['If you use CoSMoMVPA and/or some '...
                         'other toolboxes for a publication, '...
                        'please cite:\n\n%s\n'], citation_str);
                is_present=[];
                
            otherwise
                error('illegal switch %s', external);     
        end
        
        return
    end
    
    if any(cosmo_match(cached_external_names,external))
        is_present=true;
        return;
    end

    externals=get_externals();
    if ~isfield(externals, external);
        error('Unknown external %s', external);
    end

    ext=externals.(external);
    is_present=ext.is_present();
    is_recent=ext.is_recent();
    
    if is_present && is_recent
        % everything ok, add to cached_external_names
        if ~iscell(cached_external_names)
            cached_external_names=cell(0);
        end
        if all(~cosmo_match(cached_external_names,external))
            cached_external_names{end+1}=external;
        end
    else
        if ~is_present
            msg=sprintf(['The %s is required, but it was not found in '...
                    'the matlab path. If it is not present on your '...
                    'system, download it from:\n\n    %s\n\nthen, if '...
                    'applicable, add the necessary directories '...
                    'to the matlab path.'], ...
                    ext.label, ext.url);
        
        elseif ~is_recent
            msg=sprintf(['The %s was found on your matlab path, but '...
                    'seems out of date. Please download the latest '...
                    'version from:\n\n %s\n\nthen, if '...
                    'applicable, add the necessary directories '...
                    'to the matlab path.'], ...
                    ext.label, ext.url);
        else
            assert(false); % should never get here
        end
        
        if error_if_not_present
            error(msg);
        end
        
    end
    
        


function externals=get_externals()
    % helper function that defines the externals.
    externals=struct();
    yes=@() true;
    
    externals.cosmo.is_present=yes;
    externals.cosmo.is_recent=yes;
    externals.cosmo.label='CoSMoMVPA toolbox';
    externals.cosmo.url='http://cosmomvpa.org';
    externals.cosmo.authors={'N N. Oosterhof','A. C. Connolly'};
    externals.cosmo.ref=['CoSMoMVPA: A lightweight multi-variate '...
                         'pattern analysis toolbox in Matlab'];
    
    externals.afni_bin.is_present=@() isunix() && ...
                          ~unix('which afni && afni --version >/dev/null');
    externals.afni_bin.is_recent=yes;
    externals.afni_bin.label='AFNI';
    externals.afni_bin.url='http://afni.nimh.nih.gov/afni';
    externals.afni_bin.authors={'R. W. Cox'};
    externals.afni_bin.ref=['AFNI: Software for analysis and '...
                             'visualization of functional magnetic '...
                             'resonance neuroimages.  Computers and '...
                             'Biomedical Research, 29: 162-173, 1996'];
    
    externals.afni.is_present=@() ~isempty(which('BrikLoad'));
    externals.afni.is_recent=@() ~isempty(which('afni_niml_readsimple'));
    externals.afni.label='AFNI Matlab library';
    externals.afni.url='http://afni.nimh.nih.gov/afni/matlab/';
    externals.afni.authors={'Z. Saad','G. Chen'};                         

    externals.neuroelf.is_present=@() ~isempty(which('xff'));
    externals.neuroelf.is_recent=yes;
    externals.neuroelf.label='NeuroElf toolbox';
    externals.neuroelf.url='http://neuroelf.net';
    externals.neuroelf.authors={'J. Weber'};

    externals.nifti.is_present=@() ~isempty(which('load_nii'));
    externals.nifti.is_recent=yes;
    externals.nifti.label='NIFTI toolbox';
    externals.nifti.url=['http://www.mathworks.com/matlabcentral/',...
                    'fileexchange/8797-tools-for-nifti-and-analyze-image'];
    externals.nifti.authors={'J. Shen'};
    
    externals.fieldtrip.is_present=@() ~isempty(which('ft_read_data'));
    % in the future, may require from 2014 onwards
    %externals.fieldtrip.is_recent=getfield(dir(which('ft_databrowser')),...
    %                                        'datenum')>datenum(2014,1,1);
    externals.fieldtrip.is_recent=yes;
    externals.fieldtrip.label='FieldTrip toolbox';
    externals.fieldtrip.url='http://fieldtrip.fcdonders.nl';
    externals.fieldtrip.authors={'R. Oostenveld','P. Fries','E. Maris',...
                                 'J.-M. Schoffelen'};
    externals.fieldtrip.ref=['FieldTrip: Open Source Software for '...
                              'Advanced Analysis of MEG, EEG, and '...
                              'Invasive Electrophysiological Data, '...
                              'Computational Intelligence and '...
                              'Neuroscience, vol. 2011, ',...
                              'Article ID 156869, 9 pages, 2011.',...
                              'doi:10.1155/2011/156869'];

    externals.libsvm.is_present=@() ~isempty(which('svmpredict')) && ...
                                ~isempty(which('svmptrain'));
    externals.libsvm.is_recent=yes;
    externals.libsvm.label='LIBSVM';
    externals.libsvm.url='http://www.csie.ntu.edu.tw/~cjlin/libsvm';
    externals.libsvm.authors={'C.-C. Chang and C.-J. Lin'};
    externals.libsvm.ref=['LIBSVM: '...
                            'a library for support vector machines. '...
                            'ACM Transactions on Intelligent Systems '...
                            'and Technology, 2:27:1--27:27, 2011'];
    
    externals.surfing.is_present=@() ~isempty(which(...
                                            'surfing_voxelselection'));
    % require recent version with surfing_write
    externals.surfing.is_recent=~isempty(which('surfing_write'));
    externals.surfing.label='Surfing toolbox';
    externals.surfing.url='http://github.com/nno/surfing';
    externals.surfing.authors={'N. N. Oosterhof','T Wiestler',...
                                'J. Diedrichsen'};
    externals.surfing.ref=['A comparison of volume-based and '...
                            'surface-based multi-voxel pattern '...
                            'analysis. Neuroimage 56 (2), 593-600'];
    
    externals.gifti.is_present=@() ~isempty(which('gifti'));
    externals.gifti.is_recent=yes;
    externals.gifti.label='GIfTI library for matlab';
    externals.gifti.url='www.artefact.tk/software/matlab/gifti';
    externals.gifti.authors={'G. Flandin'};
    
   
    

function citation_str=get_citation_str(cached_external_names)
    % always cite CoSMoMVPA
    self='cosmo';
    if ~any(cosmo_match(cached_external_names,self))
        cached_external_names{end+1}=self;
    end
    
    externals=get_externals();
    
    n=numel(cached_external_names);
    cites=cell(n,1);
    
    for k=1:n
        external_name=cached_external_names{k};
        assert(isfield(externals,external_name));
        
        external=externals.(external_name);
        
        if isfield(external,'ref')
            % reference provided, use label to prefix URL
            title_str=external.ref;
            url_prefix_str=sprintf('%s ', external.label);
        else
            % no reference, use label as title and no prefix for URL
            title_str=external.label;
            url_prefix_str='';
        end
        
        % ensure CoSMoMVPA is mentioned first
        cites{n-k+1}=sprintf('%s, %s. %savailable online from %s',...
                             cosmo_strjoin(external.authors,', '),...
                             title_str, url_prefix_str, external.url);
                    
    end
    
    citation_str=cosmo_strjoin(cites,'\n\n');
                    
        
        
        
    