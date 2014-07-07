function p=cosmo_cartprod(xs, convert_to_numeric)
% returns the cartesian product with all combinations from values in xs.
%
% p=cosmo_cartprod(xs[, convert_to_numeric])
%
% Inputs:
%   xs                   Px1 cell array with values for which the product 
%                        is to be returned. Each element xs{k} should be a
%                        cell with Qk values; or a numeric array 
%                        [xk_1,...,xk_Qk] which is interpreted as the cell
%                        {xk_1,...,xk_Qk}.
%                        Alternatively xs can be a struct with P fieldnames
%                        where each value is a cell with Qk values.
%                         
%   convert_to_numeric   Optional; if true (default), then when the output 
%                        contains numeric values only a numerical matrix is
%                        returned; otherwise a cell is returned.
% Output:
%   p                    QxP cartesian product of xs (where Q=Q1*...*Qk)
%                        containing all combinations of values in xs.
%                        - If xs is a cell, then p is represented by either 
%                          a matrix (if all values in xs are numeric and 
%                          convert_to_numeric==true) or a cell (in all 
%                          other cases). 
%                        - If xs is a struct, then p is a Qx1 cell. Each
%                          element in p is a struct with the same 
%                          fieldnames as xs.
%
% Examples:
%     cosmo_cartprod({{1,2},{'a','b','c'}})'
%     > {1,2,1,2,1,2;
%     > 'a','a' ,'b','b','c','c'}
%
%     cosmo_cartprod({[1,2],[5,6,7]})'
%     > [1,2,1,2,1,2;
%     >  5,5,6,6,7,7]
% 
%     cosmo_cartprod(repmat({1:2},1,4))'
%     > [1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2;
%     >  1 1 2 2 1 1 2 2 1 1 2 2 1 1 2 2;
%     >  1 1 1 1 2 2 2 2 1 1 1 1 2 2 2 2;
%     >  1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]
%
%     s=struct();
%     s.roi={'v1','loc'};
%     s.hemi={'L','R'};
%     s.subj=[1 3 9];
%     p=cosmo_cartprod(s)';
%     cosmo_disp(p);
%     > { .roi     .roi     .roi    ... .roi     .roi     .roi
%     >     'v1'     'loc'    'v1'        'loc'    'v1'     'loc'
%     >   .hemi    .hemi    .hemi       .hemi    .hemi    .hemi
%     >     'L'      'L'      'R'         'L'      'R'      'R'
%     >   .subj    .subj    .subj       .subj    .subj    .subj
%     >     [ 1 ]    [ 1 ]    [ 1 ]       [ 9 ]    [ 9 ]    [ 9 ]   }@1x12
%     %
%     % print all combinations
%     for k=1:numel(p),fprintf('#%d:%s%s\n',p{k}.subj,p{k}.hemi,p{k}.roi);end
%     > #1:Lv1
%     > #1:Lloc
%     > #1:Rv1
%     > #1:Rloc
%     > #3:Lv1
%     > #3:Lloc
%     > #3:Rv1
%     > #3:Rloc
%     > #9:Lv1
%     > #9:Lloc
%     > #9:Rv1
%     > #9:Rloc
%
% 
% NNO Oct 2013

if nargin<2, convert_to_numeric=true; end

as_struct=isstruct(xs);

if as_struct
    % input is a struct; put the values in each field in a cell.
    s=xs; % make a copy
    fns=fieldnames(s);
    ndim=numel(fns); 
    xs=cell(1,ndim); % space for values in each dimension
    for k=1:ndim
        xs{k}=s.(fns{k});
    end
    
    if ndim==0
        p=xs;
        return
    end
end
    
if iscell(xs)
    ndim=numel(xs);
else
    error('Unsupported input: expected a cell or struct');
end

% get values in first dimension (the 'head')
xhead=xs{1};
nhead=numel(xhead);
if isnumeric(xhead) || islogical(xhead)
    % put numeric arrays in a cell
    xhead=num2cell(xhead);
end

% ensure head is a column vector
xhead=xhead(:);

if ndim==1
    p=xhead;
else
    % use recursion to find cartprod of remaining dimensions (the 'tail')
    me=str2func(mfilename()); % make imune to renaming of this function
    xtail=xs(2:end);
    ptail=me(xtail, false); % ensure output is always a cell
    
    % get sizes of head and tail
    nhead=numel(xhead);
    ntail=size(ptail,1);
    
    % allocate space for output
    rows=cell(nhead,1);
    for k=1:ntail
        % merge head and tail
        % ptailk_rep is a repeated version of the k-th tail row
        % to match the number of rows in head
        ptailk_rep=repmat(ptail(k,:),nhead,1);
        rows{k}=cat(2,xhead,ptailk_rep);
    end
    
    % stack the rows vertically
    p=cat(1,rows{:});
end

% if input was a struct, output is a cell with structs
if as_struct();
    % number of output 
    n=size(p,1);
    
    % allocate space for structs
    p_cell=cell(n,1);
    
    % set values for each struct
    for k=1:n
        s=struct();
        for j=1:ndim
            % use the same fieldnames as in the input
            s.(fns{j})=p{k,j};
        end
        p_cell{k}=s;
    end
    
    % use value of q in output
    p=p_cell;
elseif convert_to_numeric && ~isempty(p) && all(cellfun(@isnumeric,p(:)))
    % all values are numeric; convert to numeric matrix
    p=reshape([p{:}],size(p));
end
    
        
    


