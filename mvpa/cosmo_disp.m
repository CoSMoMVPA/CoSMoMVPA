function cosmo_disp(x,varargin)
% converts data to a string representation
%
% cosmo_disp(x,opt)
%
% Inputs:
%   x              data element, can be a dataset struct
%                  At present only elements with at most two dimensions are
%                  supported.
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
%                  Default: 5
%
% Side effect:     Calling this function caused the representation of x
%                  to be displayed.
%    
% 
% Examples:
%
%    x=struct();
%    x.a_cell={[],{'cell within cell',[1 2; 3 4]}};
%    x.a_matrix=[10 11 12; 13 14 15];
%    x.a_string='hello world';
%    x.a_struct.another_struct.name='me';
%    cosmo_disp(x);
%    >  .a_cell                                                            
%    >    { [  ]@0x0  { 'cell within cell'  [ 1         2                  
%    >                                        3         4 ]@2x2 }@1x2 }@1x2
%    >  .a_matrix                                                          
%    >    [ 10        11        12                                         
%    >      13        14        15 ]@2x3                                   
%    >  .a_string                                                          
%    >    'hello world'                                                    
%    >  .a_struct                                                          
%    >    .another_struct                                                  
%    >      .name                                                          
%    >        'me'
%
%    cosmo_disp(x.a_cell)
%    > { [  ]@0x0  { 'cell within cell'  [ 1         2                  
%    >                                     3         4 ]@2x2 }@1x2 }@1x2
%
%    cosmo_disp(x.a_cell{2}{2})
%    >  [ 1         2      
%    >    3         4 ]@2x2
%
%    % illustrate recursion 'depth' argument 
%    m={'hello'};
%    for k=1:10, m{1}=m; end;
%    cosmo_disp(m)
%    > { { { { { <cell> } } } } }
%    cosmo_disp(m,'depth',8)
%    > { { { { { { { { <cell> } } } } } } } }
%    cosmo_disp(m,'depth',Inf)
%    > { { { { { { { { { { { 'hello' } } } } } } } } } } }
%
%    % illustrate 'threshold' and 'edgeitems' arguments
%    cosmo_disp(num2cell('a':'k'))
%    > { 'a'  'b'  'c' ... 'i'  'j'  'k'   }@1x11
%    cosmo_disp(num2cell('a':'k'),'threshold',Inf)
%    > { 'a'  'b'  'c'  'd'  'e'  'f'  'g'  'h'  'i'  'j'  'k' }@1x11
%    cosmo_disp(num2cell('a':'k'),'edgeitems',2)
%    > { 'a'  'b' ... 'j'  'k'   }@1x11
%
%
% Notes:
%   - Unlike the builtin 'disp' function, this function shows the contents 
%     of x using recursion. For example if a cell contains a struct, then
%     the contents of that struct is shown as well
%   - Limitations:
%     * no support for structures with more than three dimensions
%     * structs must be singleton (of size 1x1)
%     * character arrays must be 1xP
%   - A use case is displaying dataset structs
% 
% NNO Jan 2014

    defaults.threshold=5;  % max #items before triggering summary style
    defaults.edgeitems=3;  % #items at edges in summary style
    defaults.precision=3;  % show floats with 3 decimals
    defaults.strlen=20;    % insert '...' with strings longer than 16 chars
    defaults.depth=5;      % maximal depth

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
        s=surround_with('<',class(x),'>',size(x));
        return
    end    

    opt.depth=depth-1;

    if iscell(x)
        check_is_matrix(x);
        s=disp_cell(x,opt);
    elseif isnumeric(x) || islogical(x)
        check_is_matrix(x);
        s=disp_matrix(x,opt);
    elseif ischar(x)
        check_is_matrix(x);
        s=disp_string(x,opt);
    elseif isa(x, 'function_handle')
        s=disp_function_handle(x,opt);
    elseif isstruct(x)
        check_is_singleton(x);
        s=disp_struct(x,opt);
    else
        error('not supported: %s', class(x))
    end

function check_is_matrix(s)
    ndim=numel(size(s));
    if ndim~=2
        error('Element with %d dimensions, only 2 are supported',ndim);
    end
    
function check_is_singleton(s)
    n=numel(s);
    if n>1
        error('Non-singleton elements (found %d values) not supported',n);
    end
    
