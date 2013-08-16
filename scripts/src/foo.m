
ntest=10;
counts=floor(rand(3,10)*3)+1;
[mx,i]=max(counts);
msk=bsxfun(@minus,mx,counts)==0;

counts(~msk)=0;
mxcount=sum(counts>0,1);
mxpos=floor(mxcount.*rand(1,ntest))+1;