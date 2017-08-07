function [winners,classes]=cosmo_winner_indices(pred)
% Given multiple predictions, get indices that were predicted most often.
%
% [winners,classes]=cosmo_winner_indices(pred)
%
% Input:
%   pred              PxQ prediction values for Q features and P
%                     predictions per feature. Values of NaN are ignored,
%                     i.e. can never be a winner.
%
% Output:
%   winners           Px1 indices of classes that occur most often.
%                     winners(k)==w means that no value in
%                     classes(pred(k,:)) occurs more often than classes(w).
%   classes           The sorted list of unique predicted values, across
%                     all non-ignored (non-NaN) values in pred.
%
% Examples:
%     % a single prediction, with the third one missing
%     pred=[4; 4; NaN; 5];
%     [p, c]=cosmo_winner_indices(pred);
%     p'
%     > [1 1 NaN 2]
%     c'
%     > [4, 5]
%
%     % one prediction per fold (e.g. using cosmo_nfold_partitioner)
%     pred=[4 NaN NaN; 6 NaN NaN; NaN 3 NaN; NaN NaN NaN; NaN NaN 3];
%     [p, c]=cosmo_winner_indices(pred);
%     p'
%     > [2, 3, 1, NaN, 1]
%     c'
%     > [3 4 6]
%
%     % given up to three predictions each for eight samples, compute
%     % which predictions occur most often. NaNs are ignored.
%     pred=[4 4 4;4 5 6;6 5 4;5 6 4;4 5 6; NaN NaN NaN; 6 0 0;0 0 NaN];
%     [p, c]=cosmo_winner_indices(pred);
%     p'
%     > [2, 3, 4, 2, 3, NaN, 1, 1]
%     c'
%     > [0, 4, 5, 6]
%
% Notes:
% - The typical use case is combining results from multiple classification
%   predictions, such as in binary support vector machines (SVMs) and
%   cosmo_crossvalidate
% - The current implementation selects a winner pseudo-randomly (but
%   deterministically) and (presumably) unbiased in case of a tie between
%   multiple winners. That is, using the present implementation, repeatedly
%   calling this function with identical input yields identical output,
%   but unbiased with respect to which class is the 'winner' sample-wise.
% - Samples with no predictions are assigned a value of NaN.
%
% See also: cosmo_classify_matlabsvm, cosmo_crossvalidate
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    [nsamples,nfeatures]=size(pred);
    pred_msk=~isnan(pred);

    % allocate space for output
    winners=NaN(nsamples,1);

    if nfeatures==1
        % single prediction, handle seperately
        [classes,unused,pred_idxs]=unique(pred(pred_msk));
        winners(pred_msk)=pred_idxs;
        return
    end

    sample_pred_count=sum(pred_msk,2);
    sample_pred_msk=sample_pred_count>0;
    if max(sample_pred_count)<=1
        % only one prediction per sample; set non-predictions to zero and
        % add them up to get the prediction
        pred(~pred_msk)=0;
        pred_merged=sum(pred(sample_pred_msk,:),2);

        [classes,unused,pred_idxs]=unique(pred_merged);

        winners(sample_pred_msk)=pred_idxs;
        return
    end

    classes=unique(pred(pred_msk));

    % see how often each index was predicted
    counts=histc(pred,classes,2);

    [max_count,idx]=max(counts,[],2);
    nwinners=sum(bsxfun(@eq,max_count,counts),2);

    % deal with single winners
    single_winner_msk=nwinners==1;
    winners(single_winner_msk)=idx(single_winner_msk);

    % remove the single winners from samples to consider
    sample_pred_msk(single_winner_msk)=false;

    seed=0;
    for k=find(sample_pred_msk)'
        tied_idxs=find(counts(k,:)==max_count(k));
        ntied=numel(tied_idxs);
        seed=seed+1;
        winners(k)=tied_idxs(mod(seed,ntied)+1);
    end

