% 包括风电出力的机组出力向量
index_var_pg = zeros(nGen,nPrd);
index_var_pg(:) = nVar+1:nVar+nGen*nPrd;
nVar = nVar + nGen*nPrd;

% commitment variables
index_var_ugt = zeros(nGen,nPrd);
index_var_ugt(:) = nVar+1:nVar+nGen*nPrd;
nVar = nVar + nGen*nPrd;

% startup variables
index_var_xgt = zeros(nGen,nPrd);
index_var_xgt(:) = nVar+1:nVar+nGen*nPrd;
nVar = nVar + nGen*nPrd;

% shutdown variables
index_var_ygt = zeros(nGen,nPrd);
index_var_ygt(:) = nVar+1:nVar+nGen*nPrd;
nVar = nVar + nGen*nPrd;

% 上旋备
index_var_ru = zeros(nGen,nPrd);
index_var_ru(:) = nVar+1:nVar+nGen*nPrd;
nVar = nVar + nGen*nPrd;

% 下旋备
index_var_rd = zeros(nGen,nPrd);
index_var_rd(:) = nVar+1:nVar+nGen*nPrd;
nVar = nVar + nGen*nPrd;

% heat output of CHP
index_var_qchp = zeros(nChp,nPrd);
index_var_qchp(:) = nVar+1:nVar+nChp*nPrd;
nVar = nVar + nChp*nPrd;

% convex combination of feasible extreme points
index_var_achp = zeros(nChp,nPrd,max(dhs.chppt(:,CHPPT_NPT)));
for i=1:nChp
    for t=1:nPrd
        for j=1:dhs.chppt(i,CHPPT_NPT)
            nVar = nVar + 1;
            index_var_achp(i,t,j) = nVar;
        end
    end
end

% piecewise generation output
index_var_pgpw = zeros(nNonchp,nPrd,nSeg);
index_var_pgpw(:) = nVar+1:nVar+nNonchp*nPrd*nSeg;
nVar = nVar + nNonchp*nPrd*nSeg;