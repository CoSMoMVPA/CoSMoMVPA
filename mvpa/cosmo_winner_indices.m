function [winners,classes]=cosmo_winner_indices(pred)
% Given multiple predictions, get indices that were predicted most often.
%
% [winners,classes]=cosmo_winner_indices(pred)
%
% Input:
%   pred              PxQ prediction values for Q features and P
%                     predictions per feature. Values <= 0 are ignored,
%                     i.e. can never be a winner.
%
% Output:
%   winners           Px1 indices of classes that occur most often.
%                     winners(k)==w means that no value in pred(k,:)
%                     occurs more often than classes(w).
%   classes           The sorted list of unique predicted values, across
%                     all non-ignored values in pred.
%
% Example:
%     % given three predictions each for five samples, compute
%     % which predictions occur most often.
%     [p, c]=cosmo_winner_indices([4 4 4;4 5 6;4 5 6;4 5 6;6 0 0;0 0 0]);
%     p'
%     > [1, 1, 2, 3, 3, 0]
%     c'
%     > [4, 5, 6]
%
% Notes:
% - The typical use case is combining results from multiple classification
%   predictions, such as in binary support vector machines (SVMs).
% - The current implementation selects a winner pseudo-randomly (but
%   deterministically) and (presumably) unbiased in case of a tie between
%   multiple winners. That is, using the present implementation, repeatedly
%   calling this function with identical input yields identical output,
%   but unbiased with respect to which class is the 'winner' sample-wise.
% - Samples with no winner are assigned a value of zero.
% - A typical use case is combining results from multiple predictions,
%   such as in cosmo_classify_matlabsvm and cosmo_crossvalidate.
%
% See also: cosmo_classify_matlabsvm, cosmo_crossvalidate.
%
% NNO Aug 2013

    [nsamples,nfeatures]=size(pred);
    msk=pred>0; % ignore those without predictions

    % allocate space for output
    winners=zeros(nsamples,1);

    if nfeatures==1
        % special case because histc works differently on singleton dimension

        [classes,unused,pred_winners]=unique(pred(msk));
        winners(msk)=pred_winners;
        return
    end

    mx_pred=max(pred(msk));

    counts=histc(pred',1:mx_pred)';
    % optimization: if all classes in range 1:mx_pred then set classes directly
    if sum(counts(:))==sum(msk(:)) && all(sum(counts)>0)
        classes=(1:mx_pred)';
    else
        classes=unique(pred(msk)); % see which classes are predicted (slower)
        counts=histc(pred',classes)'; % how often each class was predicted
    end

    % get the first class in each feature that was predicted most often
    [mx,mxi]=max(counts,[],2);

    % mask with classes that are the winners
    winners_msk=bsxfun(@eq,counts,mx);

    % for each feature the number of winners
    nwinners=sum(winners_msk,2);

    % optimization: first take features with just one winner
    one_winner=nwinners==1;
    winners(one_winner)=mxi(one_winner);

    % now consider the remaning ones - with multiple winners
    multiple_winners=~one_winner;
    winners_msk=bsxfun(@and,winners_msk,multiple_winners);

    seed=sum(winners_msk(:)); % get some semi-random number to start with

    % get the rows (which correspond to indices of class winners) and
    % columns (corresponding to each feature)
    [unused,wcols]=ind2sub(size(winners_msk),find(winners_msk));

    colpos=1; % referring to wcols - for pseudo-random selection in ties
    for k=find(multiple_winners)' % treat each feature seperately
        nwinner=nwinners(k);

        % pseudorandomly update the seed
        seed=seed+nwinner;

        % indices of winner values
        wind=colpos+(1:nwinner);

        % select one value randomly in range 1..nwinner
        idx=mod(seed, nwinner)+2;

        % set the winner accordingly
        winners(k)=wcols(wind(idx));

        colpos=colpos+nwinner; % update for next iteration
    end

    no_winner=prod((pred<=0)+0,2)==1;
    winners(no_winner)=0;


