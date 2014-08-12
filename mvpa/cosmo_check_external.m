function is_ok=cosmo_check_external(external, raise_)
% Checks whether a certain external toolbox exists, or list citation info
%
% is_ok=cosmo_check_external(external[, raise_])
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
%                          'xunit'     xUnit unit test framework
%                          'matlabsvm' SVM classifier in matlab stats
%                                      toolbox
%                          'svm'       Either matlabsvm or libsvm
%                          '@{name}'   Matlab toolbox {name}
%                          It can also be '-list', '-tic', '-toc',' or
%                          '-cite'; see below for their meaning.
%   raise_                 if true (the default), an error is raised if the
%                          external is not present.
%
% Returns:
%   is_ok             boolean indicating whether the external is
%                          present. A matlab toolbox must be prefixed
%                          by a '@'. If external is a cell if P elements,
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
%   % see if libsvm and neuroelf are available, if not raise an error
%   cosmo_check_external({'libsvm','neuroelf'});
%
%   % see if libsvm and neuroelf and store the result in
%   % the 2x1 boolean array is_ok. An error is not raised if
%   % either is not present.
%   is_ok=cosmo_check_external({'libsvm','neuroelf'},false);
%
%   % see if the matlab 'stats' toolbox is available
%   cosmo_check_external('@stats');
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
%   - For performance reasons this function keeps a persistent variable
%     with the names of externals that have already been checked for.
%     Benchmarking suggests a speedup of at least a factor of 30.
%     If the user changes the path in between successive calls of this
%     function and removes a toolbox from the path, then this function may
%     incorrectly report the external present when
%     using cosmo_check_external, with a less user-friendly error message
%     as a result
%
% NNO Sep 2013


    persistent cached_present_names
    persistent cached_absent_names;
    persistent cached_path;

    if nargin<2
        raise_=true;
    end
    
    if cosmo_path_changed() || (ischar(external) && ...
                                        strcmp(external,'-tic'))
        % clear cache
        cached_present_names=cell(0);
        cached_absent_names=cell(0);
    end

    if iscell(external)
        % cell input - check for each of them using recursion
        nexternals=numel(external);
        is_ok=false(nexternals,1); % space for output
        me=str2func(mfilename()); % the present function
        for k=1:nexternals
            is_ok(k)=me(external{k}, raise_);
        end
        return
    end

    if external(1)=='-'
        % process special user switch
        switch external(2:end)
            case 'list'
                % return a list of externals
                supported_externals=fieldnames(get_externals());
                me=str2func(mfilename()); % the present function

                cached_present_names_copy=cached_present_names;
                msk=me(supported_externals,false);
                cached_present_names=cached_present_names_copy;

                is_ok=supported_externals(msk);

            case 'tic'
                cached_present_names=cell(0);

            case 'toc'
                is_ok=cached_present_names;

            case 'cite'
                citation_str=get_citation_str(cached_present_names);
                s=sprintf(['If you use CoSMoMVPA and/or some '...
                         'other toolboxes for a publication, '...
                        'please cite:\n\n%s\n'], citation_str);
                disp(s);
                is_ok=[];

            otherwise
                error('illegal switch %s', external);
        end

        return
    end

    if cosmo_match({external},cached_present_names)
        is_ok=true;
        return;
    elseif cosmo_match({external},cached_absent_names) && ~raise_
        is_ok=false;
        return;
    elseif external(1)=='@'
        toolbox_name=external(2:end);
        is_ok=check_matlab_toolbox(toolbox_name,raise_);
    else
        is_ok=check_external_toolbox(external,raise_);
    end

    % add if not in cache already
    if is_ok
        if ~cosmo_match({external},cached_present_names)
            cached_present_names{end+1}=external;
        end
    else
        if ~cosmo_match({external},cached_absent_names)
            cached_absent_names{end+1}=external;
        end
    end

