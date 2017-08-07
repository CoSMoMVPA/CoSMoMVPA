function cosmo_disp(x,varargin)
% display the input as a string representation
%
% cosmo_disp(x,opt)
%
% Inputs:
%   x              any type of data element (can be a dataset struct)
%   opt            Optional struct with fields
%     .threshold   If the number of values in an array along a dimension
%                  exceeds threshold, then an array is showed in summary
%                  style along that dimension. Default: 5
%     .edgeitems   When an array is shown in summary style, edgeitems sets
%                  the number of items at the beginning and end of the
%                  array to be shown (separated by '...' in rows and by ':'
%                  in columns).
%                  Default: 3
%     .precision   Numeric precision, indicating number of decimals after
%                  the floating point
%                  Default: 3
%     .strlen      Maximal string lenght, if a string is longer the
%                  beginning and end are shown separated by ' ... '.
%                  Default: 20
%     .depth       Maximum recursion depth
%                  Default: 6
%
% Side effect:     Calling this function caused the representation of x
%                  to be displayed.
%
%
% Examples:
%     % display a complicated data structure
%     x=struct();
%     x.a_cell={[],{'cell within cell',[1 2; 3 4]}};
%     x.small_matrix=[10 11 12; 13 14 15];
%     x.big_matrix=reshape(1:200,10,20);
%     x.huge=2^40;
%     x.tiny=2^-40;
%     x.a_string='hello world';
%     x.a_struct.another_struct.name='me';
%     x.a_struct.another_struct.func=@abs;
%     cosmo_disp(x);
%     > .a_cell
%     >   { [  ]  { 'cell within cell'  [ 1         2
%     >                                   3         4 ] } }
%     > .small_matrix
%     >   [ 10        11        12
%     >     13        14        15 ]
%     > .big_matrix
%     >   [  1        11        21  ...  171       181       191
%     >      2        12        22  ...  172       182       192
%     >      3        13        23  ...  173       183       193
%     >      :         :         :        :         :         :
%     >      8        18        28  ...  178       188       198
%     >      9        19        29  ...  179       189       199
%     >     10        20        30  ...  180       190       200 ]@10x20
%     > .huge
%     >   [ 1.1e+12 ]
%     > .tiny
%     >   [ 9.09e-13 ]
%     > .a_string
%     >   'hello world'
%     > .a_struct
%     >   .another_struct
%     >     .name
%     >       'me'
%     >     .func
%     >       @abs
%     %
%     cosmo_disp(x.a_cell)
%     > { [  ]  { 'cell within cell'  [ 1         2
%     >                                 3         4 ] } }
%     cosmo_disp(x.a_cell{2}{2})
%     > [ 1         2
%     >   3         4 ]
%
%     % illustrate recursion 'depth' argument
%     m={'hello'};
%     % make a cell in a cell in a cell in a cell ...
%     for k=1:10, m{1}=m; end;
%     cosmo_disp(m)
%     > { { { { { { <cell> } } } } } }
%     cosmo_disp(m,'depth',8)
%     > { { { { { { { { <cell> } } } } } } } }
%     cosmo_disp(m,'depth',Inf)
%     > { { { { { { { { { { { 'hello' } } } } } } } } } } }
%
%     % illustrate 'threshold' and 'edgeitems' arguments
%     cosmo_disp(num2cell('a':'k'))
%     > { 'a'  'b'  'c' ... 'i'  'j'  'k'   }@1x11
%     cosmo_disp(num2cell('a':'k'),'threshold',Inf)
%     > { 'a'  'b'  'c'  'd'  'e'  'f'  'g'  'h'  'i'  'j'  'k' }
%     cosmo_disp(num2cell('a':'k'),'edgeitems',2)
%     > { 'a'  'b' ... 'j'  'k'   }@1x11
%
%     % illustrate 'precision' argument
%     for p=1:2:7, cosmo_disp(pi*[1 2],'precision',p); end
%     > [ 3       6 ]
%     > [ 3.14      6.28 ]
%     > [ 3.1416      6.2832 ]
%     > [ 3.141593      6.283185 ]
%
%     % illustrate n-dimensional arrays
%     x=zeros([2 2 1 2 3]);
%     x(:)=2*(1:numel(x));
%     cosmo_disp(x)
%     > <double>@2x2x1x2x3
%     >    (:,:,1,1,1) =  [ 2         6
%     >                     4         8 ]
%     >    (:,:,1,2,1) =  [ 10        14
%     >                     12        16 ]
%     >    (:,:,1,1,2) =  [ 18        22
%     >                     20        24 ]
%     >    (:,:,1,2,2) =  [ 26        30
%     >                     28        32 ]
%     >    (:,:,1,1,3) =  [ 34        38
%     >                     36        40 ]
%     >    (:,:,1,2,3) =  [ 42        46
%     >                     44        48 ]
%     cosmo_disp(reshape(char(65:72),[2 2 2]))
%     > <char>@2x2x2
%     >    (:,:,1) = 'AC
%     >               BD'
%     >    (:,:,2) = 'EG
%     >               FH'
%     cosmo_disp(zeros([2 3 5 7 0 2]))
%     > <double>@2x3x5x7x0x2 (empty)
%
%     % illustrate non-singleton structs
%     x=struct('x',{1 2; 3 4});
%     cosmo_disp(x);
%     > <struct>@2x2
%     >    (1,1).x
%     >           [ 1 ]
%     >    (2,1).x
%     >           [ 3 ]
%     >    (1,2).x
%     >           [ 2 ]
%     >    (2,2).x
%     >           [ 4 ]
%     x3=cat(3,x,x,x);
%     cosmo_disp(x3);
%     > <struct>@2x2x3
%     >    (1,1,1).x
%     >             [ 1 ]
%     >    (2,1,1).x
%     >             [ 3 ]
%     >    (1,2,1).x
%     >             [ 2 ]
%     >      :        :
%     >    (2,1,3).x
%     >             [ 3 ]
%     >    (1,2,3).x
%     >             [ 2 ]
%     >    (2,2,3).x
%     >             [ 4 ]
%
% Notes:
%   - Unlike the builtin 'disp' function, this function shows the contents
%     of the input using recursion. For example if a cell contains a
%     struct, then the contents of that struct is shown as well
%   - A use case is displaying dataset structs
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    defaults.threshold=5;    % max #items before triggering summary style
    defaults.edgeitems=3;    % #items at edges in summary style
    defaults.precision=3;    % show floats with 3 decimals
    defaults.strlen=20;      % insert '...' with strings more than 20 chars
    defaults.depth=6;        % maximal depth
    defaults.show_size=false;% whether to show size of matrices

    opt=cosmo_structjoin(defaults,varargin);

    % get string representation of x
    s=disp_helper(x, opt);

    % print string representation of x
    disp(s);

