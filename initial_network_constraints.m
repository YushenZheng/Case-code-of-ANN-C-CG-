%% initialize indices for network constraints
% nodal flow equations
index_con_node = zeros(nBus,nPrd);
index_con_node(:) = nEq+1:nEq+nBus*nPrd;
nEq = nEq + nBus*nPrd;

% network constraints
index_con_networkPos = zeros(nBranch,nPrd);
index_con_networkPos(:) = nIneq+1:nIneq+nBranch*nPrd;
nIneq = nIneq + nBranch*nPrd;

index_con_networkNeg = zeros(nBranch,nPrd);
index_con_networkNeg(:) = nIneq+1:nIneq+nBranch*nPrd;
nIneq = nIneq + nBranch*nPrd;