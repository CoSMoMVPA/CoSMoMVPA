function nproc_available=cosmo_parallel_get_nproc_available(varargin)
% get number of processes available from Matlab parallel processing pool
%
% nproc=cosmo_parallel_get_nproc_available()
%
% Input:
%   'nproc',nproc_wanted            Number of desired processes (optional)
%                                   If not provided, then the number of
%                                   available cores is returned.
%                                   Use 'nproc',inf to get as many
%                                   cores as there available.
%   'nproc_available_query_func',f  Function handle to determine how many
%                                   processes are available. This function
%                                   is intended for use by developers only;
%                                   by default it selects the appropriate
%                                   function based on the platform (Octave,
%                                   Matlab <= 2013b, or Matlab > 2013b)
%
% Output:
%   nproc_available                 Number of available parallel processes.
%                                   - On Matlab: this requires the parallel
%                                     computing toolbox
%                                   - On Octave: this requires the parallel
%                                     toolbox
%                                   If the required toolbox is not
%                                   available, then nproc_available=1.
%                                   If there are nproc_available
%                                   processes available and
%                                       nproc_available<nproc_wanted
%                                   then nproc=nproc_available is returned.
%
% Notes:
%   - If no parallel processing pool has been started, then this function
%     will try to start one (with as many parallel processes as possible)
%     before counting the number of processes available.
%   - If a parallel processing pool has already been started, then this
%     function returns the number of processes available it that pool. This
%     function *does not* close an existing pool and open a new one. This
%     means that if a user has started a pool with M processes on a machine
%     with N processes available (i.e. a pool has started with fewer
%     processes than available), then this function will return M (and not
%     N if M<N). If you need a fresh pool with
%
% See also: parcellfun, matlabpool
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    defaults=struct();
    opt=cosmo_structjoin(defaults,varargin{:});
    check_inputs(opt);

    [has_nproc_wanted,nproc_wanted]=get_nproc_wanted(opt);
    if has_nproc_wanted && nproc_wanted<=1
        nproc_available=1;
        return;
    end

    max_nproc_available_query_func=get_max_nproc_available_func(opt);
    [max_nproc_available,msg]=max_nproc_available_query_func();

    if ~has_nproc_wanted
        nproc_available=max_nproc_available;
        return;
    end

    % getting here it means opt.nproc>1, i.e. the user asked for more than
    %
    nproc_wanted=opt.nproc;
    nproc_available=max_nproc_available;

    if nproc_wanted>max_nproc_available
        full_msg=sprintf(['''nproc''=%d requested, but %s. '...
                            'Using ''nproc''=%d'],...
                            nproc_wanted,msg,nproc_available);

        if ~isinf(nproc_wanted)
            % do not show warning if nproc_wanted is infinity
            cosmo_warning(full_msg);
        end
    end

    if nproc_wanted<nproc_available
        nproc_available=nproc_wanted;
    end


function [has_nproc_wanted,nproc_wanted]=get_nproc_wanted(opt)
    nproc_wanted=NaN;

    has_nproc_wanted=isfield(opt,'nproc');
    if has_nproc_wanted
        nproc_wanted=opt.nproc;
    end



function func=get_max_nproc_available_func(opt)
    override_key='nproc_available_query_func';
    if isfield(opt,override_key)
        func=opt.(override_key);
        return;
    end

    if cosmo_wtf('is_matlab')
        v_num=cosmo_wtf('version_number');
        % Matlab 2013b is version 8.2
        is_matlab_ge_2013b=v_num(1)>=8 && v_num(2)>=2;

        if is_matlab_ge_2013b
            func=@matlab_get_max_nproc_available_ge2013b;
        else
            func=@matlab_get_max_nproc_available_lt2013b;
        end
    elseif cosmo_wtf('is_octave')
        func=@octave_get_max_nproc_available;
    else
        assert(false,'this should not happen');
    end


function check_inputs(opt)
    if isfield(opt,'nproc')
        nproc=opt.nproc;
        if ~(isnumeric(nproc) && ...
                    isscalar(nproc) && ...
                    nproc>=1 && ...
                    round(nproc)==nproc)
            error('nproc must be a positive scalar');
        end
    end


function [nproc_available,msg]=matlab_get_max_nproc_available_lt2013b()
    nproc_available=1;
    msg=check_java_and_funcs({'matlabpool'});

    if ~isempty(msg)
        return;
    end

    pool_func=@matlabpool;
    open_pool_func=pool_func;
    query_pool_func=@()pool_func('size');

    % get number of processes
    try
        nproc_available=query_pool_func();
        pool_is_open=nproc_available>0;

        if ~pool_is_open
            % try to open pool
            open_pool_func();
            nproc_available=query_pool_func();
        end
    catch
        msg=lasterr();
        return
    end

    % ensure nproc_available>=1
    nproc_available=max(nproc_available,1);



function [nproc_available,msg]=matlab_get_max_nproc_available_ge2013b()
    msg='';
    nproc_available=1;

    matlab_parallel_functions={'gcp','parpool'};
    if ~(usejava('jvm') && ...
                platform_has_functions(matlab_parallel_functions))
        msg='java or parallel functions not available';
        return;
    end

    try
        pool = gcp();

        if isempty(pool)
            msg=['Parallel toolbox is available, but '...
                            'unable to open pool'];
            return;
        end
     catch
         msg=lasterr();
         return
     end

    nproc_available=pool.NumWorkers();


function msg=check_java_and_funcs(function_names)
    msg='';
    if ~(usejava('jvm') && ...
                platform_has_functions(function_names))
        msg='java or parallel functions not available';
        return;
    end


function [nproc_available,msg]=octave_get_max_nproc_available
    msg='';
    nproc_available=1;

    if ~cosmo_check_external('octave_pkg_parallel',false)
        msg='parallel toolbox is not available';
        return;
    end

    nproc_available=nproc('overridable');


function tf=platform_has_functions(function_names)
    tf=all(cellfun(@(x)~isempty(which(x)),function_names));
