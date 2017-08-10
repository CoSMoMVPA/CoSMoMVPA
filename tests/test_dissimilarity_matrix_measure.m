function test_suite=test_dissimilarity_matrix_measure()
% tests for cosmo_dissimilarity_matrix_measure
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_dissimilarity_matrix_measure_basics()
    nclasses=5;
    ds=struct();
    ds.samples=[1 2 3; 1 2 3; 1 0 1; 1 1 2; 1 1 2];
    ds.sa.targets=10+(1:nclasses)';
    %
    % compute dissimilarity
    dsm_ds=cosmo_dissimilarity_matrix_measure(ds);
    assertEqual(dsm_ds.a.sdim.labels,{'targets1','targets2'});
    assertEqual(dsm_ds.a.sdim.values,{ds.sa.targets,ds.sa.targets});

    [i,j]=find(tril(ones(nclasses),-1));
    assertEqual(dsm_ds.sa.targets1,i);
    assertEqual(dsm_ds.sa.targets2,j);

    dsm=cosmo_unflatten(dsm_ds,1,'set_missing_to',NaN);

    pd=cosmo_pdist(ds.samples,'correlation');
    pd_sq=cosmo_squareform(pd);

    n=size(pd_sq,1);

    for k=1:n
        for j=1:n
            if k<=j
                expected_value=NaN;
            else
                expected_value=pd_sq(k,j);
            end
            assertEqual(expected_value, dsm(k,j));
        end
    end


function test_dissimilarity_matrix_measure_centered_data()
    nsamples=ceil(rand()*10+5);
    for center_data=[false,true]
        ds=struct();
        ds.samples=randn(nsamples,5);
        ds.sa.targets=(1:size(ds.samples,1))';

        samples=ds.samples;

        opt=struct();
        if center_data
            opt.center_data=true;
            samples=bsxfun(@minus,samples,mean(samples,1));
        end

        res=cosmo_dissimilarity_matrix_measure(ds,opt);

        pd=cosmo_pdist(samples,'correlation');
        counter=0;
        for k=1:(nsamples-1)
            for j=(k+1):nsamples
                row=res.sa.targets2==k & res.sa.targets1==j;
                assert(sum(row)==1);
                counter=counter+1;
                assertElementsAlmostEqual(res.samples(row,:),pd(counter));
            end
        end
        assert(counter==numel(pd));
    end



function test_dissimilarity_matrix_measure_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_dissimilarity_matrix_measure(varargin{:}),'');

    % needs samples and targets
    ds=struct();
    ds.samples=zeros(3,4);
    aet(ds);
    ds.sa.chunks=[1;2;3];
    aet(ds);

    ds=struct();
    ds.sa.targets=[1;2;3];
    aet(ds);

    ds=cosmo_synthetic_dataset('nchunks',2,'ntargets',3);
	aet(ds);





