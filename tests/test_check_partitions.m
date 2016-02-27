function test_suite=test_check_partitions()
% tests for cosmo_check_partitions
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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






