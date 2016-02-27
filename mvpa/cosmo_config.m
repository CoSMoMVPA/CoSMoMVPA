function [config,fn]=cosmo_config(fn, config)
% return a struc with configuration settings, or store such settings
%
% Usages:
% - get the configuation (either default, or what is in '.cosmomvpa.cfg'):
%   >> config=cosmo_config();
%
% - read configuration from a specified file
%   >> config=cosmo_config(fn)
%
% - store configuration in a file
%   >> cosmo_config(fn, to_store)
%
% - related function (in CoSMoMVPA's 'examples/' directory):
%   >> cosmo_wizard_set_config
%
% Inputs:
%   fn          optional filename of a configuration file.
%               This can either be a path of a file, or (on Unix platforms)
%               a filename in the user's home directory.
%               If fn is omitted, then it defaults to '.cosmomvpa.cfg'
%               and will read the configuration from that file if it
%               exists in one of the aforementioned locations; see the
%               notes below for details.
%   to_store    optional struct with configuration to store.
%               If omitted then the configuration is not stored.
%
% Returns:
%   config      Struct with configurations
%
% Notes:
%  - the rationale for this function is to keep the example code fixed
%    (that is, without any paths hard-coded) and still allow each
%    user to store the example data in a directory of their choice.
%
%  - the format for a configuration file is of the form <key>=<value>,
%    where <key> cannot contain the '=' character and <value> cannot start
%    or end with a white-space character.

%  - if the .cosmomvpa.cfg file is in the same directory as this file
%   (presently, 'mvpa/'), it will be found there as well.
%
%  - an example configuration file (of three lines):
%
% # path for runnable examples
% tutorial_data_path=/Users/nick/organized/_datasets/CoSMoMVPA/tutorial_data
% output_data_path=/Users/nick/organized/_datasets/CoSMoMVPA/tutorial_data
%
%  - If a configuration file with the name '.cosmomvpa.cfg' is stored
%    in a directory that is in the matlab path, the user path, or (on Unix
%    platforms) the user's home directory, then calling this function with
%    no arguments will read that file and return the configuration stored
%    in it.
%
%  - The configuration can also be changed as follows:
%    >> % get default configuration
%    >> % If the following command gives an error, do: config=struct()
%    >> config=cosmo_config();
%    >>
%    >> % update settings
%    >> config.tutorial_data_path='/path/to/some/data';
%    >> config.output_data_path='/where/i/want/output';
%    >>
%    >> % get first directory in user path
%    >> matlab_path=cosmo_strsplit (userpath,':',1);
%    >>
%    >> % set configuration filename
%    >> config_fn=fullfile(matlab_path,'.cosmomvpa.cfg');
%    >> cosmo_config(config_fn, config);
%    >> fprintf('Configuration stored in %s\n', config_fn);
%    >>
%    >> % now check they are the same
%    >> loaded_config=cosmo_config();
%    >> assert(isequal(loaded_config,config));
%
%  - The configuration can be set using cosmo_wizard_set_config in
%    CoSMoMVPA's 'examples/' directory
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    default_config_fn='.cosmomvpa.cfg';

    if nargin==1 && ischar(fn)
        fn=find_config_file(fn);
        config=read_config(fn);
    elseif nargin==0
        % see if the configuration file can be found
        fn=find_config_file(default_config_fn);
        if isempty(fn)
            config=struct();
        else
            config=read_config(fn);
        end
    elseif nargin==2 && ischar(fn) && isstruct(config)
        write_config(fn,config);
    else
        error('Illegal input');
    end

    expected_fields={'tutorial_data_path','output_data_path'};
    missing_fields=setdiff(expected_fields,fieldnames(config));

    if numel(missing_fields)>0
        missing_fields_str=cosmo_strjoin(missing_fields,''', ''');
        cosmo_warning(['Using %s, fields ''%s'' are missing. This makes '...
                    'it more complicated to run CoSMoMVPA''s '...
                    'exercises and examples.\n'...
                    'To set the configuration, consider running\n\n'...
                    '    cosmo_wizard_set_config\n\n'...
                    'in the CoSMoMVPA ''examples/'' directory'],...
                    mfilename(),missing_fields_str);
    end

    validate_config(config);


function validate_config(config)
    % simple validation of config

    % poor-man version of OO
    path_exists=struct();
    path_exists.match=@(x)isempty(cosmo_strsplit(x,'_path',-1));
    path_exists.test=@(p) exist(p,'file');
    path_exists.msg=@(key, p) sprintf('%s: path "%s" not found. ',key,p);

    checks={path_exists};
    add_msg=sprintf('To set the configuration, run: help %s', mfilename());

    % perform checks on fieldnames present in 'checks'.

    fns=fieldnames(config);
    for k=1:numel(fns)
        fn=fns{k};
        for j=1:numel(checks)
            check=checks{j};
            if check.match(fn)
                test_func=check.test;
                value=config.(fn);

                if ~test_func(value)
                    msg_func=check.msg;
                    warning('%s\n%s',msg_func(fn, value),add_msg);
                end
            end
        end
    end


function path_fn=find_config_file(fn, raise_)
% tries to find a configuration file by looking:
% - for the path of the file
% - in the matlab path
% - in the user's home directory (on Unix)
    if nargin<2, raise_=false; end

    exist_=@(fn_) exist(fn_,'file');

    path_fn=[];

    % simulate 'go-to' statement using a while loop with break at the end
    while true
        % does the file exist 'as is'?
        if exist_(fn)
            path_fn=fn;
            break
        end

        % is it in the mvpa directory?
        parent_dir=fileparts(mfilename('fullpath'));
        m_fn=fullfile(parent_dir,fn);
        if exist_(m_fn)
            path_fn=m_fn;
            break;
        end

        % is it in the user path?
        % (not supported on octave)
        if cosmo_wtf('is_matlab')
            upaths=cosmo_strsplit(userpath(),':');
            for k=1:numel(upaths)
                u_fn=fullfile(upaths{k},fn);
                if exist_(u_fn)
                    path_fn=u_fn;
                    break;
                end
            end
            if ~isempty(path_fn)
                break;
            end
        end

        if isunix()
            % is it in the home directory?
            u_fn=fullfile(getenv('HOME'),fn);
            if exist_(u_fn)
                path_fn=u_fn;
                break;
            end
        end

        if raise_
            error('Cannot find config file "%s"', fn);
        end

        break;
    end



function config=read_config(fn)
% reads configuration from a file fn

    config=struct(); % space for output
    if isempty(fn)
        error('Input file not specified - cannot open')
    end

    fid=fopen(fn);
    if fid==-1
        error('Unable to open file %s',fn);
    end

    line_number=0;
    while true
        % read each line
        line=fgetl(fid);
        if ~ischar(line)
            % end of file
            break;
        end

        line_number=line_number+1;

        % ignore empty lines or lines starting with '#'
        if isempty(line) || line(1)=='#'
            continue
        end

        % look for lines of form '<key>=<value>'.
        % white spaces around key or value are ignored.
        m=regexp(line,'(?<key>[^=]+)\s*=\s*(?<value>.*)\s*','names');

        if isempty(m)
            warning('Skipping non-recognized line "%s"', line);
            continue;
        end


        % get key and value
        key=m.key;
        value=m.value;

        verify_no_illegal_char(fn,line_number,[key value])

        % see if it can be converted to numeric
        value_num=str2double(value);
        if ~isnan(value_num)
            value=value_num;
        end

        config.(key)=value;
    end

    fclose(fid);

function verify_no_illegal_char(fn,line_number,s)
    illegal_chars=sprintf('"''');
    matching=bsxfun(@eq,s,illegal_chars(:));
    if any(matching(:));
        error(['File %s, line %d: found illegal character. '...
            'note that quote characters are not allowed '...
            'for keys or values'],fn,line_number)
    end



function write_config(fn, config)
% writes the config to a file fn
% no support for comments or empty lines

    fid=fopen(fn,'w');

    fns=fieldnames(config);
    for k=1:numel(fns)
        fn=fns{k};

        v=config.(fn);
        if isnumeric(v)
            % convert numeric to string
            v=sprintf('%d ',v);
        elseif ischar(v)
            % no converstion
        else
            warning('Skipping unsupported data type for key "%s"', fn);
        end
        fprintf(fid,'%s=%s\n',fn,v);
    end

    fclose(fid);
