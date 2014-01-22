function config=cosmo_config(fn, config)
% return a struc with configuration settings, or store such settings
%
% Usages:
% - get the configuation:
%   >> config=cosmo_config();
%
% - read configuration from a file
%   >> config=cosmo_config(fn)
%
% - store configuration in a file
%   >> cosmo_config(fn, to_store)
%
% Inputs:
%   fn          optional filename of a configuration file. 
%               This can either be a path to a file, a filename to a file 
%               in the matlab path, or (on Unix platforms) a filename in 
%               the user's home directory.
%   to_store    optional struct with configuration to store. 
%               If omitted then the configuration is not stored.
%
% Returns:
%   config      Struct with configurations
%
% Notes:
%  - the format for a configuration file is of the form <key>=<value>,
%    where <key> cannot contain the '=' character and <value> cannot start
%    or end with a white-space character.
%
%  - an example configuration file (of two lines):
%
%    # path for runnable examples
%    data_path=/Users/nick/organized/_datasets/CoSMoMVPA
%  
%  - If a configuration file with the name '.cosmomvpa.cfg' is stored 
%    in a directory that is in the matlab path or (on Unix platforms) the 
%    user's home directory, then calling this function with no arguments
%    will read that file and return the configuration stored in it.
%
% NNO Jan 2014


    default_fn='.cosmomvpa.cfg';

    if nargin==1 && ischar(fn)
        fn=find_file(fn);
        config=read_config(fn);
    elseif nargin==0
        % see if the configuration file can be found
        fn=find_file(default_fn);
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

    cosmo_mvpa_dir=fileparts(which('cosmo_corr'));

    % set defaults
    defaults.data_path=fullfile(cosmo_mvpa_dir,'..','data');

    % overwrite defaults by configuration options
    fns=fieldnames(defaults);
    for k=1:numel(fns)
        fn=fns{k};
        if ~isfield(config, fn)
            config.(fn)=defaults.(fn);
        end
    end
    
    validate_config(config);
    

function validate_config(config)
    % simple validation of config
    % XXX for now just the data_path - maybe a bit overkill
    checks.data_path.test=@(p) exist(p,'file');
    checks.data_path.msg=@(p) sprintf('Path "%s" does not exist',p);

    add_msg=sprintf('To set the configuration, run: help %s', mfilename());
    
    fns=fieldnames(config);
    for k=1:numel(fns)
        fn=fns{k};
        if isfield(checks,fn)
            test_func=checks.(fn).test;
            value=config.(fn);
            if ~test_func(value)
                msg_func=checks.(fn).msg;
                error('%s\n%s',msg_func(value),add_msg);
            end
        end
    end
    
    



function fn=find_file(fn, raise_)
% tries to find a configuration file by looking:
% - for the path of the file
% - in the matlab path
% - in the user's home directory (on Unix)
    if nargin<2, raise_=false; end

    exist_=@(fn) exist(fn,'file');

    if ~exist_(fn)
        % is it in the matlab path?
        w_fn=which(fn);
        if ~isempty(w_fn) 
            fn=w_fn;
        elseif isunix()
            % is it in the home directory?
            u_fn=fullfile(getenv('HOME'),fn);
            if exist_(u_fn)
                fn=u_fn;
            else
                if raise_
                    % nothing worked
                    error('Cannot find config file "%s"', fn);
                else
                    fn=[];
                end
            end
        end
    end


function config=read_config(fn)
% reads configuration from a file fn

    config=struct();

    fid=fopen(fn);
    while true
        line=fgetl(fid);
        if ~ischar(line)
            break;
        end

        if isempty(line) || line(1)=='#'
            continue
        end

        m=regexp(line,'(?<key>[^=]+)\s*=\s*(?<value>.*)\s*','names');

        if isempty(m)
            warning('Skipping non-recognized line "%s"', line);
            continue;
        end

        value=m.value;

        % see if it can be converted to numeric
        value_num=str2double(value);
        if ~isnan(value_num)
            value=value_num;
        end 

        config.(m.key)=value;

    end
    fclose(fid);


function write_config(fn, config)
% writes the config to a file fn
    fid=fopen(fn,'w');
    
    fns=fieldnames(config);
    for k=1:numel(fns)
        fn=fns{k};

        v=config.(fn);
        if isnumeric(v)
            v=sprintf('%d ',v);
        elseif ischar(v)
            % no converstion
        else
            warning('Skipping unsupported data type for key "%s"', fn);
        end
        fprintf(fid,'%s=%s\n',fn,v);
    end
    
    fclose(fid); 
