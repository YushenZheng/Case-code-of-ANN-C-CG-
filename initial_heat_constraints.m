%% initialize indices for heat constraints
% heat supply aggregation
index_con_hssum = zeros(nChpplant,nPrd);
index_con_hssum(:) = nEq+1:nEq+nChpplant*nPrd;
nEq = nEq + nChpplant*nPrd;

% heat supply constraints
index_con_hs = zeros(nChpplant,nPrd);
index_con_hs(:) = nEq+1:nEq+nChpplant*nPrd;
nEq = nEq + nChpplant*nPrd;

% heat load constraints
index_con_hes = zeros(nLoad,nPrd);
index_con_hes(:) = nEq+1:nEq+nLoad*nPrd;
nEq = nEq + nLoad*nPrd;

% temperature mixing constraints
index_con_tns = zeros(nNode,nPrd);
index_con_tns(:) = nEq+1:nEq+nNode*nPrd;
nEq = nEq + nNode*nPrd;

index_con_tnr = zeros(nNode,nPrd);
index_con_tnr(:) = nEq+1:nEq+nNode*nPrd;
nEq = nEq + nNode*nPrd;

index_con_tbsin = zeros(nPipe,nPrd);
index_con_tbsin(:) = nEq+1:nEq+nPipe*nPrd;
nEq = nEq + nPipe*nPrd;

index_con_tbrin = zeros(nPipe,nPrd);
index_con_tbrin(:) = nEq+1:nEq+nPipe*nPrd;
nEq = nEq + nPipe*nPrd;

index_con_tbsout = zeros(nPipe,nPrd);
index_con_tbsout(:) = nEq+1:nEq+nPipe*nPrd;
nEq = nEq + nPipe*nPrd;

index_con_tbrout = zeros(nPipe,nPrd);
index_con_tbrout(:) = nEq+1:nEq+nPipe*nPrd;
nEq = nEq + nPipe*nPrd;

index_con_tgr = zeros(nChpplant,nPrd);
index_con_tgr(:) = nEq+1:nEq+nChpplant*nPrd;
nEq = nEq + nChpplant*nPrd;

index_con_tds = zeros(nLoad,nPrd);
index_con_tds(:) = nEq+1:nEq+nLoad*nPrd;
nEq = nEq + nLoad*nPrd;