function s=disp_helper(x, opt)
    % general helper function to get a string representation. Unlike the
    % main function this function returns a string, which makes it suitable
    % for recursion
    depth=opt.depth;
    if depth<=0
        s=any2summary_str(x,opt);
        return
    end

    opt.depth=depth-1;

    if ~has_size(x)
        s=any2summary_str(x,opt);
    else
        s=nd_any2str(x,opt);
    end

function s=any2summary_str(x,unused)
    if has_size(x)
        sz=size(x);
    else
        sz=[1 1];
    end
    s=surround_with(true,'<',class(x),'>',sz);

function tf=has_size(x)
    % helper, because some classes have no 'size'
    try
        size(x);
        tf=true;
    catch
        tf=false;
    end

function y=nd_any2str(x,opt)
    if isstruct(x)
        if numel(x)<=1
            y=struct2str(x,opt);
        else
            y=multi_any2string(x,0,opt);
        end
    elseif numel(size(x))==2
        if iscell(x)
            y=cell2str(x,opt);
        elseif isnumeric(x) || islogical(x)
            y=matrix2str(x,opt);
        elseif ischar(x)
            y=string2str(x,opt);
        elseif isa(x, 'function_handle')
            y=function_handle2str(x,opt);
        else
            y=any2summary_str(x,opt);
        end
    else
        y=multi_any2string(x,2,opt);
    end


function y=multi_any2string(x,ndim_post,opt)
    sz=size(x);
    sz_rest=sz((ndim_post+1):end);
    ndim_rest=numel(sz_rest);
    n_rest=prod(sz_rest);

    parts=cell(ndim_rest,1);
    for k=1:ndim_rest
        parts{k}=num2cell(1:sz_rest(k));
    end

    p=cosmo_cartprod(parts);
    if ndim_post>0
        xflat=reshape(x,[sz(1:ndim_post) n_rest]);
    else
        xflat=x(:);
    end

    [pre,post]=get_mx_idxs(xflat,opt.edgeitems,opt.threshold,ndim_post+1);

    header=any2summary_str(x,opt);
    s_pre=nd_any2str_helper(xflat,p, pre,opt);

    if isempty(post)
        s_post={'',''};
        s_dots={'',''};
    else
        s_post=nd_any2str_helper(xflat,p,post,opt);
        s_dots=cell(1,2);
        for k=1:2
            szs=cellfun(@(x)size(x,2),s_post(:,k));
            pos=round(max(szs)/2);
            s_dots{k}=[spaces(1,pos) ':'];
        end
    end
    s_all=cat(1,s_pre,s_dots,s_post);

    y=strcat_({header;strcat_(s_all)});


