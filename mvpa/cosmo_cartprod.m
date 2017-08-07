function p=cosmo_cartprod(xs, convert_to_numeric)
% returns the cartesian product with all combinations of the input
%
% p=cosmo_cartprod(xs[, convert_to_numeric])
%
% Inputs:
%   xs                   Px1 cell array with values for which the product
%                        is to be returned. Each element xs{k} should be
%                        - a cell with Qk values
%                        - a numeric array [xk_1,...,xk_Qk], which is
%                          interpreted as the cell {xk_1,...,xk_Qk}.
%                        - or a string s, which is interpreted as {s}.
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
%     s.ana='vis';
%     s.beta=4;
%     p=cosmo_cartprod(s)';
%     cosmo_disp(p);
%     > { .roi     .roi     .roi    ... .roi     .roi     .roi
%     >     'v1'     'loc'    'v1'        'loc'    'v1'     'loc'
%     >   .hemi    .hemi    .hemi       .hemi    .hemi    .hemi
%     >     'L'      'L'      'R'         'L'      'R'      'R'
%     >   .subj    .subj    .subj       .subj    .subj    .subj
%     >     [ 1 ]    [ 1 ]    [ 1 ]       [ 9 ]    [ 9 ]    [ 9 ]
%     >   .ana     .ana     .ana        .ana     .ana     .ana
%     >     'vis'    'vis'    'vis'       'vis'    'vis'    'vis'
%     >   .beta    .beta    .beta       .beta    .beta    .beta
%     >     [ 4 ]    [ 4 ]    [ 4 ]       [ 4 ]    [ 4 ]    [ 4 ]   }@1x12
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
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2, convert_to_numeric=true; end

    as_struct=isstruct(xs);

    if as_struct
        % input is a struct; put the values in each field in a cell.
        [xs,fns]=struct2cell(xs);
    elseif ~iscell(xs)
        error('Unsupported input: expected a cell or struct');
    end

    if isempty(xs)
        p=cell(1,0);
        return
    end

    p=cartprod(xs);

    % if input was a struct, output is a cell with structs
    if as_struct();
        p=cell2structs(p, fns);
    elseif convert_to_numeric && ~isempty(p) && ...
                        all(cellfun(@isnumeric,p(:)))
        % all values are numeric; convert to numeric matrix
        p=reshape([p{:}],size(p));
    end

function p=cartprod(xs)

    ndim=numel(xs);

    % get values in first dimension (the 'head')
    xhead=xs{1};
    if isnumeric(xhead) || islogical(xhead)
        % put numeric arrays in a cell
        xhead=num2cell(xhead);
    elseif ischar(xhead)
        xhead={xhead};
    end

    % ensure head is a column vector
    xhead=xhead(:);

    if ndim==1
        p=xhead;
    else
        % use recursion to find cartprod of remaining dimensions
        % (the 'tail')
        xtail=xs(2:end);
        ptail=cartprod(xtail); % ensure output is always a cell

        % get sizes of head and tail
        nhead=numel(xhead);
        ntail=size(ptail,1);

        % allocate space for output
        rows=cell(ntail,1);
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



function [c,fns]=struct2cell(xs)
    fns=fieldnames(xs);
    ndim=numel(fns);
    c=cell(1,ndim); % space for values in each dimension
    for k=1:ndim
        c{k}=xs.(fns{k});
    end

function struct_cell=cell2structs(p, fns)
    % number of output
    n=size(p,1);
    ndim=numel(fns);

    % allocate space for structs
    struct_cell=cell(n,1);

    % set values for each struct
    for k=1:n
        s=struct();
        for j=1:ndim
            % use the same fieldnames as in the input
            s.(fns{j})=p{k,j};
        end
        struct_cell{k}=s;
    end
