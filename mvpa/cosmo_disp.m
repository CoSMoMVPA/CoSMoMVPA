function s=cosmo_disp(x,varargin)
% converts data to a string representation
%
% TODO: - add dimensions for matrix
%       - documentation
% 
% NNO Jan 2014

    defaults.min_elips=3;
    defaults.precision=3;
    defaults.strlen=12;
    defaults.depth=4;

    opt=cosmo_structjoin(defaults,varargin);

    depth=opt.depth;
    if depth<=0
        s=surround_with('<',class(x),'>',size(x));
    else
        opt.depth=depth-1;

        if iscell(x)
            s=disp_cell(x,opt);
        elseif isnumeric(x) || islogical(x)
            s=disp_matrix(x,opt);
        elseif ischar(x)
            s=disp_string(x,opt);
        elseif isa(x, 'function_handle')
            s=disp_function_handle(x,opt);
        elseif isstruct(x)
            s=disp_struct(x,opt);
        else
            error('not supported: %s', class(x))
        end
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
            d=cosmo_disp(x.(fn),opt);
            r{k*2}=[repmat(' ',size(d,1),2) d];
        end
        y=strcat_(r);
        



    function s=disp_function_handle(x,opt)
        s=['@' disp_string(func2str(x),opt)];


    function s=disp_string(x, opt)
    if ~ischar(x), error('expected a char'); end
    if size(x,1)>1, error('need a single row'); end

    infix=' ... ';

    n=numel(x);
    if n>opt.strlen
        h=floor((opt.strlen-infix)/2);
        x=[x(1:h), infix ,x(n+((1-h):0))];
    end
    s=['''' x ''''];


    function s=disp_cell(x, opt)
    min_elips=opt.min_elips;
    precision=opt.precision;

    [ns,nf]=size(x);

    % get indices of rows and columns to show
    [r_pre, r_post]=get_mx_idxs(x, min_elips, 1);
    [c_pre, c_post]=get_mx_idxs(x, min_elips, 2);

    part_idxs={{r_pre, r_post}, {c_pre, c_post}};
    
    nrows=numel([r_pre r_post])+~isempty(r_post);
    ncols=numel([c_pre c_post])+~isempty(c_post);
    
    sinfix=cell(nrows,ncols*2+1);
    for k=1:(ncols-1)
        sinfix{1,k*2+1}='  ';
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
                
                for ri=1:nr
                    row_idx=row_idxs(ri);
                    sinfix{rpos+ri,cpos+ci*2-1}=cosmo_disp(x{row_idx,col_idx});
                end
                
                if rpart==2
                    max_length=max(cellfun(@numel,sinfix(:,cpos+ci)));
                    spaces=repmat(' ',1,floor(max_length/2-1));
                    sinfix{rpos,cpos+ci}=[spaces ':'];
                end
            end
            rpos=rpos+nr+1;
        end
        cpos=cpos+nc+1;
    end
    s=surround_with('{ ', strcat_(sinfix), ' }', size(x));
    

    
    function pre_infix_post=surround_with(pre, infix, post, matrix_sz)
        if prod(matrix_sz)~=1
            size_str=sprintf('x%d',matrix_sz);
            size_str(1)='@';
        else
            size_str='';
        end
        post=strcat_({repmat(' ',size(infix,1)-1,1); [post size_str]});
        pre_infix_post=strcat_({pre, infix, post});
        

    function s=disp_matrix(x,opt)
    min_elips=opt.min_elips;
    precision=opt.precision;

    [ns,nf]=size(x);

    % get indices of rows and columns to show
    [r_pre, r_post]=get_mx_idxs(x, min_elips, 1);
    [c_pre, c_post]=get_mx_idxs(x, min_elips, 2);

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
        sinfix(1:3,2)={s(1:min_elips,:);line;s(min_elips+(1:min_elips),:)};
    end

    if ~isempty(c_post)
        % insert '  ...  ' halfway (column-wise)
        ndata=nc-2*(size(y,2)-1); % without spaces in between
        step_size=ceil(ndata/size(y,2));
        % position of dots
        dpos=step_size*(min_elips)+mod(nc,step_size)+4;

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

    function [pre,post]=get_mx_idxs(x, min_elips, dim)
    n=size(x,dim);

    if n>2*min_elips
        pre=1:min_elips;
        post=n-min_elips+(1:min_elips);
    else
        pre=1:n;
        post=[];
    end

