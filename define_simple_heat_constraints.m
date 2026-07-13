% %% Define constraints for simple heat operation
% for t=1:nPrd
%     Aeq(index_con_heat_balance(t),index_var_qchp(:,t)) = 1;
%     Aeq(index_con_heat_balance(t),index_var_ugt(index_chp2gen,t)) = dhs.chp(:,CHP_HMIN);
%     beq(index_con_heat_balance(t)) = dhs.load(t);
% end

% heat supply constraints
for i=1:nChpplant
    index_chp = find(dhs.chp(:,CHP_PLANT)==i);
    node = dhs.chpplant(i,CHPPLANT_NODE);
    pipe = find(dhs.pipe(:,PIPE_FROM)==dhs.chpplant(i,CHPPLANT_NODE) | dhs.pipe(:,PIPE_TO)==dhs.chpplant(i,CHPPLANT_NODE) );
    for t=1:nPrd
        Aeq(index_con_hs(i,t),index_var_qchp(index_chp,t)) = 1;
        Aeq(index_con_hs(i,t),index_var_ugt(index_chp2gen(index_chp),t)) = dhs.chp(index_chp,CHP_HMIN);
        Aeq(index_con_hs(i,t),index_var_tns(node,t)) = -dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base;
        Aeq(index_con_hs(i,t),index_var_tnr(node,t)) = dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base;
        beq(index_con_hs(i,t)) = 0;
    end
end

% heat load constraints
for i=1:nLoad
    node = index_load_new2old(i);
    pipe = find(dhs.pipe(:,PIPE_FROM)==node | dhs.pipe(:,PIPE_TO)==node);    
    for t=1:nPrd
        Aeq(index_con_hes(i,t),index_var_tns(node,t)) = dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base;
        Aeq(index_con_hes(i,t),index_var_tnr(node,t)) = -dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base;
        beq(index_con_hes(i,t)) = dhs.node(node,NODE_LD)*dhs.loadrate(t);
    end
end

% temperature mixing constraints
temp_neg = im_pipe_neg.*(ones(nNode,1)*dhs.pipe(:,PIPE_FLOWRATE)');
temp_pos = im_pipe_pos.*(ones(nNode,1)*dhs.pipe(:,PIPE_FLOWRATE)');
for t=1:nPrd
    Aeq(index_con_tns(:,t),index_var_tbsout(:,t)) = temp_neg;
    Aeq(index_con_tns(:,t),index_var_tns(:,t)) = -diag(sum(temp_neg,2));
    beq(index_con_tns(:,t)) = 0;
    
    Aeq(index_con_tnr(:,t),index_var_tbrout(:,t)) = temp_pos;
    Aeq(index_con_tnr(:,t),index_var_tnr(:,t)) = -diag(sum(temp_pos,2));
    beq(index_con_tnr(:,t)) = 0;
end

for t=1:nPrd
    Aeq(index_con_tbsin(:,t),index_var_tns(:,t)) = -im_pipe_pos';
    Aeq(index_con_tbsin(:,t),index_var_tbsin(:,t)) = speye(nPipe);
    beq(index_con_tbsin(:,t)) = 0;
    
    Aeq(index_con_tbrin(:,t),index_var_tnr(:,t)) = -im_pipe_neg';
    Aeq(index_con_tbrin(:,t),index_var_tbrin(:,t)) = speye(nPipe);
    beq(index_con_tbrin(:,t)) = 0;
end

for t=1:nPrd
    for p=1:nPipe
        temp = ttr(ttr_map(p,t),:);
        temp1 = fliplr(temp(1:t));
        temp2 = fliplr(temp(t+1:nPrd0));
        Aeq(index_con_tbsout(p,t),index_var_tbsout(p,t)) = 1;
        Aeq(index_con_tbsout(p,t),index_var_tbsin(p,t)) = -1;
        beq(index_con_tbsout(p,t)) = 0;
        
        Aeq(index_con_tbrout(p,t),index_var_tbrout(p,t)) = 1;
        Aeq(index_con_tbrout(p,t),index_var_tbrin(p,t)) = -1;
        beq(index_con_tbrout(p,t)) = 0;
    end
end

temp = temp;