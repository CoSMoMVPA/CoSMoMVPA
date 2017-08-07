function [tail_values, idxs]=cosmo_tail(values, to_select)
% find values in left or right tail of a vector or string
%
% [tail_values, idxs]=cosmo_tail(values, to_select)
%
% Inputs:
%   values             vector or cell with strings
%   to_select          - if between -1 and 1, then (abs(to_select))*100%
%                        (rounded up to the nearest integer) values
%                        are returned
%                      - otherwise, abs(to_select) values are returned
%                      Negative values return the smallest values, positive
%                      values return the largest values
%
% Returns:
%   tail_values        the largest or smallest values in values
%   idxs               the indices of the values in tail_values, i.e.
%                      tail_values=values(idxs)
%
% Examples:
%     % two largest values
%     [v,i]=cosmo_tail(10:15,2)
%     > v = 15 14
%     > i = 6 5
%
%     % two smallest values
%     [v,i]=cosmo_tail(10:15,-2)
%     > v = 10 11
%     > i = 1 2
%
%     % 40% largest values
%     [v,i]=cosmo_tail(10:15,.4)
%     > v = 15 14 13
%     > i = 6 5 4
%
%     % 40% smallest values
%     [v,i]=cosmo_tail(10:15,-.4)
%     > v = 10 11 12
%     > i = 1 2 3
%
%     % 40% largest values
%     [v,i]=cosmo_tail({'a','d','c','b'},.4)
%     > v = 'd' 'c'
%     > i = 2 3
%
%     % 70% smallest values
%     [v,i]=cosmo_tail({'a','d','c','b'},-.7)
%     > v = 'a' 'b' 'c'
%     > i = 1 4 3
%
%     % matrix input is not supported
%     [v,i]=cosmo_tail(zeros(3),-.7)
%     > error('Only vector or cell with strings input is supported');
%
%     % values exceeding the size of the input is not supported
%     [v,i]=cosmo_tail(10:15,66)
%     > error('Cannot select 66 values: input has 6 values');
%
%     % second argument must be scalar
%     [v,i]=cosmo_tail(10:15,[2,3])
%     > error('Second argument must be scalar');
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    check_input(values, to_select);

    right_tail=to_select>0;
    tail_value=abs(to_select);

    n=numel(values);
    if tail_value>=1
        if tail_value>n
            error('Cannot select %d values: input has %d values',...
                        tail_value,n);
        end
        ntail=tail_value;
    else
        ntail=ceil(n*tail_value);
    end

    [unused,all_idxs]=sort(values);
    if right_tail
        all_idxs=all_idxs(end:-1:1);
    end

    idxs=all_idxs(1:ntail);
    tail_values=values(idxs);




function check_input(values, to_select)
    if ~(isvector(values) && (isnumeric(values) || iscellstr(values)))
        error('Only vector or cell with strings input is supported');
    end

    if ~(isscalar(to_select) && isnumeric(to_select))
        error('Second argument must be scalar');
    end
