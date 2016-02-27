function [y_in_x,x_in_y]=cosmo_overlap(xs,ys)
% compute overlap between vectors or cellstrings in two cells
%
% [y_in_x,x_in_y]=cosmo_overlap(xs,ys)
%
% Inputs:
%    xs         Nx1 cell with all elements either numeric arrays or
%               cells with strings
%    ys         Mx1 cell with all elements either numeric arrays or
%               cells with strings
%
% Output:
%    y_in_x     MxN cell with the (i,j)-th element indicating the ratio of
%               elements in ys{j} that are present in xs{i}
%    x_in_i     MxN cell with the (i,j)-th element indicating the ratio of
%               elements in ys{i} that are present in ys{i}
%
% Examples:
%     % Compute overlap between two cells with cellstrings
%     xs={{'a'},{'a','b'},{'a','b','c'},{}};
%     ys={{'b'},{'c','b','a'}};
%     [x_in_y,y_in_x]=cosmo_overlap(xs,ys)
%     > x_in_y =
%     >          0    0.3333
%     >     1.0000    0.6667
%     >     1.0000    1.0000
%     >          0         0
%     >
%     > y_in_x =
%     >          0    1.0000
%     >     0.5000    1.0000
%     >     0.3333    1.0000
%     >        NaN       NaN
%
%     % Compute overlap between two cells with numeric arrays
%     xs={1,[1 2],1:3,[]};
%     ys={2,[3,2,1]};
%     [x_in_y,y_in_x]=cosmo_overlap(xs,ys)
%     > x_in_y =
%     >          0    0.3333
%     >     1.0000    0.6667
%     >     1.0000    1.0000
%     >          0         0
%     >
%     > y_in_x =
%     >          0    1.0000
%     >     0.5000    1.0000
%     >     0.3333    1.0000
%     >        NaN       NaN
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    [xs_vec,nx,nxs,xi]=get_counts(xs);
    [ys_vec,ny,nys,yi]=get_counts(ys);

    xy_cell=[xs_vec(:);ys_vec(:)];
    xyc=cat(1,xy_cell{:});

    % index xs from 1 to nx, and ys from (nx+1) to (nx+ny)
    xyi=[xi;(nx+yi)];

    % space for histogram
    h=zeros(nx,ny);

    % position of index of last value in xs
    xs_pos_last=sum(nxs);

    % because string comparisons are slow, use their indices instead
    [unq,unused,idxs]=unique(xyc);
    nunq=numel(unq);
    [idxs_sorted,i_sorted]=sort(idxs);

    msk=[true; any(diff(idxs_sorted,1),2)];
    unq_start_end_pos=[find(msk); 1+numel(msk)];

    for j=1:nunq
        % more readible, but slower:
        %    start_pos=unq_start_end_pos(j);
        %    end_pos=unq_start_end_pos(j+1)-1;
        %    if i_sorted(start_pos)>xs_pos_last [...]
        if i_sorted(unq_start_end_pos(j))<=xs_pos_last && ...
                i_sorted(unq_start_end_pos(j+1)-1)>xs_pos_last

            start_pos=unq_start_end_pos(j);
            end_pos=unq_start_end_pos(j+1)-1;

            i=i_sorted(start_pos:(end_pos));

            first_y=find_first_greater_than(i,xs_pos_last);
            px=xyi(i(1:(first_y-1)));
            py=xyi(i(first_y:end))-nx;

            h(px,py)=h(px,py)+1;
        end
    end

    x_in_y=bsxfun(@rdivide,h,nxs);
    y_in_x=bsxfun(@rdivide,h,nys');

function i=find_first_greater_than(sorted_vs,thr)
    % using binary search, find the first position i in sorted_vs
    % so that sorted(vs)>thr
    % it is assumed that sorted_vs is sorted
    if sorted_vs(end)<=thr
        i=numel(sorted_vs)+1;
        return
    end

    first=1;
    last=numel(sorted_vs);

    while first<last
        mid=floor((first+last)/2);
        if sorted_vs(mid)<=thr
            first=mid+1;
        else
            last=mid;
        end
    end
    i=first;
    %assert(sorted_vs(i)>thr);
    %assert(i==1 || sorted_vs(i-1)<=thr);


function [xs_vec,n,c,i]=get_counts(xs)
    n=numel(xs);
    c=zeros(n,1);
    xs_vec=cell(n,1);
    for k=1:n
        xsk=xs{k};
        if ~isnumeric(xsk) && ~iscellstr(xsk)
            error('only cells with numeric or cellstr input is supported');
        end
        c(k)=numel(xsk);
        xs_vec{k}=xsk(:);
    end

    nc=sum(c);
    i=zeros(nc,1);
    pos=0;
    for k=1:n
        ck=c(k);
        idxs=pos+(1:ck);
        i(idxs)=k;
        pos=pos+ck;
    end


