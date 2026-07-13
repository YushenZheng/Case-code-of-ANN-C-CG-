%% Define constraints for the network subproblems
% 1. nodal flow equations
[Bbus, Bf] = makeBdc(mpc.baseMVA,mpc.bus,mpc.branch);

for t=1:nPrd
    Aeq(index_con_node(:,t),index_var_a(:,t)) = Bbus;
    Aeq(index_con_node(:,t),index_var_pg(:,t)) = -im_gen;
    Aeq(index_con_node(:,t),index_var_ugt(:,t)) = -im_gen.*(ones(nBus,1)*mpc.gen(:,PMIN)');
    beq(index_con_node(:,t)) = -mpc.bus(:,PD).*mpc.loadrate1(:,t);
%     beq(index_con_node(:,t)) = -mpc.bus(:,PD)*mpc.loadrate(t);
end

% 2. network constraints
for t=1:nPrd
    Aineq(index_con_networkPos(:,t),index_var_a(:,t)) = Bf;
    bineq(index_con_networkPos(:,t)) = mpc.branch(:,RATE_A);
    
    Aineq(index_con_networkNeg(:,t),index_var_a(:,t)) = -Bf;
    bineq(index_con_networkNeg(:,t)) = mpc.branch(:,RATE_A);
end