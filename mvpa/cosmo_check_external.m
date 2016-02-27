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
%                          'moxunit'   MOxUnit unit test framework
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
%   is_ok                  boolean indicating whether the external is
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
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    persistent cached_present_names;

    if isnumeric(cached_present_names)
        cached_present_names=cell(0);
    end

    if nargin<2
        raise_=true;
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
                if nargout==0
                    disp(s);
                    is_ok=[];
                else
                    is_ok=s;
                end

            otherwise
                error('illegal switch %s', external);
        end

        return
    end


    if external(1)=='@'
        toolbox_name=external(2:end);
        is_ok=check_matlab_toolbox(toolbox_name,raise_);
    elseif external(1)=='!'
        command_name=external(2:end);
        is_ok=check_which(command_name,raise_);
        external='';
    else
        is_ok=check_external_toolbox(external,raise_);
    end

    if is_ok && ...
                ~isempty(external) && ...
                ~cosmo_match({external},cached_present_names)
        cached_present_names{end+1}=external;
    end

function is_ok=check_which(command_name,raise_)
    is_ok=exist(command_name,'builtin') || ...
                ~isempty(which(command_name));
    if ~is_ok && raise_
        error('Function ''%s'' is not available', command_name);
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

    if isempty(cosmo_strsplit(external_name,'_bin',-1))
        % binary package
        env='system';
    else
        env=cosmo_wtf('environment');
    end
    error_msg=[];

    % simulate goto statement
    while true
        if ~ext.is_present()
            suffix=ext_get_what_to_do_message(ext,env);
            error_msg=sprintf(['%s is required, but it was not '...
                'found in the %s path. If it is not present on your '...
                'system, obtain it from:\n\n    %s\n\nthen, %s.'], ...
                ext.label(), env, url2str(ext.url), suffix);
            break;
        end

        if ~ext.is_recent()
            suffix=ext_get_what_to_do_message(ext,env);
            error_msg=sprintf(['%s was found on your %s path, but '...
                'seems out of date. Please download the latest '...
                'version from:\n\n %s\n\nthen, %s.'], ...
                ext.label(), env, url2str(ext.url), suffix);
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
                    trouble_maker=externals.(name).label();
                    me=ext.label();

                    error_msg=sprintf(['The %s conflicts with the %s, '...
                                    'making the %s unusable. You may '...
                                    'have to change the %s path so '...
                                    'that the location of the %s comes '...
                                    'below (after) that of the %s.'],...
                                    trouble_maker,me,me,...
                                    env,trouble_maker,me);
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

function msg=ext_get_what_to_do_message(ext,env)
    if isfield(ext, 'what_to_do')
        msg=ext.what_to_do();
    else
        msg=sprintf(['if applicable, add the necessary directories '...
                'to the %s path'], env);
    end

function is_ok=check_matlab_toolbox(toolbox_name,raise_)
    if cosmo_wtf('is_matlab')
        toolbox_dir=fullfile(toolboxdir(''),toolbox_name);
        % directory must exist and be in the path
        is_ok=isdir(toolbox_dir) && toolbox_in_matlab_path(toolbox_dir);
    else
        is_ok=false;
    end
    if ~is_ok && raise_
        error('The matlab toolbox ''%s'' seems absent',...
                            toolbox_name);
    end

