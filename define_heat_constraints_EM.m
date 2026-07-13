%% heat supply aggregation
for i=1:nChpplant
    index_chp = find(dhs.chp(:,CHP_PLANT)==i);
%     node = dhs.chpplant(i,CHPPLANT_NODE);
%     pipe = find(dhs.pipe(:,PIPE_FROM)==dhs.chpplant(i,CHPPLANT_NODE) | dhs.pipe(:,PIPE_TO)==dhs.chpplant(i,CHPPLANT_NODE) );
    for t=1:nPrd
        AeqEM(index_con_hssum(i,t),index_var_qchp(index_chp,t)) = 1;     %Î´ºÏ
        AeqEM(index_con_hssum(i,t),index_var_ugt(index_chp2gen(index_chp),t)) = dhs.chp(index_chp,CHP_HMIN);     %Î´ºÏ
        AeqEM(index_con_hssum(i,t),index_var_qchpplant(i,t)) = -1;     %ºÏ
        beqEM(index_con_hssum(i,t)) = 0;
    end
end

%% connect heat supply and tgs
AeqEM(index_con_tgs(:),index_var_tgs(:)) = -Y_g_GS;
AeqEM(index_con_tgs(:),index_var_qchpplant(:)) = speye(nChpplant*nPrd);
beqEM(index_con_tgs(:)) = Y_g_d*dT+g_hat;

% tns upper bound: Y_NS_GS*tgs+t_NS_GS <= TSMAX
AineqEM(index_con_tns_max(:),index_var_tgs(:)) = Y_NS_GS;
bineqEM(index_con_tns_max(:)) = kron(ones(nPrd,1),dhs.node(:,NODE_TSMAX)) - t_NS_GS;

% tns lower bound: TSMIN <= Y_NS_GS*tgs+t_NS_GS ---> -Y_NS_GS*tgs <= t_NS_GS-TSMIN
AineqEM(index_con_tns_min(:),index_var_tgs(:)) = -Y_NS_GS;
bineqEM(index_con_tns_min(:)) = t_NS_GS - kron(ones(nPrd,1),dhs.node(:,NODE_TSMIN));

% tnr upper bound: Y_NR_GS*tgs+Y_NR_d*d+t_NR_GS <= TRMAX ---> Y_NR_GS*tgs <= TRMAX - Y_NR_d*d - t_NR_GS
AineqEM(index_con_tnr_max(:),index_var_tgs(:)) = Y_NR_GS;
bineqEM(index_con_tnr_max(:)) = kron(ones(nPrd,1),dhs.node(:,NODE_TRMAX)) - Y_NR_d*dT - t_NR_GS;
% 
% tnr lower bound: TRMIN <= Y_NR_GS*tgs+Y_NR_d*d+t_NR_GS ---> -Y_NR_GS*tgs <= Y_NR_d*d+t_NR_GS-TRMIN
AineqEM(index_con_tnr_min(:),index_var_tgs(:)) = -Y_NR_GS;
bineqEM(index_con_tnr_min(:)) = Y_NR_d*dT + t_NR_GS - kron(ones(nPrd,1),dhs.node(:,NODE_TRMIN));