function test_suite = test_fx
% tests for cosmo_fx
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_fx_basics()
    % dataset with rows shuffled
    ds=cosmo_synthetic_dataset('nchunks',3,'ntargets',5);
    n_samples=size(ds.samples,1);

    fs={@(x)x, @abs, @(x)min(x,1), @(x)x(1:min(size(x,1),2),:)};
    split_by={{},{'chunks'},{'targets'},{'chunks','targets'}};

    n_fs=numel(fs);
    n_split_by=numel(split_by);

    for k=1:n_fs
        for j=1:n_split_by
            % shuffle rows
            rp=randperm(n_samples);
            ds_rp=cosmo_slice(ds,rp);

            helper_assert_fx_matches(ds_rp,fs{k},split_by{j});
        end
    end

function helper_assert_fx_matches(ds,f,split_by)
    res=cosmo_fx(ds,f,split_by);

    n_split_by=numel(split_by);
    if n_split_by==0
        idxs={1:size(ds.samples,1)};
    else
        unq_vals=cell(n_split_by,1);
        for k=1:n_split_by
            key=split_by{k};
            unq_vals{k}=ds.sa.(key);
        end

        idxs=cosmo_index_unique(unq_vals);
    end

    n_unq=numel(idxs);
    pos=0;

    for k=1:n_unq
        d=cosmo_slice(ds,idxs{k});
        s=f(d.samples);
        n_s=size(s,1);

        expected_res_part=cosmo_slice(d,ones(n_s,1));
        expected_res_part.samples=s;

        res_part=cosmo_slice(res,pos+(1:n_s));

        % do not care about .sa; but rest should match
        assertEqual(expected_res_part.samples,res_part.samples);
        assertEqual(expected_res_part.fa,res_part.fa);
        assertEqual(expected_res_part.a,res_part.a);

        pos=pos+n_s;
    end

function test_fx_unequal_output_size_other_dim
    ds=cosmo_synthetic_dataset('nchunks',3,'ntargets',5);
    ds.sa.targets(1)=2;

    f=@(x)ones(1,size(x,1));
    assertExceptionThrown(@()cosmo_fx(ds,f,{'targets'}),'');

function test_fx_feature_dim
    ds=cosmo_synthetic_dataset();
    fs={@(x)max(x,[],2),@(x)sum(x,2)};

    labels={'i','j','k'};

    for k=1:numel(fs)
        f=fs{k};
        for j=1:numel(labels)
            label=labels{j};
            res=cosmo_fx(ds,f,{label},2);
            assertEqual(res.sa,ds.sa);
            assertEqual(res.a,ds.a);

            % check samples
            fa_values=ds.fa.(label);
            unq_fa=unique(fa_values);

            for m=1:numel(unq_fa)
                s=ds.samples(:,fa_values==unq_fa(m));
                f_s=f(s);
                assertEqual(f_s,res.samples(:,m));
            end
        end
    end


function test_fx_illegal_input_arguments
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_fx(varargin{:}),'');

    ds=cosmo_synthetic_dataset();
    aet(struct,@abs,{});
    aet(ds,[],{});
    aet(ds,@abs,{'i'});
    aet(ds,@abs,{'targets'},2);