function s=nd_any2str_helper(xflat, p, idxs, opt)
    n_rest=numel(idxs);
    s=cell(n_rest,2);
    sz=size(xflat);
    npre=numel(sz)-1;
    for k=1:n_rest
        idx=idxs(k);
        switch npre
            case 1
                % for struct
                v=xflat(idx);
                idx_prefix='';
                idx_postfix='';
            case 2
                % anything else
                v=xflat(:,:,idx);
                idx_prefix=':,:,';
                idx_postfix=' = ';
            otherwise
                assert(false);
        end

        v_str=disp_helper(v,opt);
        idx_str=sprintf(',%d',p(idx,:));
        s{k,1}=sprintf('   (%s%s)%s',idx_prefix,idx_str(2:end),idx_postfix);
        s{k,2}=v_str;
    end


function y=strcat_(xs)
    if isempty(xs)
        y='';
        return
    end

    % all elements in xs are char
    [nr,nc]=size(xs);
    ys=cell(1,nc);

    % sizes for each element
    width_per_col=max_element_size(xs,2);
    height_per_row=max_element_size(xs,1);
    for k=1:nc
        xcol=cell(nr,1);
        width=width_per_col(k);
        row_pos=0;
        for j=1:nr
            height=height_per_row(j);
            if height==0
                continue;
            end

            x=xs{j,k};
            if ~ischar(x) && isempty(x)
                x='';
            end

            sx=size(x);
            to_add=[height width]-sx;

            % pad with spaces
            row_pos=row_pos+1;
            xcol{row_pos}=[[x spaces(sx(1),to_add(2))];...
                        spaces(to_add(1), width)];
        end
        ys{k}=char(xcol{1:row_pos});
    end
    y=[ys{:}];

function m=max_element_size(x,dim)
    % faster than cellfun
    n=numel(x);
    sizes=zeros(size(x));
    for k=1:n
        sizes(k)=size(x{k},dim);
    end
    m=max(sizes,[],3-dim);



function y=spaces(nx,ny)
    % faster than repmat(' ',nx,ny)
    if nx>0 && ny>0
        y(nx,ny)=' ';
        y(:)=' ';
    else
        if nx<0
            nx=0;
        end
        if ny<0
            ny=0;
        end
        y=reshape('',nx,ny);
    end



function y=struct2str(x,opt)
    if numel(x)==0
        show_size=opt.show_size;
        y=[surround_with(show_size,'', 'struct', '', size(x)) ' (empty)'];
        return;
    end

    assert(numel(x)==1)
    fns=fieldnames(x);
    n=numel(fns);

    if n==0
        show_size=opt.show_size;
        y=[surround_with(show_size,'', 'struct', '', size(x)) ' (empty)'];
    else
        r=cell(n*2,1);
        for k=1:n
            fn=fns{k};
            r{k*2-1}=['.' fn];
            d=disp_helper(x.(fn),opt);
            r{k*2}=[spaces(size(d,1),2) d];
        end
        y=strcat_(r);
    end

function s=function_handle2str(x,opt)
    s_with_quotes=string2str(func2str(x),opt);
    s=['@' s_with_quotes(2:(end-1))];


