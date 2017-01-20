function nproc_available=cosmo_parallel_get_nproc_available(varargin)
% get number of processes available from Matlab parallel processing pool
%
% nproc=cosmo_parallel_get_nproc_available()
%
% Input:
%   'nproc',nproc_wanted            Number of desired processes
%                                   If not provided, then the number of
%                                   available cores is returned.
%
% Output:
%   nproc_available                 Number of available parallel processes.
%                                   - On Matlab: this requires the parallel
%                                     computing toolbox
%                                   - On Octave: this requires the parallel
%                                     toolbox
%                                   If the required toolbox is not
%                                   available, then nproc_available=1.
%                                   If there are nproc_available processes
%                                   available and
%                                     nproc_available<nproc_wanted
%                                   then nproc=nproc_available.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    defaults=struct();
    opt=cosmo_structjoin(defaults,varargin{:});
    check_inputs(opt);

    max_nproc_available_query_func=get_max_nproc_available_func();
    [max_nproc_available,msg]=max_nproc_available_query_func();

    if ~isfield(opt,'nproc')
        nproc_available=max_nproc_available;
        return;
    end

    nproc_wanted=opt.nproc;
    nproc_available=max_nproc_available;

    if nproc_wanted>max_nproc_available
        full_msg=sprintf(['''nproc''=%d requested, but %s. '...
                            'Using ''nproc''=%d'],...
                            nproc_wanted,msg,nproc_available);
        warning(full_msg);
    end




function func=get_max_nproc_available_func()
    if cosmo_wtf('is_matlab')
        func=@matlab_get_max_nproc_available;
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


function [nproc_available,msg]=matlab_get_max_nproc_available
    msg='';
    nproc_available=1;

    matlab_parallel_functions={'gcp','parpool'};
    if ~(usejava('jvm') && ...
                platform_has_functions(matlab_parallel_functions))
        msg='java or parallel functions not available';
        return;
    end

    pool = gcp();

    if isempty(pool)
        msg=['Parallel toolbox is available, but '...
                        'unable to open pool'];
        return;
    end

    nproc_available=pool.NumWorkers();


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
