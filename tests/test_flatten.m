function test_suite=test_flatten()
% tests for cosmo_flatten
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_flatten_and_unflatten()
    combis=cosmo_cartprod({1:2,0:2,1:2});
    for k=1:size(combis,1)
        args=num2cell(combis(k,:));
        run_helper_test_flatten(args{:});
    end

function run_helper_test_flatten(nsamples, nfdim, dim)
    aet_fl=@(varargin) assertExceptionThrown(@()...
                                cosmo_flatten(varargin{:}),'');
    aet_unfl=@(varargin) assertExceptionThrown(@()...
                                cosmo_unflatten(varargin{:}),'');

    ndata=nsamples*30;
    orig_labels={'i','j','k'};
    orig_values={[1:2;3 4],[1:3;3:-1:1],{'a','b','c','d','e'}};

    use_vector_values=nfdim<=1;
    transpose_vectors=nfdim==0;

    if use_vector_values
        % select first row only
        orig_values=cellfun(@(x)x(1,:),orig_values,...
                                        'UniformOutput',false);
    end

    transpose_count=transpose_vectors+0;

    switch dim
        case 1
            data_shape=[2 3 5 nsamples];

            transpose_count=transpose_count+1;
            a_dim='sa';
            attr_dim='sdim';

        case 2
            data_shape=[nsamples 2 3 5];

            a_dim='fa';
            attr_dim='fdim';

    end

    if use_vector_values && transpose_vectors
        opt=struct();
        wrong_opt=struct();
        wrong_opt.matrix_labels={'i','j'};
    elseif use_vector_values
        opt=struct();
        wrong_opt='this will raise an error because it is not a struct';
    else
        opt=struct();
        opt.matrix_labels={'i','j'};
        wrong_opt=struct();
    end

    if mod(dim,2)==1
        tr=@transpose;
    else
        tr=@(x)x;
    end

    if mod(transpose_count,2)==1
        tr_values=@transpose;
    else
        tr_values=@(x)x;
    end

    orig_values_tr=cellfun(tr_values,orig_values,'UniformOutput',false);

    data=reshape(1:ndata,data_shape);

    ds=cosmo_flatten(data,orig_labels,orig_values_tr,dim,opt);
    aet_fl(data,orig_labels,orig_values_tr,dim,wrong_opt);

    assertEqual(ds.samples(:),(1:ndata)');
    assertEqual(ds.(a_dim).i,tr(repmat([1 2],1,15)));
    assertEqual(ds.(a_dim).j,tr(repmat([1 1 2 2 3 3],1,5)));
    assertEqual(ds.(a_dim).k,tr(kron(1:5,ones(1,6))));
    aet_fl(data,orig_labels,cellfun(@(x)x(1:2),orig_values,...
                                'UniformOutput',false));

    expected_values=cellfun(tr,orig_values,'UniformOutput',false);
    expected_labels=cellfun(tr,orig_labels,'UniformOutput',false);

    assertEqual(ds.a.(attr_dim).values,expected_values);
    assertEqual(ds.a.(attr_dim).labels,expected_labels);

    % test unflatten
    if transpose_vectors
        ds.a.(attr_dim).values=cellfun(@transpose,...
                                    ds.a.(attr_dim).values,...
                                    'UniformOutput',false);
    end

    [data2,labels,values]=cosmo_unflatten(ds,dim,opt);
    aet_unfl(ds,dim,wrong_opt);

    assertEqual(data,data2);
    assertEqual(labels,expected_labels);
    assertEqual(values,expected_values);
    aet_unfl(ds,3-dim);



    % test exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_unflatten(varargin{:}),'');
    ds2=cosmo_stack({ds,ds},dim);
    aet(ds2,dim);

    ds_bad=ds;
    ds_bad.a.(attr_dim).values=ds_bad.a.(attr_dim).values(1:(end-1));
    aet(ds_bad,dim,opt);

    % illegal dim argument
    aet(ds,3);
    aet(ds,[1 1]*dim,opt);

