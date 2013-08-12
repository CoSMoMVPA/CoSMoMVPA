.. solution_3

For-loop for nearest-neighbor classifier using Euclidean distance
=================================================================
.. code-block:: matlab

    for k=1:ntest
        delta=bsxfun(@minus, samples_train, samples_test(k,:));
        dst=sqrt(sum(delta.^2,2));
        if numel(dst)~=ntrain, error('wrng'); end
        [m, i]=min(dst);
        predicted(k)=targets_train(i);
    end

