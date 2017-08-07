function test_suite=test_dim_match
% tests for cosmo_dim_match
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_dim_match_basics()
    ds=get_dim_dataset();

    [nsamples,nfeatures]=size(ds.samples);
    ds=cosmo_slice(ds,randperm(nsamples));
    ds=cosmo_slice(ds,randperm(nfeatures),2);

    for dim=1:2
        for subset=1:3
            if subset==3
                sel=[1 2];
            else
                sel=subset;
            end

            verify_with(ds, dim, sel);
        end
    end

function verify_with(ds, dim, sel)
    verify_with_dataset_or_neighborhood(ds,dim,sel);

    nh=ds;

    delete_fields={'f','s'};
    nh=rmfield(nh,[delete_fields{dim} 'a']);
    nh.a=rmfield(nh.a,[delete_fields{dim} 'dim']);

    samples_size=size(ds.samples);
    nh=rmfield(nh,'samples');

    nh.neighbors=cell(samples_size(dim),1);
    nh.origin.a=nh.a;



    verify_with_dataset_or_neighborhood(nh, dim, sel);



function verify_with_dataset_or_neighborhood(ds, dim, sel)
    infixes='sf';
    infix=infixes(dim);

    % get sdim or fdim
    xdim=ds.a.([infix 'dim']);
    labels=xdim.labels;
    values=xdim.values;

    % get fa or sa
    xa=ds.([infix 'a']);

    if isfield(ds,'samples')
        sizes=size(ds.samples);
        nx=sizes(dim);
    else
        nx=numel(ds.neighbors);
    end

    msk=true(nx,1);

    n_sel=numel(sel);
    xdim_labels=cell(n_sel,1);
    xa_values=cell(n_sel,1);
    all_idxs=cell(n_sel,1);
    sel_idxs=cell(n_sel,1);
    sel_fhandles=cell(n_sel,1);



    for k=1:n_sel
        s=sel(k);

        value=values{s};
        label=labels{s};

        xdim_labels{k}=label;

        % select a subset
        nx=numel(value);
        rp=randperm(nx);
        xa_idx=rp(1:ceil(rand()*nx));
        xa_values{k}=value(xa_idx);

        m=cosmo_match(xa.(label),xa_idx);

        all_idxs{k}=xa.(label);
        sel_idxs{k}=xa_idx;
        sel_fhandles{k}=@(x)cosmo_match(x,xa_values{k});

        msk=msk & m(:);
    end

    if dim==2
        msk=reshape(msk,1,[]);
    end

    % labels and values
    args=[xdim_labels(:)';xa_values(:)'];
    dm=cosmo_dim_match(ds,args{:});
    assertEqual(dm,msk);

    dm2=cosmo_dim_match(ds,args{:},dim);
    assertEqual(dm2,msk);

    % labels and function handles
    args=[xdim_labels(:)';sel_fhandles(:)'];
    dm=cosmo_dim_match(ds,args{:});
    assertEqual(dm,msk);

    args=[xdim_labels(:)';sel_fhandles(:)'];
    dm=cosmo_dim_match(ds,args{:},dim);
    assertEqual(dm,msk);




function test_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_dim_match(varargin{:}),'');
    aet({},'i',1);
    ds=struct();
    aet(ds,'i',1);

    % input mismatch
    ds=get_dim_dataset();
    aet(ds,'i','a');
    aet(ds,'targets',2);
    aet(ds,'chunks','2');

    % cannot mask in both dimensions
    aet(ds,'chunks',1,'i',4);

    % size mismatch
    aet(ds,[1 2],1);
    aet(ds,'chunks',1,1:10,2);

    % wrong dimension
    aet(ds,'i',1,1);
    aet(ds,'foo',1);
    aet(ds,'foo',1,2);


    % no vector input
    aet(ds,'i',zeros(2));

    % illegal cell input
    aet(ds,'i',{1});

    % no mixing of dimensions
    ds=cosmo_synthetic_dataset(); % square
    ds.a.sdim.labels={'targets','chunks'};
    ds.a.sdim.values={1:3,4:6};
    assertEqual(size(ds.samples),[6 6])
    aet(ds,'i',1,'targets',1);



function ds=get_dim_dataset()
    % return dataset with values in sample and feature dimensions
    ds=cosmo_synthetic_dataset('size','normal','nchunks',3,'ntargets',4);
    ds.a.sdim.labels={'targets','chunks'};
    ds.a.sdim.values={{'foo','bar','baz','bazz'},4:6};









