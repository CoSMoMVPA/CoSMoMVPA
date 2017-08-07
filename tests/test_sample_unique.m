function test_suite = test_sample_unique
% tests for cosmo_sample_unique
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_sample_unique_basics
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_sample_unique(varargin{:}),'');

    for k=from_range_randomly(10,5)
        for n=from_range_randomly(10,5);
            for count=[0,from_range_randomly(100,10)];
                if count==0
                    args={k,n};
                    ncol=1;
                else
                    args={k,n,count};
                    ncol=count;
                end

                if k>n
                    % n too large; should throw error
                    aet(args{:});
                    continue;
                else
                    i=cosmo_sample_unique(args{:});
                    assertEqual(sort(i,1),i);

                    % check size
                    assert(isequal(size(i),[k,ncol]))

                    % check contents
                    i_vec=i(:);
                    assert(all(i_vec>=1 | i_vec<=n | round(i_vec)==i_vec));

                    % each element must be select about equally often,
                    % and each column must have unique elements
                    i_s=sort(i,1);

                    % each element unique
                    assert(all(all(diff(i_s,1,1)>0)));

                    % check counts
                    counts=zeros(n,1);
                    for col=1:ncol
                        counts(i(:,col))=counts(i(:,col))+1;
                    end

                    % counts differ at most by one
                    assert(min(counts)+1>=max(counts));
                end
            end
        end
    end

function test_sample_unique_full_randperm()
    k=2+from_range_randomly(10);
    n=k;
    c=5+from_range_randomly(10);

    i=cosmo_sample_unique(k,n,c);
    assertEqual(sort(i,1),repmat((1:k)',1,c));

function test_sample_unique_difference_sequences()
    k=2+from_range_randomly(10);
    n=k+from_range_randomly(10);
    c=5+from_range_randomly(10);

    seed=1+from_range_randomly(1e5);
    last_args={{'seed',seed},{'seed',[]'},{}};
    for k=1:numel(last_args)
        all_same=true;

        last_arg=last_args{k};
        use_seed=numel(last_arg)==2 && ~isempty(last_arg{2});

        for tries=1:5
            i=cosmo_sample_unique(k,n,c,last_arg{:});
            if tries==1
                i_first=i;
            elseif ~isequal(i_first,i)
                all_same=false;
                break;
            end
        end

        if xor(all_same,use_seed)
            assertFalse(true,'randomness mismatch with respect to seed');
        end
    end


function test_sample_unique_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_sample_unique(varargin{:}),'');

    bad_args={-1, 1.5, [1 1], struct(), false};
    for k=1:numel(bad_args)
        bad_arg=bad_args{k};

        for j=1:3
            all_args={1,1,1};
            all_args{j}=bad_arg;
            aet(all_args{:});
        end
    end




function vs=from_range_randomly(n, count)
    if nargin<=2
        count=1;
    end

    assert(n>=count);
    vals=1:n;

    rp=randperm(n);
    vs=vals(rp(1:count));