function s=string2str(x, opt)
    if ~ischar(x), error('expected a char'); end
    [nrows,ncols]=size(x);


    if ncols>opt.strlen
        infix=' ... ';
        h=floor((opt.strlen-numel(infix))/2);
        x=strcat_({x(:,1:h), infix ,x(:,ncols+((1-h):0))});
    end
    quote='''';
    pre=quote;
    post=[spaces(nrows-1,1);quote];
    s=strcat_({pre,x,post});


function s=cell2str(x, opt)
    % display a cell

    edgeitems=opt.edgeitems;
    threshold=opt.threshold;

    % get indices of rows and columns to show
    [r_pre, r_post]=get_mx_idxs(x, edgeitems, threshold, 1);
    [c_pre, c_post]=get_mx_idxs(x, edgeitems, threshold, 2);

    part_idxs={{r_pre, r_post}, {c_pre, c_post}};

    nrows=numel([r_pre r_post])+~isempty(r_post);
    ncols=numel([c_pre c_post])+~isempty(c_post);

    sinfix=cell(nrows,ncols*2+1);
    for k=1:(ncols-1)
        sinfix{1,k*2+2}='  ';
    end

    cpos=1;
    for cpart=1:2
        col_idxs=part_idxs{2}{cpart};
        nc=numel(col_idxs);

        rpos=0;
        for rpart=1:2
            row_idxs=part_idxs{1}{rpart};

            nr=numel(row_idxs);
            if nr==0
                continue
            end
            for ci=1:nc
                col_idx=col_idxs(ci);
                trgc=cpos+ci*2;
                for ri=1:nr
                    row_idx=row_idxs(ri);
                    sinfix{rpos+ri,trgc}=disp_helper(x{row_idx,...
                                                             col_idx},opt);
                    if cpart==2 && ci==1 && nc>0
                        sinfix{rpos+ri,cpos+ci*2-1}=' ... ';
                    end
                end


                if rpart==2
                    max_length=max(cellfun(@numel,sinfix(:,trgc)));
                    pre_spaces=spaces(1,floor(max_length/2-1));
                    sinfix{rpos,cpos+ci*2}=[pre_spaces ':'];
                end
            end
            rpos=rpos+nr+1;
        end
        cpos=cpos+nc*2;
    end

    show_size=opt.show_size || ~isempty(r_post) || ~isempty(c_post);
    s=surround_with(show_size,'{ ', strcat_(sinfix), ' }', size(x));



function pre_infix_post=surround_with(show_size, pre, infix, post, matrix_sz)
    % surround infix by pre and post, doing
    n=prod(matrix_sz);
    if show_size && n~=1
        size_str=sprintf('x%d',matrix_sz);
        size_str(1)='@';
        if n==0
            size_str=[size_str ' (empty)'];
        end
    else
        size_str='';
    end
    post=strcat_({spaces(size(infix,1)-1,1); [post size_str]});
    pre_infix_post=strcat_({pre, infix, post});


function s=matrix2str(x,opt)
    if isempty(x)
        show_size=opt.show_size;
        s=surround_with(show_size,'[','  ',']',size(x));
        return
    end

    % display a matrix
    edgeitems=opt.edgeitems;
    threshold=opt.threshold;
    precision=opt.precision;

    % get indices of rows and columns to show
    [r_pre, r_post]=get_mx_idxs(x, edgeitems, threshold, 1);
    [c_pre, c_post]=get_mx_idxs(x, edgeitems, threshold, 2);

    % data to be shown
    y=x([r_pre r_post],[c_pre c_post]);

    % convert to string
    s=num2str(y,precision);

    % number of characters in first and second dimension
    [nc_row,nc_col]=size(s);

    % see where each column is a space; that's a potential split point
    sp_col=sum(s==' ',1)==nc_row;

    % col_index has value k for characters in the k-th column, else zero
    col_index=zeros(1,nc_col);
    col_count=1;
    in_num=true;
    for k=1:nc_col
        if in_num
            if sp_col(k)
                col_count=col_count+1;
                in_num=false;

            else
                col_index(k)=col_count;
            end
        elseif ~sp_col(k)
            in_num=true;
            col_index(k)=col_count;
        end
    end

    % deal with rows
    row_blocks=cell(3,1);
    if isempty(r_post)
        row_blocks{1,1}=s;
    else
        % insert ':' for each column
        line=spaces(1,nc_col);
        for k=1:max(col_index)
            idxs=find(col_index==k);
            median_pos=round(mean(idxs));
            line(median_pos)=':';
        end
        row_blocks{1}=s(1:edgeitems,:);
        row_blocks{2}=line;
        row_blocks{3}=s(edgeitems+(1:edgeitems),:);
    end

    % deal with columns
    row_and_col_blocks=cell(3,3);
    for row=1:3
        if isempty(c_post)
            row_and_col_blocks{row}=row_blocks{row};
        else
            % insert ' ... ' halfway each row
            pre_end=find(col_index==edgeitems,1,'last')+1;
            post_start=find(col_index==(edgeitems+1),1,'first')-1;

            r=row_blocks{row,1};
            if isempty(r)
                continue;
            end
            row_and_col_blocks{row,1}=r(:,1:pre_end);
            if row~=2
                row_and_col_blocks{row,2}=repmat(' ... ',size(r,1),1);
            end
            row_and_col_blocks{row,3}=r(:,post_start:end);
        end
    end

    show_size=opt.show_size || ~isempty(r_post) || ~isempty(c_post);
    s=surround_with(show_size,'[ ',strcat_(row_and_col_blocks),' ]',...
                                                                size(x));


function [pre,post]=get_mx_idxs(x, edgeitems, threshold, dim)
    % returns the first and last indices for showing an array along
    % dimension dim. If size(x,dim)<2*edgeitems, then pre has all the
    % indices, otherwise pre and post have the first and last edgeitems
    % indices, respectively
    n=size(x,dim);

    if n>max(threshold,2*edgeitems) % properly deal with Inf values
        pre=1:edgeitems;
        post=n-edgeitems+(1:edgeitems);
    else
        pre=1:n;
        post=[];
    end