function tf=toolbox_in_matlab_path(toolbox_dir)
    persistent cached_toolbox_dir;
    persistent cached_tf;
    persistent cached_path;

    cur_path=path();
    if ~(isequal(cur_path, cached_path) && ...
                isequal(toolbox_dir, cached_toolbox_dir))

        toolbox_dir_esc=toolbox_dir;
        if isequal(filesep,'\')
            toolbox_dir_esc=strrep(toolbox_dir_esc,'\','\\');
        end


        paths=cosmo_strsplit(path(),pathsep());
        starts_with_toolbox_dir=@(x)isempty(...
                                    cosmo_strsplit(x,toolbox_dir_esc,1));
        cached_tf=any(cellfun(starts_with_toolbox_dir,paths));
        cached_path=cur_path;
        cached_toolbox_dir=toolbox_dir;
    end

    tf=cached_tf;

    %paths=cosmo_strsplit(path(),pathsep());
    %starts_with_toolbox_dir=@(x)isempty(cosmo_strsplit(x,toolbox_dir,1));
    %f=any(cellfun(starts_with_toolbox_dir,paths));


function s=url2str(url)
    if strcmp(cosmo_wtf('environment'),'matlab')
        s=sprintf('<a href="%s">%s</a>',url,url);
    else
        s=url;
    end


function w=noerror_which(varargin)
    % Octave raises an expection when 'which' is called and a mex-file of
    % incompatible architecture is found
    w='';
    try
        w=which(varargin{:});
    catch
        % do nothing
    end

function externals=get_externals()
    persistent cached_externals;

    if ~isstruct(cached_externals)
        cached_externals=get_externals_helper();
    end

    externals=cached_externals;


function externals=get_externals_helper()
    % helper function that defines the externals.
    externals=struct();
    yes=@() true;
    has=@(x) ~isempty(noerror_which(x));
    has_toolbox=@(x)check_matlab_toolbox(x,false);
    path_of=@(x) fileparts(noerror_which(x));
    is_in_path=@(x)has(x) && cosmo_match({path_of(x)},...
                    cosmo_strsplit(path(),pathsep()));

    externals.cosmo.is_present=@()is_in_path(mfilename());
    externals.cosmo.is_recent=yes;
    externals.cosmo.label='CoSMoMVPA toolbox';
    externals.cosmo.url='http://cosmomvpa.org';
    externals.cosmo.authors={'N. N. Oosterhof','A. C. Connolly', ...
                                'J. V. Haxby'};
    externals.cosmo.year='in preparation';
    externals.cosmo.ref=['CoSMoMVPA: multi-modal multivariate pattern '...
                            'analysis of neuroimaging data in '...
                            'Matlab / GNU Octave.'];

    externals.afni_bin.is_present=@() isunix() && ...
                          ~unix(['which afni > /dev/null && '...
                                 'which 3dresample > /dev/null && '...
                                    'afni --version >/dev/null']);
    externals.afni_bin.is_recent=yes;
    externals.afni_bin.label='AFNI binaries';
    externals.afni_bin.url='http://afni.nimh.nih.gov/afni';
    externals.afni_bin.authors={'R. W. Cox'};
    externals.afni_bin.ref=['AFNI: Software for analysis and '...
                             'visualization of functional magnetic '...
                             'resonance neuroimages.  Computers and '...
                             'Biomedical Research, 29: 162-173, 1996'];
    externals.afni_bin.what_to_do=['consider the environment you are '...
                                    'running Matlab from. It may '...
                                    'be required to start matlab '...
                                    'from the shell'];


    externals.afni.is_present=@() has('BrikLoad');
    % Octave requires a more recent version of AFNI, whereas there is
    % currently no need for Matlab users to upgrade
    externals.afni.is_recent=@() has('afni_swapbytes');
    externals.afni.label='AFNI Matlab library';
    externals.afni.url='https://github.com/afni/AFNI';
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

    externals.fieldtrip.is_present=@() has('ft_defaults');
    % in the future, may require from 2014 onwards
    %externals.fieldtrip.is_recent=getfield(dir(which('ft_databrowser')),...
    %                                        'datenum')>datenum(2014,1,1);
    externals.fieldtrip.is_recent=yes;
    externals.fieldtrip.label='FieldTrip toolbox';
    externals.fieldtrip.url='http://fieldtrip.fcdonders.nl';
    externals.fieldtrip.authors={'R. Oostenveld','P. Fries','E. Maris',...
                                 'J.-M. Schoffelen'};
    externals.fieldtrip.year='2011';
    externals.fieldtrip.ref=['FieldTrip: Open Source Software for '...
                              'Advanced Analysis of MEG, EEG, and '...
                              'Invasive Electrophysiological Data, '...
                              'Computational Intelligence and '...
                              'Neuroscience, vol. 2011, ',...
                              'Article ID 156869, 9 pages.',...
                              'doi:10.1155/2011/156869'];

    externals.libsvm.is_present=@() has('svmpredict') && ...
                                        has('svmtrain');
    % require version 3.18 or later, because it has a 'quiet' option
    % for svmpredict
    externals.libsvm.is_recent=@() get_libsvm_version()>=318;
    externals.libsvm.label='LIBSVM toolbox';
    externals.libsvm.url='https://github.com/cjlin1/libsvm';
    externals.libsvm.authors={'C.-C. Chang', 'C.-J. Lin'};
    externals.libsvm.year='2011';
    externals.libsvm.ref=['LIBSVM: '...
                            'a library for support vector machines. '...
                            'ACM Transactions on Intelligent Systems '...
                            'and Technology, 2:27:1--27:27, 2011'];
    externals.libsvm.conflicts.neuroelf=@() isequal(...
                                                path_of('svmtrain'),...
                                                fileparts(path_of('xff')));
    externals.libsvm.conflicts.matlabsvm=@() ~isequal(...
                                                path_of('svmpredict'),...
                                                path_of('svmtrain'));

    externals.surfing.is_present=has('surfing_voxelselection');
    % require recent version with surfing_write
    externals.surfing.is_recent=has('surfing_write') && ...
                                    has('surfing_nodeselection') && ...
                                    get_surfing_version() >= .5;
    externals.surfing.label='Surfing toolbox';
    externals.surfing.url='http://github.com/nno/surfing';
    externals.surfing.authors={'N. N. Oosterhof','T. Wiestler',...
                                'J. Diedrichsen'};
    externals.surfing.year='2011';
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
                                        has('svmtrain') && ...
                                        has('svmclassify');
    externals.matlabsvm.is_recent=yes;
    externals.matlabsvm.conflicts.neuroelf=@() isequal(...
                                                path_of('svmtrain'),...
                                                fileparts(path_of('xff')));
    externals.matlabsvm.conflicts.libsvm=@() ~isequal(...
                                                path_of('svmtrain'),...
                                                path_of('svmclassify'));
    externals.matlabsvm.label='Matlab stats or bioinfo toolbox';
    externals.matlabsvm.url='http://www.mathworks.com';

    externals.svm={'libsvm', 'matlabsvm'}; % need either

    externals.distatis.is_present=yes;
    externals.distatis.is_recent=yes;
    externals.distatis.label='DISTATIS CoSMoMVPA implementation';
    externals.distatis.url=externals.cosmo.url;
    externals.distatis.authors={'Abdi, H.','Valentin, D.',...
                                        'O''Toole, A. J.','Edelman, B.'};
    externals.distatis.year='2005';
    externals.distatis.ref=['DISTATIS: The analysis of multiple '...
                             'distance matrices. In Proceedings of the '...
                             'IEEE Computer Society: International '...
                             'conference on computer vision and '...
                             'pattern recognition, San Diego, CA, USA '...
                             '(pp. 42-47)'];

    externals.fast_marching.is_present=@() has(...
                                        'perform_front_propagation_mesh');
    externals.fast_marching.is_recent=yes;
    externals.fast_marching.label=['toolbox fast marching [included '...
                                    'in surfing]'];
    externals.fast_marching.authors={'Gabriel Peyre'};
    externals.fast_marching.ref=['Toolbox Fast Marching - A toolbox '...
                                    'Fast Marching and level '...
                                    'sets computations [https://www.'...
                                    'ceremade.dauphine.fr/'...
                                    '~peyre/matlab/fast-marching/'...
                                    'content.html]'];
    externals.fast_marching.url=externals.surfing.url;

    externals.moxunit.is_present=@() has('moxunit_runtests');
    externals.moxunit.is_recent=yes;
    externals.moxunit.label=['Matlab/Octave MOxUnit '...
                                        'Test Framework'];
    externals.moxunit.authors={'N. N. Oosterhof'};
    externals.moxunit.url='https://github.com/MOxUnit/MOxUnit';
    externals.moxunit.conflicts.xunit=@() same_path({'runtests',...
                                                'initTestSuite'});

    externals.octave_pkg_parallel.is_present=@() has_octave_package(...
                                                    'parallel');
    externals.octave_pkg_parallel.is_recent=yes;
    externals.octave_pkg_parallel.label=['GNU Octave parallel package'];
    externals.octave_pkg_parallel.authors={'Hayato Fujiwara',...
                                            'Jaroslav Hajek, Olaf Till'};
    externals.octave_pkg_parallel.url=['http://http://octave.'...
                                        'sourceforge.net/parallel/'];

    externals.octave_pkg_statistics.is_present=@() has_octave_package(...
                                                    'statistics');
    externals.octave_pkg_statistics.is_recent=yes;
    externals.octave_pkg_statistics.label=['GNU Octave statistics '...
                                                'package'];
    externals.octave_pkg_statistics.authors={'Arno Onken'};
    externals.octave_pkg_statistics.url=['http://http://octave.'...
                                        'sourceforge.net/statistics/'];

    externals.mocov.is_present=@() has('mocov');
    externals.mocov.is_recent=yes;
    externals.mocov.label=['Matlab/Octave MOcov '...
                                        'Coverage report generator'];
    externals.mocov.authors={'N. N. Oosterhof'};
    externals.mocov.url='https://github.com/MOcov/MOcov';

function tf=has_octave_package(label)
    tf=cosmo_wtf('is_octave') && ~isempty(pkg('list',label));

function tf=same_path(args)
    pths=cellfun(@(x)fileparts(which(x)),args,'UniformOutput',false);
    tf=all(cellfun(@(x)isequal(x,pths{1}),pths(2:end)));


function version=get_libsvm_version()
    svm_root=fileparts(fileparts(noerror_which('svmpredict')));
    svm_h_fn=fullfile(svm_root,'svm.h');

    fid=fopen(svm_h_fn);

    if fid<0
        error('Unable to open %s; cannot determine libsvm version',...
                                                            svm_h_fn);
    end

    c=onCleanup(@()fclose(fid));

    chars=fread(fid,Inf,'char=>char');
    lines=cosmo_strsplit(chars','\n');

    for k=1:numel(lines)
        sp=cosmo_strsplit(lines{k},'LIBSVM_VERSION');
        if numel(sp)>1
            version=str2double(sp{end});
            return
        end
    end

    error('Could not find LIBSVM version in %s', svm_h_fn);

function version=get_surfing_version()
    surfing_root=fileparts(fileparts(noerror_which(...
                                    'surfing_voxelselection')));
    surfing_version_fn=fullfile(surfing_root,'VERSION');

    fid=fopen(surfing_version_fn);
    if fid<0
        if ~exist(surfing_version_fn,'file')
            version=0;
            return;
        else
            error('Unable to open %s, cannot determine surfing version',...
                    surfing_version_fn);
        end
    end

    c=onCleanup(@()fclose(fid));

    chars=fread(fid,Inf,'char=>char')';
    v_str=regexp(chars,'version\s+([\d\.]*)','tokens');

    if iscell(v_str)
        v_str=v_str{1};
    end

    version=str2double(v_str);


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

        author_str=cosmo_strjoin(external.authors,', ');
        if isfield(external,'year')
            author_str=sprintf('%s (%s)', author_str, external.year);
        end

        cites{k}=sprintf('%s. %s. %savailable online from %s',...
                             author_str,...
                             title_str, url_prefix_str, external.url);
        cites_msk(k)=true;

    end

    citation_str=cosmo_strjoin(cites(cites_msk),'\n\n');
