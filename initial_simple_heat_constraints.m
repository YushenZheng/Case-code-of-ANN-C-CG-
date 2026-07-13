%% Initialize the indices for simple heat constraints
index_con_heat_balance = zeros(1,nPrd);
index_con_heat_balance(:) = nEq+1:nEq+nPrd;
nEq = nEq + nPrd;