function is_ok=check_external_toolbox(external_name,raise_)
    externals=get_externals();
    if ~isfield(externals, external_name);
        error('Unknown external ''%s''', external_name);
    end

    ext=externals.(external_name);
    if iscell(ext)
        % at least one of them must be ok
        is_ok=false;
        for j=1:numel(ext)
            is_ok=is_ok || check_external_toolbox(ext{j},false);
        end
        if ~is_ok && raise_
            error('None of the following externals was found: %s',...
                        cosmo_strjoin(ext,', '));
        end
        return
    end

    env=cosmo_wtf('environment');
    error_msg=[];

    % simulate goto statement
    while true
        if ~ext.is_present()
            error_msg=sprintf(['%s is required, but it was not '...
                'found in the %s path. If it is not present on your '...
                'system, obtain it from:\n\n    %s\n\nthen, if '...
                'applicable, add the necessary directories '...
                'to the %s path.'], ...
                ext.label(), env, url2str(ext.url), env);
            break;
        end

        if ~ext.is_recent()
            error_msg=sprintf(['%s was found on your %s path, but '...
                'seems out of date. Please download the latest '...
                'version from:\n\n %s\n\nthen, if '...
                'applicable, add the necessary directories '...
                'to the %s path.'], ...
                ext.label(), env, url2str(ext.url), env);
            break;
        end

        if isfield(ext,'conflicts')
            conflicts=ext.conflicts;
            names=fieldnames(conflicts);
            for k=1:numel(names)
                name=names{k};

                if ~externals.(name).is_present()
                    continue;
                end

                conflict=conflicts.(name);
                if conflict()
                    error_msg=sprintf(['%s conflicts with %s, making %s '...
                                    'unusable. You may '...
                                    'have to adjust the %s path '...
                                    'to resolve this.']...
                                    ,externals.(name).label(),...
                                    ext.label(),ext.label(),env);
                    break;
                end
            end
            if ~isempty(error_msg)
                break;
            end
        end

        break;
    end

    is_ok=isempty(error_msg);
    if ~is_ok && raise_
        error(error_msg);
    end

function is_ok=check_matlab_toolbox(toolbox_name,raise_)
    if cosmo_wtf('is_matlab')
        toolbox_dir=fullfile(toolboxdir(''),toolbox_name);
        is_ok=isdir(toolbox_dir);
    else
        is_ok=false;
    end
    if ~is_ok && raise_
        error('The matlab toolbox ''%s'' seems absent',...
                            toolbox_name);
    end


function s=url2str(url)
    if strcmp(cosmo_wtf('environment'),'matlab')
        s=sprintf('<a href="%s">%s</a>',url,url);
    else
        s=url;
    end

