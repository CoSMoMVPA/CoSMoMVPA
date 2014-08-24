function path_changed=cosmo_path_changed(set_stack_counter_)
% helper function to detect changes in the matlab path
%
% path_changed=cosmo_path_changed(set_stack_counter_)
%
% Inputs:
%   set_stack_counter_     Optional argument that changes the internal
%                          state of this function. Can be on of:
%                          'on':     enables checking for changes
%                          'off':    disables checking for changes
%                          'push':   disables checking for changes
%                          'pop':    when called after 'push', resets the x
%                                    for changes before the last 'push'
%                          'update': force check for changes in the path
%                          'not_here': like 'push', but returns a function
%                                      handle that does a pop
%
% Output:
%   path_changed           Boolean (true or false) indicating whether the
%                          path has changed since the last call. If the
%                          input is 'not_here' a function handle is
%                          returned that does a pop
%
% Notes:
%   - the rationale for this function is that it takes time to check for
%     changes in the matlab path. Code can be optimized in functions where
%     the path will not change.
%   - in a function where the path will not change, one can add a line
%        on_cleanup_=onCleanup(cosmo_path_changed('not_here'));
%     which will do a 'push' immediately and ensures a 'pop' is done when
%     leaving the function
%
% NNO Aug 2014

    persistent cached_names_
    persistent cached_paths_    % path from last call
    persistent stack_counter_  % #push minus #pop
    persistent func_me_        % handle to this function

    if isempty(stack_counter_)
        stack_counter_=0;
    end

    force_update=false;

    if nargin>=1
        switch set_stack_counter_
            case 'push'
                stack_counter_=stack_counter_+1;
            case 'pop'
                if stack_counter_<=0
                    error('More pops than pushes');
                end
                stack_counter_=stack_counter_-1;
            case 'off'
                stack_counter_=1;
            case 'on'
                stack_counter_=0;
            case 'update'
                force_update=true;
            case 'not_here'
                stack_counter_=stack_counter_+1;

                if isempty(func_me_)
                    func_me_=str2func(mfilename());
                end

                path_changed=@()func_me_('pop');
                return
            otherwise
                error('illegal state %s', set_stack_counter);
        end
    end

    if stack_counter_>0 && ~force_update
        path_changed=false;
        return
    end

    if isnumeric(cached_names_)
        cached_names_=cell(0);
        cached_paths_=cell(0);
    end

    stack=dbstack();
    n=numel(stack);

    if n==1
        name='!'; % call from workspace
    else
        assert(n>1);
        name=stack(2).name;
    end

    m=cosmo_match({name}, cached_names_);


    if any(m)
        i=find(m);
        assert(numel(i)==1);
        cached_path=cached_paths_{i};

        p=path();
        n=numel(p);
        path_changed=n~=numel(cached_path)||~strncmp(p,cached_path,n);
        if path_changed
            cached_paths_{i}=path();
        end
    else
        cached_names_{end+1}=name;
        cached_paths_{end+1}=path();
        path_changed=true;
    end