function y=strcat_(xs)
    if isempty(xs)
        y='';
        return
    end
        
    % all elements in xs are char
    [nr,nc]=size(xs);
    ys=cell(1,nc);

    % height of each row
    width_per_col=max(cellfun(@(x)size(x,2),xs),[],1);
    height_per_row=max(cellfun(@(x)size(x,1),xs),[],2);
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
            sx=size(x);
            to_add=[height width]-sx;
            
            % pad with spaces
            row_pos=row_pos+1;
            xcol{row_pos}=[[x repmat(' ',sx(1),to_add(2))];...
                        repmat(' ',to_add(1), width)];
        end
        ys{k}=char(xcol{1:row_pos});
    end
    y=[ys{:}];


function y=disp_struct(x,opt)
    fns=fieldnames(x);
    n=numel(fns);
    r=cell(n*2,1);
    for k=1:n
        fn=fns{k};
        r{k*2-1}=['.' fn];
        d=disp_helper(x.(fn),opt);
        r{k*2}=[repmat(' ',size(d,1),2) d];
    end
    y=strcat_(r);




function s=disp_function_handle(x,opt)
    s=['@' disp_string(func2str(x),opt)];


function s=disp_string(x, opt)
    if ~ischar(x), error('expected a char'); end
    if size(x,1)>1, error('string has to be a single row'); end

    infix=' ... ';

    n=numel(x);
    if n>opt.strlen
        h=floor((opt.strlen-numel(infix))/2);
        x=[x(1:h), infix ,x(n+((1-h):0))];
    end
    s=['''' x ''''];


function s=disp_cell(x, opt)
    % display a cell
    
    edgeitems=opt.edgeitems;
    threshold=opt.threshold;
    precision=opt.precision;

    [ns,nf]=size(x);

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
                    spaces=repmat(' ',1,floor(max_length/2-1));
                    sinfix{rpos,cpos+ci*2}=[spaces ':'];
                end
            end
            rpos=rpos+nr+1;
        end
        cpos=cpos+nc*2;
    end
    
    s=surround_with('{ ', strcat_(sinfix), ' }', size(x));
    

    
function pre_infix_post=surround_with(pre, infix, post, matrix_sz)
    % surround infix by pre and post, doing 
    if prod(matrix_sz)~=1
        size_str=sprintf('x%d',matrix_sz);
        size_str(1)='@';
    else
        size_str='';
    end
    post=strcat_({repmat(' ',size(infix,1)-1,1); [post size_str]});
    pre_infix_post=strcat_({pre, infix, post});
        

function s=disp_matrix(x,opt)
    % display a matrix
    edgeitems=opt.edgeitems;
    threshold=opt.threshold;
    precision=opt.precision;

    [ns,nf]=size(x);

    % get indices of rows and columns to show
    [r_pre, r_post]=get_mx_idxs(x, edgeitems, threshold, 1);
    [c_pre, c_post]=get_mx_idxs(x, edgeitems, threshold, 2);

    y=x([r_pre r_post],[c_pre c_post]);

    s=num2str(y,precision);
    [nr,nc]=size(s);
    
    sinfix=cell(3,5);

    if isempty(r_post)
        % no split in rows
        sinfix{1,2}=s;
    else
        ndata=nc-2*(size(y,2)-1); % without spaces in between
        step_size=ceil((ndata+1)/size(y,2))+2;
        offset=1;
                
        if isnan(step_size)
            cpos=offset;
        else
            cpos=offset:step_size:nc; % position of colon
        end
        line=repmat(' ',1,nc);
        line(cpos)=':';
        sinfix(1:3,2)={s(1:edgeitems,:);line;s(edgeitems+(1:edgeitems),:)};
    end

    if ~isempty(c_post)
        % insert '  ...  ' halfway (column-wise)
        ndata=nc-2*(size(y,2)-1); % without spaces in between
        step_size=ceil(ndata/size(y,2));
        % position of dots
        dpos=step_size*(edgeitems)+mod(nc,step_size)+4;

        for k=1:size(sinfix,1)
            si=sinfix{k,2};
            if isempty(si)
                continue
            end
            
            sinfix(k,2:4)={si(:,1:dpos), ...
                            repmat('  ...  ',size(si,1),1),...
                            si(:,(dpos+1):end)};
        end
    end
    
    s=surround_with('[ ',strcat_(sinfix),' ]', size(x));

function [pre,post]=get_mx_idxs(x, edgeitems, threshold, dim)
    % returns the first and last indices for showing an array along
    % dimension dim. If size(x,dim)<2*edgeitems, then pre has all the
    % indices, otherwise pre and post have the first and last edgeitems
    % indices, respectively
    n=size(x,dim);

    if n>max(threshold,2*edgeitems)
        pre=1:edgeitems;
        post=n-edgeitems+(1:edgeitems);
    else
        pre=1:n;
        post=[];
    end

