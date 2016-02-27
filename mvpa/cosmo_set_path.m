function cosmo_set_path()
% set the matlab path for CoSMoMVPA
%
% cosmo_set_path()
%
% Notes:
%  - if $ROOT is the root directory of CoSMoMVPA, then this function adds
%    the paths $ROOT/{mvpa,external}, and their subdirectories, to the
%    matlab path. It removes $ROOT{doc,examples,tests}.
%  - A warning message is given if an unexpected directory structure is
%    encountered.
%  - To store the path, run savepath after calling this function.
%
% Example:
%   cosmo_set_path();
%   savepath();
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % directories to be added and removed from the path
    remove_subdirs={'doc','examples','tests'};
    add_subdirs={'mvpa','external'};

    remove_add_subdirs={remove_subdirs, add_subdirs};

    % get path of this very function
    me_pth=fileparts(which(mfilename()));

    % get CoSMoMVPA root path
    root_pth=fileparts(me_pth);

    % get matlab path, each path in a cell
    pathsep_=pathsep(); % store path separator
    matlab_pth=cosmo_strsplit(path(),pathsep_);

    for add=[0,1]
        subdirs=remove_add_subdirs{add+1};

        n=numel(subdirs);
        for k=1:n
            subdir=subdirs{k};
            full_pth=fullfile(root_pth,subdir);

            if exist(full_pth,'file') && isdir(full_pth)
                % generate all subdirectories
                all_pths=cosmo_strsplit(genpath(full_pth),pathsep_);

                % see which ones are in the matlab path
                in_matlab_pth=cosmo_match(all_pths,matlab_pth);

                for j=1:numel(all_pths)
                    pth=all_pths{j};
                    if add && ~in_matlab_pth(j)
                        addpath(pth);
                    elseif ~add && in_matlab_pth(j)
                        rmpath(pth);
                    else
                        % do nothing
                    end
                end
            else
                cosmo_warning(['Path ''%s'' not found - this is an '...
                            'unexpected directory structure. ',...
                            'Please check your path settings'],full_pth);
            end

        end
    end



