index_var_a = zeros(nBus,nPrd);
index_var_a(:) = nVar+1:nVar+nBus*nPrd;
nVar = nVar + nBus*nPrd;