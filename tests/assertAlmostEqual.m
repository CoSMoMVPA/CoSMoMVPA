function assertAlmostEqual(a,b,varargin)
    stack=empty_stack();
    assert_almost_equal(a,b,stack,varargin{:});

function assert_almost_equal(a,b,stack,varargin)
    a_class=class(a);
    assert_equal(a_class,class(b),stack,'<class>');
    switch a_class
        case 'cell'
            assert_cell_almost_equal(a,b,stack,varargin{:});
        case 'struct'
            assert_struct_almost_equal(a,b,stack,varargin{:});
        otherwise
            if isfloat(a)
                assert_elements_almost_equal(a,b,stack,varargin{:});
            else
                assert_equal(a,b,stack,'');
            end
    end

function stack=add_to_stack(stack,element)
    if stack.pos>=stack.size
        stack.size=stack.size*2;
        stack.elements{stack.size}=[];
    end
    stack.pos=stack.pos+1;
    stack.elements{stack.pos}=element;

function stack=empty_stack()
    stack=struct();
    stack.size=20;
    stack.pos=0;
    stack.elements=cell(stack.size,1);

function assert_elements_almost_equal(a,b,stack,varargin)
    try
        assertElementsAlmostEqual(a,b,varargin{:});
    catch me
        msg=stack2msg(stack);
        if isempty(msg)
            args=varargin;
        else
            args=[varargin(:);msg];
        end
        args
        assertElementsAlmostEqual(a,b,args{:});
    end



function str=ind2str(a,ind)
    sz=size(a);
    ndim=numel(sz);
    sub=cell(1,ndim);
    [sub{:}]=ind2sub(sz,ind);
    idx_str=sprintf(',%d',sub{:});
    str=idx_str(2:end);

function msg=stack2msg(stack)
    n=stack.pos;
    if n==0
        msg='';
        return
    end
    strs=cell(1,n);
    for k=1:n
        element=stack.elements{k};
        desc=element{4};
        if isnumeric(desc)
            sz=element{3};
            if isequal(sz,[1 1])
                str='';
            else
                infix=ind2str(sz,desc);
                str=[element{1} infix element{2}];
            end
        elseif ischar(desc)
            str=[element{1} desc element{2}];
        else
            assert(false);
        end
        strs{k}=str;
    end
    msg=['in element ' cat(2,strs{:})];


function assert_equal(a,b,stack,postfix)
    if ~isequal(a,b)
        msg=[stack2msg(stack) ' ' postfix ' not equal'];
        assertEqual(a,b,msg);
        assert(false);
    end

function assert_size_equal(a,b,stack)
    assert_equal(size(a),size(b),stack,'<size>')


function assert_cell_almost_equal(a,b,stack,varargin)
    assert_size_equal(a,b,stack)
    stack=add_to_stack(stack,{'{','}',size(a),NaN});
    pos=stack.pos;
    for k=1:numel(a)
        stack.elements{pos}{4}=k;
        assert_almost_equal(a{k},b{k},stack,varargin{:});
    end

function assert_struct_almost_equal(a,b,stack,varargin)
    assert_size_equal(a,b,stack)
    a_keys=fieldnames(a);
    assert_equal(sort(a_keys),sort(fieldnames(b)),stack,'<fieldnames>');

    stack=add_to_stack(stack,{'(',')',size(a),NaN});
    pos=stack.pos;
    for k=1:numel(a)
        stack.elements{pos}{4}=k;
        assert_singleton_struct_almost_equal(a(k),b(k),stack,varargin{:});
    end


function assert_singleton_struct_almost_equal(a,b,stack,varargin)
    a_keys=fieldnames(a);
    n=numel(a_keys);

    stack=add_to_stack(stack,{'.','',[],''});
    pos=stack.pos;

    for k=1:n
        key=a_keys{k};
        stack.elements{pos}{4}=key;
        assert_almost_equal(a.(key),b.(key),stack,varargin{:});
    end









