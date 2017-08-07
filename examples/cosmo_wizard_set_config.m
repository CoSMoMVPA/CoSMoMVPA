function cosmo_wizard_set_config()
% GUI-based 'wizard' to set CoSMoMVPA configuration file
%
% cosmo_wizard_set_config()
%
% This 'wizard' can be used to set the CoSMoMVPA configuration paths
% for exercises and demonstration outputs (in CoSMoMVPA's 'examples/'
% directory).
%
% It asks to select the directories for the 'tutorial_data_path'
% and 'output_data_path'. The former requires tutorial data, which can be
% downloaded from cosmomvpa.org/download.html
%
% It will store a '.cosmomvpa.cfg' file in either the user's home directory
% (on Linux / OSX), or in any available userpath() directory.
%
% Selecting cancel at any time will close this wizard.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

% simulate go-to
while true
    if isempty(which('cosmo_config'))
        % store original path.
        % (should we ask to user whether the path should be set)
        orig_path=path();
        path_resetter=onCleanup(@()path(orig_path));

        addpath(get_cosmo_mvpa_dir());
        cosmo_set_path();
    end

    % read existing configuration, if it exists
    [config,fn]=get_cosmo_config();

    if isempty(fn)
        % no existing configuration, find location where to store it
        [fn,error_msg]=get_output_filename();

        if ~isempty(error_msg)
            break
        end
    end

    % ask for paths and update configuration
    [config,error_msg]=update_config(config);
    if ~isempty(error_msg)
        break;
    end

    % store configuration
    error_msg=write_config(fn,config);

    if ~isempty(error_msg)
        break;
    end

    % all done without error, quit this function
    return
end

error('%s did not complete, reason: %s',mfilename(),error_msg);


function mvpa_dir=get_cosmo_mvpa_dir()
    cur_dir=fileparts(mfilename('fullpath'));
    mvpa_dir=fullfile(fileparts(cur_dir),'mvpa');


function error_msg=write_config(fn,config)
    config_str=config2str(config);

    title='Confirm writing CoSMoMVPA configuration';
    body=sprintf(['The following CoSMoMVPA configuration\n\n%s\n'...
                    'will be written in this file:\n\n%s\n\nContinue?'],...
                    config_str,fn);

    if show_ok_cancel_dialog(title,body)
        error_msg='';
        cosmo_config(fn,config);
        return;
    end

    error_msg='Writing configuration file was cancelled';

function str=config2str(config)
    rows=cellfun(@(key)sprintf('%s=%s\n',key,config.(key)),...
                        fieldnames(config),...
                        'UniformOutput',false);
    str=sprintf('%s',rows{:});

function response_is_ok=show_ok_cancel_dialog(title,body)
    response=questdlg(body,...
                        title,...
                        'Cancel','OK','OK');

    response_is_ok=strcmp(response,'OK');


function [config,error_msg]=update_config(config)
    % get keys
    path_keys=get_path_keys();
    path_key_fields=fieldnames(path_keys);
    n_paths=numel(path_key_fields);

    start_path='';
    for k=1:n_paths
        key=path_key_fields{k};
        desc=path_keys.(key);

        title=sprintf('Set ''%s''',key);
        body=sprintf(['In the next dialog, select '...
                                'the directory ' desc]);

        if isfield(config,key)
            current_config_path=config.(key);
            if isdir(current_config_path)
                % if it already has a value, use that as starting value
                start_path=current_config_path;
                body=sprintf(['%s\n\nThe current setting '...
                                'for ''%s'' is:\n%s'],...
                                body,key,start_path);
            end
        end


        response_is_ok=show_ok_cancel_dialog(title,body);

        if response_is_ok


            result_dir=uigetdir(start_path,desc);

            if ischar(result_dir)
                start_path=result_dir;
                config.(key)=result_dir;
                continue;
            end
        end

        % no valid response
        error_msg=sprintf(['Selecting directory for key ''%s'' '...
                                'was cancelled'],key);
        return;
    end

    error_msg='';





function path_keys=get_path_keys()
    path_keys=struct();
    path_keys.tutorial_data_path=[...
                        'where CoSMoMVPA tutorial and example'...
                        'data is stored. This data is required '...
                        'for running the exercises and '...
                        'demonstrations that come with '...
                        'CoSMoMVPA (in the examples/ '...
                        'directory)\n'...
                        'If you have not '...
                        'downloaded this data, select ''Cancel'' '...
                        'and see the '...
                        'website for download instructions:\n\n'...
                        '    http://cosmomvpa.org/download.html'...
                        ''];
    path_keys.output_data_path=[...
                        'where output from running the exercises and '...
                        'demonstrations (such as fMRI volumes with '...
                        'searchlight result maps) is be stored. This '...
                        'can be '...
                        'any directory of your liking that you have '...
                        'write permissions to'];


function [path_fn,error_msg]=get_output_filename()
    fn='.cosmomvpa.cfg';
    error_msg='';

    if isunix()
        home_directory=getenv('HOME');
        candidate_paths={home_directory};
    else
        candidate_paths={};
    end

    if ~isempty(which('userpath','builtin'))
        % this does not work on GNU Octave
        candidate_paths{end+1}=userpath();
    end

    % not preferred, but no other options available
    % (typically, GNU Octave on Windows)
    candidate_paths{end+1}=get_cosmo_mvpa_dir();

    sep=pathsep();
    candidates_strjoined=cosmo_strjoin(candidate_paths,sep);
    candidates_paths=cosmo_strsplit(candidates_strjoined,sep);

    n_candidates=numel(candidates_paths);
    for k=1:n_candidates
        p=candidates_paths{k};
        if isempty(p)
            continue;
        end

        path_fn=fullfile(p,fn);
        if can_write(path_fn);
            return
        end
    end

    path_fn=[];
    error_msg=sprintf(['No suitable directory found where %s '...
                'could be written. The following directories were '...
                'tried but failed: ''%s''\n\n'],...
                fn,cosmo_strjoin(candidates_paths,''', '''));



function tf=can_write(fn)
    file_existed=exist(fn,'file');

    % try to open in append mode
    fid=fopen(fn,'a');
    tf=fid>0;

    if ~file_existed
        delete(fn);
    end


function [config,fn]=get_cosmo_config()
    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    [config,fn]=cosmo_config();