function externals=get_externals()
    % helper function that defines the externals.
    externals=struct();
    yes=@() true;
    has=@(x) ~isempty(which(x));
    has_toolbox=@(x)check_matlab_toolbox(x,false);
    path_of=@(x) fileparts(which(x));

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

    externals.afni.is_present=@() has('BrikLoad');
    externals.afni.is_recent=@() has('afni_niml_readsimple');
    externals.afni.label='AFNI Matlab library';
    externals.afni.url='http://afni.nimh.nih.gov/afni/matlab/';
    externals.afni.authors={'Z. Saad','G. Chen'};

    externals.neuroelf.is_present=@() has('xff');
    externals.neuroelf.is_recent=yes;
    externals.neuroelf.label='NeuroElf toolbox';
    externals.neuroelf.url='http://neuroelf.net';
    externals.neuroelf.authors={'J. Weber'};

    externals.nifti.is_present=@() has('load_nii');
    externals.nifti.is_recent=yes;
    externals.nifti.label='NIFTI toolbox';
    externals.nifti.url=['http://www.mathworks.com/matlabcentral/',...
                    'fileexchange/8797-tools-for-nifti-and-analyze-image'];
    externals.nifti.authors={'J. Shen'};

    externals.fieldtrip.is_present=@() has('ft_read_data');
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

    externals.libsvm.is_present=@() has('svmpredict') && ...
                                        has('svmtrain');
    externals.libsvm.is_recent=yes;
    externals.libsvm.label='LIBSVM';
    externals.libsvm.url='http://www.csie.ntu.edu.tw/~cjlin/libsvm';
    externals.libsvm.authors={'C.-C. Chang', 'C.-J. Lin'};
    externals.libsvm.ref=['LIBSVM: '...
                            'a library for support vector machines. '...
                            'ACM Transactions on Intelligent Systems '...
                            'and Technology, 2:27:1--27:27, 2011'];
    externals.libsvm.conflicts.matlabsvm=@() ~isequal(...
                                                path_of('svmpredict'),...
                                                path_of('svmtrain'));

    externals.surfing.is_present=has('surfing_voxelselection');
    % require recent version with surfing_write
    externals.surfing.is_recent=~isempty(which('surfing_write'));
    externals.surfing.label='Surfing toolbox';
    externals.surfing.url='http://github.com/nno/surfing';
    externals.surfing.authors={'N. N. Oosterhof','T. Wiestler',...
                                'J. Diedrichsen'};
    externals.surfing.ref=['A comparison of volume-based and '...
                            'surface-based multi-voxel pattern '...
                            'analysis. Neuroimage 56 (2), 593-600'];

    externals.gifti.is_present=@() has('gifti');
    externals.gifti.is_recent=yes;
    externals.gifti.label='GIfTI library for matlab';
    externals.gifti.url='www.artefact.tk/software/matlab/gifti';
    externals.gifti.authors={'G. Flandin'};

    externals.xunit.is_present=@() has('runtests') && ...
                                    has('VerboseTestRunDisplay');
    externals.xunit.is_recent=yes;
    externals.xunit.label='MATLAB xUnit Test Framework';
    externals.xunit.url=['http://www.mathworks.it/matlabcentral/'...
                    'fileexchange/22846-matlab-xunit-test-framework'];
    externals.xunit.authors={'S. Eddins'};

    externals.matlab.is_present=@() cosmo_wtf('is_matlab');
    externals.matlab.is_recent=yes;
    externals.matlab.label=@() sprintf('Matlab %s',cosmo_wtf('version'));
    externals.matlab.url='http://www.mathworks.com';
    externals.matlab.authors={'The Mathworks, Natick, MA, United States'};

    externals.octave.is_present=@() cosmo_wtf('is_octave');
    externals.octave.is_recent=yes;
    externals.octave.label=@() sprintf('GNU Octave %s',...
                                    cosmo_wtf('version'));
    externals.octave.url='http://www.gnu.org/software/octave/';
    externals.octave.authors={'Octave community'};

    externals.matlabsvm.is_present=@() (has_toolbox('stats') || ...
                                            has_toolbox('bioinfo')) && ...
                                        has('svmpredict') && ...
                                        has('svmclassify');
    externals.matlabsvm.is_recent=yes;
    externals.matlabsvm.conflicts.libsvm=@() ~isequal(...
                                                path_of('svmtrain'),...
                                                path_of('svmclassify'));
    externals.matlabsvm.label='matlab stats or bioinfo toolbox';
    externals.matlabsvm.url='http://www.mathworks.com';

    externals.svm={'libsvm', 'matlabsvm'}; % need either



function c=add_to_cell(c, v)
    if ~cosmo_match({v},c)
        c{end+1}=v;
    end


function citation_str=get_citation_str(cached_present_names)
    % always cite CoSMoMVPA
    present_names=cached_present_names;

    present_names=add_to_cell(present_names,'cosmo');
    if cosmo_wtf('is_matlab')
        present_names=add_to_cell(present_names,'matlab');
    end

    if cosmo_wtf('is_octave')
        present_names=add_to_cell(present_names,'octave');
    end

    externals=get_externals();

    n=numel(present_names);
    cites=cell(n,1);
    cites_msk=false(n,1);

    for k=1:n
        external_name=present_names{k};
        if ~isfield(externals,external_name)
            % built-in
            continue;
        end

        external=externals.(external_name);

        if ~isfield(external,'authors')
            continue;
        end

        if isfield(external,'ref')
            % reference provided, use label to prefix URL
            title_str=external.ref;
            url_prefix_str=sprintf('%s ', external.label);
        else
            % no reference, use label as title and no prefix for URL
            title_str=external.label();
            url_prefix_str='';
        end

        cites{k}=sprintf('%s, %s. %savailable online from %s',...
                             cosmo_strjoin(external.authors,', '),...
                             title_str, url_prefix_str, external.url);
        cites_msk(k)=true;

    end

    citation_str=cosmo_strjoin(cites(cites_msk),'\n\n');
