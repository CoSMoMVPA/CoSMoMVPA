function p=cosmo_cartprod(xs, convert_to_numeric)
% returns the cartesian product with all combinations from values in xs.
%
% p=cosmo_cartprod(xs, convert_to_numeric)
%
% Inputs
%   xs                   Px1 cell array with values for which the product 
%                        is to be returned. Each element xs{k} should be a
%                        cell with Qk values; or a numeric array 
%                        [xk_1,...,xk_Qk] which is interpreted as the cell
%                        {xk_1,...,xk_Qk}.
%                        Alternatively xs can be a struct with P fieldnames
%                        where each value is a cell with Qk values.
%                         
%   convert_to_numeric   If true (the default), then when the output 
%                        contains numeric values only a numerical matrix is
%                        returned; otherwise a cell is returned
% Output
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
% NNO Oct 2013

if nargin<2, convert_to_numeric=true; end

as_struct=isstruct(xs);

if as_struct
    s=xs;
    fns=fieldnames(s);
    ndim=numel(fns);
    xs=cell(1,ndim);
    for k=1:ndim
        xs{k}=s.(fns{k});
    end
end
    
if iscell(xs)
    ndim=numel(xs);
else
    error('Unsupported input');
end

xhead=xs{1};
nhead=numel(xhead);
if isnumeric(xhead)
    xhead=mat2cell(xhead(:),ones(nhead,1),1);
end
xhead={xhead{:}}';

if ndim==1
    p=xhead;
else
    me=str2func(mfilename());
    xtail={xs{2:end}};
    ptail=me(xtail, false);
    
    nhead=numel(xhead);
    ntail=size(ptail,1);
    
    n=nhead*ntail;
    
    rows=cell(nhead,1);
    for k=1:nhead
        rows{k}=cat(2,repmat({xhead{k}},ntail,1),ptail);
    end
    p=cat(1,rows{:});
end
    
if as_struct();
    n=size(p,1);
    q=cell(n,1);
    for k=1:n
        s=struct();
        for j=1:ndim
            s.(fns{j})=p{k,j};
        end
        q{k}=s;
    end
    p=q;
elseif convert_to_numeric && all(cellfun(@isnumeric,{p{:}}))
    p=reshape([p{:}],size(p));
end
    
        
    


