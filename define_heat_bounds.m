%% Define variables bounds for DHS subproblems
% lb(index_var_tns(dhs.chpplant(:,CHPPLANT_NODE),:)) = dhs.node(dhs.chpplant(:,CHPPLANT_NODE),NODE_TSMIN)*ones(1,nPrd);
% ub(index_var_tns(dhs.chpplant(:,CHPPLANT_NODE),:)) = dhs.node(dhs.chpplant(:,CHPPLANT_NODE),NODE_TSMAX)*ones(1,nPrd);
% 
% lb(index_var_tns(index_load_new2old,:)) = dhs.node(index_load_new2old,NODE_TSMIN)*ones(1,nPrd);
% ub(index_var_tns(index_load_new2old,:)) = dhs.node(index_load_new2old,NODE_TSMAX)*ones(1,nPrd);

lb(index_var_tns(:,:)) = dhs.node(:,NODE_TSMIN)*ones(1,nPrd);
ub(index_var_tns(:,:)) = dhs.node(:,NODE_TSMAX)*ones(1,nPrd);

lb(index_var_tnr(:,:)) = dhs.node(:,NODE_TRMIN)*ones(1,nPrd);
ub(index_var_tnr(:,:)) = dhs.node(:,NODE_TRMAX)*ones(1,nPrd);