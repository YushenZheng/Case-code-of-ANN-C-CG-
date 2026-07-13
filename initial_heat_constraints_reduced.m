%% initialize indices for heat constraints
%% 取决于define_heat_bounds.m中有哪些上下界

% heat supply aggregation
index_con_hssum = zeros(nChpplant,nPrd);
index_con_hssum(:) = nEqEM+1:nEqEM+nChpplant*nPrd;
nEqEM = nEqEM + nChpplant*nPrd;

% connect heat supply and tgs
index_con_tgs = zeros(nChpplant,nPrd);
index_con_tgs(:) = nEqEM+1:nEqEM+nChpplant*nPrd;
nEqEM = nEqEM + nChpplant*nPrd;

% tns upper bound
index_con_tns_max = zeros(nNode, nPrd);
index_con_tns_max(:) = nIneqEM+1:nIneqEM+nNode*nPrd;
nIneqEM = nIneqEM + nNode*nPrd;

% tns lower bound
index_con_tns_min = zeros(nNode, nPrd);
index_con_tns_min(:) = nIneqEM+1:nIneqEM+nNode*nPrd;
nIneqEM = nIneqEM + nNode*nPrd;

% tnr upper bound
index_con_tnr_max = zeros(nNode, nPrd);
index_con_tnr_max(:) = nIneqEM+1:nIneqEM+nNode*nPrd;
nIneqEM = nIneqEM + nNode*nPrd;

% tnr lower bound
index_con_tnr_min = zeros(nNode, nPrd);
index_con_tnr_min(:) = nIneqEM+1:nIneqEM+nNode*nPrd;
nIneqEM = nIneqEM + nNode*nPrd;