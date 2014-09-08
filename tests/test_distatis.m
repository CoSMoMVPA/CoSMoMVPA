function test_suite = test_statis
    initTestSuite;


function test_statis_
    % using: 1.	Abdi, H. & Valentin, D. in Encyclopedia of Measurement
    %        and Statistics (Salkind, N.) 42?42 (SAGE Publications, 2007).

    d=cell(0);
    % note: element [1,3] is reported as .148, for symmetry use .146
    d{1}=[   0    0.1120    0.1460    0.0830    0.1860    0.1100
        0.1120         0    0.1520    0.0980    0.1580    0.1340
        0.1460    0.1520         0    0.2020    0.2850    0.2490
        0.0830    0.0980    0.2020         0    0.1310    0.1100
        0.1860    0.1580    0.2850    0.1310         0    0.1550
        0.1100    0.1340    0.2490    0.1100    0.1550         0];

    d{2}=[   0    0.6000    1.9800    0.4200    0.1400    0.5800
        0.6000         0    2.1000    0.7800    0.4200    1.3400
        1.9800    2.1000         0    2.0200    1.7200    2.0600
        0.4200    0.7800    2.0200         0    0.5000    0.8800
        0.1400    0.4200    1.7200    0.5000         0    0.3000
        0.5800    1.3400    2.0600    0.8800    0.3000         0];

    d{3}=[   0    0.5400    1.3900    5.7800   10.2800    6.7700
        0.5400         0    1.0600    3.8000    6.8300    4.7100
        1.3900    1.0600         0    8.0100   11.0300    5.7200
        5.7800    3.8000    8.0100         0    2.5800    6.0900
       10.2800    6.8300   11.0300    2.5800         0    3.5300
        6.7700    4.7100    5.7200    6.0900    3.5300         0];
    d{4}=[   0    0.0140    0.1590    0.0040    0.0010    0.0020
        0.0140         0    0.0180    0.0530    0.0240    0.0040
        0.1590    0.0180         0    0.2710    0.0670    0.0530
        0.0040    0.0530    0.2710         0    0.0010    0.0080
        0.0010    0.0240    0.0670    0.0010         0    0.0070
        0.0020    0.0040    0.0530    0.0080    0.0070         0];

    nsubj=numel(d);
    ds_all=cell(nsubj,1);
    for k=1:nsubj
        ds=struct();
        sq=cosmo_squareform(d{k});
        ds.samples=sq(:);
        nd=size(d{k},1);

        ns=size(ds.samples,1);
        ds.sa.subject=k*ones(ns,1);

        [i,j]=find(triu(repmat(1:nd,nd,1)',1)');

        ds.sa.targets1=i;
        ds.sa.targets2=j;
        faces={'f1','f2','f3','f4','f5','f6'};
        ds.a.sdim.values={faces,faces};
        ds.a.sdim.labels={'targets1','targets2'};

        ds_all{k}=ds;
    end

    ds=cosmo_stack(ds_all);
    ds=cosmo_stack({ds,ds,ds},2);

    cosmo_check_dataset(ds);

    opt=struct();
    opt.split_by='subject';
    opt.return='crossproduct';
    res=cosmo_distatis(ds,opt);

    % note: S_{[+]}[6,2] is reported as -0.01, should be -.100
    s= [.176 .004 -.058 .014 -.100 -.036
        .004 .178 .022 -.038 -.068 -.100
        -.058 .022 .579 -.243 -.186 -.115
        .014 -.038 -.243 .240 .054 -.027
        -.100 -.068 -.186 .054 .266 .034
        -.036 -.100 -.115 -.027 .034 .243];

    u=cosmo_unflatten(res,1);

    assertElementsAlmostEqual(repmat(s,[1,1,3]),u,'absolute',.001);
    assertElementsAlmostEqual(res.fa.quality(2),.6551,'absolute',.001)

    opt.return='distance';
    opt.shape='square';
    res=cosmo_distatis(ds,opt);
    u=cosmo_unflatten(res,1);
    sq=cosmo_squareform(u(:,:,1));
    assertElementsAlmostEqual(sq,[0.3452    0.8710    0.3888    0.6419 ...
                                  0.4911    0.7112    0.4919    0.5789 ...
                                  0.6203    1.3049    1.2163    1.0512 ...
                                  0.3996  0.5354 0.4400],'absolute',.001);
    opt.shape='triangle';
    resvec=cosmo_distatis(ds,opt);
    assertElementsAlmostEqual(resvec.samples(:,1),sq');




