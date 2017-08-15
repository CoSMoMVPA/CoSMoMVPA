function tf=cosmo_isequaln(x,y)
% compares two input for equality with NaNs considered being equal
%
% tf=cosmo_isequaln(x,y)
%
% Inputs:
%   x                   first input
%   y                   second input, to be compared with first input
%
% Output:
%   tf                  true if x and y are equal, with NaNs considered
%                       to be equal; false otherwise
%
% Examples:
%    cosmo_isequaln(2,2)
%    > true
%    cosmo_isequaln(2,3)
%    > false
%    % using the builtin isequal, NaNs are considered not equal
%    isequal(NaN,NaN)
%    > false
%    % using cosmo_isequaln, NaNs are considered to be equal to each other
%    cosmo_isequaln(NaN,NaN)
%    > true

% Notes:
%   - in earlier versions of Matlab, isequaln did not exist;
%     isequalwithequalnans was used instead. However isequaln will be
%     deprecated in GNU Octave 4.2. This function is there included for
%     compatibility with both old versions of Matlab and future versions of
%     GNU Octave
%
% See also: isequaln, isequalwithequalnans

    comparison_func=get_comparison_func();
    tf=comparison_func(x,y);


function func=get_comparison_func()
    persistent cached_comparison_func

    if isempty(cached_comparison_func)
        cached_comparison_func=find_comparison_func_helper();
    end

    func=cached_comparison_func;


function func=find_comparison_func_helper()
    candidates_str={'isequaln','isequalwithequalnans'};

    has_func=@(x)~isempty(which(x,'builtin'));
    idx=find(cellfun(has_func,candidates_str),1,'first');
    if ~isempty(idx)
        func=str2func(candidates_str{idx});
        return
    end

    error('No comparison function found from candidates: %s',...
                cosmo_strjoin(candidates_str,', '));
