function test_suite = test_dim_prune()
% tests for cosmo_dim_prune
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_dim_prune_fmri()
    helper_test_dim_prune();


function test_dim_prune_meeg_timelock()
    helper_test_dim_prune('type','timelock');

function test_dim_prune_meeg_source_mom()
    helper_test_dim_prune('type','source','data_field','mom');

function test_dim_prune_meeg_source_pow()
    helper_test_dim_prune('type','source','data_field','pow');

function test_dim_prune_surface()
    helper_test_dim_prune('type','surface');

function test_dim_prune_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_dim_prune(varargin{:}),'');
    aet(struct);
    ds=cosmo_synthetic_dataset();
    aet(ds,3);
    aet(ds,'matrix_labels','pos');
    aet(ds,'dim',3);
    aet(ds,'labels',struct);

function test_dim_prune_default_dim()
    ds=cosmo_synthetic_dataset();
    for dim=1:2
        ds_pruned=cosmo_dim_prune(ds);
        ds_pruned2=cosmo_dim_prune(ds,'dim',dim);
        assertEqual(ds_pruned,ds_pruned2);
    end

function test_dim_prune_pos_sample_dim()
    ds=cosmo_synthetic_dataset('type','source','data_field','mom');
    sdim=struct();
    sdim.labels=ds.a.fdim.labels(1);
    sdim.values=ds.a.fdim.values(1)';
    pos=ds.fa.pos;

    ds_tr=cosmo_dim_remove(ds,'pos');

    ds_tr.a.sdim=sdim;
    nsamples=size(ds.samples,1);
    ds_tr.sa.pos=pos(1:nsamples)';

    ds_tr.sa.pos(ds_tr.sa.pos==1)=2;

    assertExceptionThrown(@()cosmo_dim_prune(ds_tr),'');
    assertExceptionThrown(@()cosmo_dim_prune(ds_tr,'labels',{'pos'}),'');
    ds_tr2=cosmo_dim_prune(ds_tr,'labels',{'time'});
    assertEqual(ds_tr2,ds_tr);


function test_dim_prune_label()
    ds=cosmo_synthetic_dataset();
    ds.fa.i(ds.fa.i==2)=1;

    labels={'i','j','k'};

    ds_pruned=cosmo_dim_prune(ds);
    for k=1:numel(labels)
        label=labels{k};
        ds_pruned=cosmo_dim_prune(ds,'labels',labels(k));
        if strcmp(label,'i')
            assertFalse(isequal(ds_pruned,ds));
        else
            assertEqual(ds_pruned,ds);
        end
    end


function helper_test_dim_prune(varargin)
    ds=cosmo_synthetic_dataset(varargin{:});

    has_pos=cosmo_match({'pos'},ds.a.fdim.labels);
    get_helper_handle=@(dim_arg,varargin)...
                @()...
                helper_test_dim_prune_dim(ds,dim_arg,varargin{:});

    dim_args={[],1,2,[1 2]};
    for k=1:numel(dim_args)
        dim_arg=dim_args{k};

        if has_pos && numel(dim_arg)>0 && any(dim_arg==2);
            assertExceptionThrown(get_helper_handle(...
                                    dim_arg),'');
            assertExceptionThrown(get_helper_handle(...
                                    dim_arg,...
                                    'matrix_labels',{'foo'}),'');
            helper_handle=get_helper_handle(...
                                    dim_arg,...
                                    'matrix_labels',{'pos'});
        else
            helper_handle=get_helper_handle(dim_arg);
        end
        helper_handle();
    end



function ds_pruned=helper_test_dim_prune_dim(ds_orig,prune_dim,varargin)

    dim=2;

    infixes='sf';
    infix=infixes(dim);

    dim_labels=ds_orig.a.([infix 'dim']).labels;

    % choose single dimension to prune, which must not be singleton
    n_dim=numel(dim_labels);

    for dim_to_prune=1:n_dim
        ds=ds_orig;
        % find attribute values in dimension to prune
        attr=ds.([infix 'a']).(dim_labels{dim_to_prune});
        unq=unique(attr);
        n=numel(unq);
        if n==1
            continue;
        end


        % set single value in dimension to 1, removing the presence
        % of remove_idx
        remove_idx=1+ceil(rand()*(n-1));
        orig_attr=attr;
        attr(attr==remove_idx)=1;
        ds.([infix 'a']).(dim_labels{dim_to_prune})=attr;


        ds_pruned=cosmo_dim_prune(ds,'dim',prune_dim,varargin{:});
        if all(prune_dim~=2)
            % nothing should have been pruned
            assertEqual(ds_pruned,ds);
        else
            assertEqual(ds.samples,ds_pruned.samples);
            for k=1:n_dim
                dim_value=ds.a.([infix 'dim']).values{k};

                if k==dim_to_prune
                    keep_indices=setdiff(1:n,remove_idx);
                    wanted_dim_pruned=dim_value(:,keep_indices);
                    % set expected .sa or .fa

                    wanted_attr_pruned=orig_attr;

                    equal_msk=orig_attr==remove_idx;
                    wanted_attr_pruned(equal_msk)=1;

                    after_msk=wanted_attr_pruned>remove_idx;
                    wanted_attr_pruned(after_msk)=wanted_attr_pruned(...
                                                            after_msk)-1;
                else
                    wanted_dim_pruned=dim_value;
                    wanted_attr_pruned=ds.([infix 'a']).(dim_labels{k});
                end

                dim_pruned=ds_pruned.a.([infix 'dim']).values{k};
                attr_pruned=ds_pruned.([infix 'a']).(dim_labels{k});

                assertEqual(dim_pruned,wanted_dim_pruned);
                assertEqual(attr_pruned,wanted_attr_pruned);

            end
        end
    end









