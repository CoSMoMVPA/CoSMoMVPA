function test_suite=test_check_partitions()
% tests for cosmo_check_partitions
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_check_partitions_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_check_partitions(varargin{:}),'');
    is_ok=@(varargin)cosmo_check_partitions(varargin{:});
    ds=cosmo_synthetic_dataset();

    % empty input
    p=struct();
    aet(p,ds);
    p.train_indices=[];
    p.test_indices=[];
    aet(p,ds);

    % fold count mismatch
    p.train_indices={[1 2],[1 2]};
    p.test_indices={1};
    aet(p,ds);

    % unbalance in test indices is ok
    p.test_indices={[3 4 5 6],[3 4 6]};
    is_ok(p,ds);

    % error for unbalance in unique targets, unless overridden
    p.train_indices={[1 2],1};
    aet(p,ds);
    aet(p,ds,'unbalanced_partitions_ok',false);
    is_ok(p,ds,'unbalanced_partitions_ok',true);

    % error for unbalance over chunks, unless overridden
    p.train_indices={[1 2],[1 2 3]};
    p.test_indices={[5 6],[5 6]};
    aet(p,ds);
    aet(p,ds,'unbalanced_partitions_ok',false);
    is_ok(p,ds,'unbalanced_partitions_ok',true);

    % indices must be integers not exceeding range
    p.train_indices={[1 2],[4 7]};
    p.test_indices={[3 4 5 6],[3 4 6]};
    aet(p,ds);
    p.train_indices={[1 2],[4.5 5.5]};
    aet(p,ds);

    % empty indices are not allowed
    p.train_indices={[1 2],[]};
    aet(p,ds);


    % no double dipping allowed
    p.train_indices={[1 2],[3 4]};
    aet(p,ds);
    aet(p,ds,'unbalanced_partitions_ok',false);
    aet(p,ds,'unbalanced_partitions_ok',true);

    % second input must be dataset struct
    ds.sa=struct();
    aet(p,ds);
    ds=struct();
    aet(p,ds);

    % it's fine to have missing targets...
    ds=cosmo_synthetic_dataset('ntargets',3);
    p=struct();
    p.train_indices={[2 3 5 6], [5 6 8 9]};
    p.test_indices={[8 9],[1 3]};
    is_ok(p,ds);

    % ...but if so it must be consistent across the folds
    p.train_indices={[1 2 4 5],[5 6 8 9]};
    p.test_indices={[8 9],[1 3]};
    aet(p,ds);


function test_warning_shown_unsorted_indices()
    orig_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(orig_state));

    cosmo_warning('reset');
    cosmo_warning('off');


    ds=cosmo_synthetic_dataset();

    max_chunk=max(ds.sa.chunks);
    sorted_partitions=struct();
    sorted_partitions.train_indices={find(ds.sa.chunks<max_chunk)};
    sorted_partitions.test_indices={find(ds.sa.chunks==max_chunk)};

    fns={'train_indices','test_indices'};
    prev_warning_count=0; % because of reset
    for k=0:2
        switch k
            case 0
                partitions=sorted_partitions;
            otherwise
                partitions=sorted_partitions;
                fn=fns{k};

                reversed_idx=partitions.(fn){1}(end:-1:1);
                partitions.(fn){1}=reversed_idx;
                assertFalse(issorted(reversed_idx))
        end

        cosmo_check_partitions(partitions,ds);

        state=cosmo_warning();
        warning_count=numel(state.shown_warnings);

        should_have_new_warning=k>0;
        if should_have_new_warning
            delta=1;
        else
            delta=0;
        end

        assertEqual(warning_count,prev_warning_count+delta);

        prev_warning_count=warning_count;
    end


















