%% Define constraints for DHS operation
%% heat supply aggregation
for i=1:nChpplant
    index_chp = find(dhs.chp(:,CHP_PLANT)==i);
    node = dhs.chpplant(i,CHPPLANT_NODE);
    pipe = find(dhs.pipe(:,PIPE_FROM)==dhs.chpplant(i,CHPPLANT_NODE) | dhs.pipe(:,PIPE_TO)==dhs.chpplant(i,CHPPLANT_NODE) );
    for t=1:nPrd
        Aeq(index_con_hssum(i,t),index_var_qchp(index_chp,t)) = 1;     %未合
        Aeq(index_con_hssum(i,t),index_var_ugt(index_chp2gen(index_chp),t)) = dhs.chp(index_chp,CHP_HMIN);     %未合
        Aeq(index_con_hssum(i,t),index_var_qchpplant(i,t)) = -1;     %合
        beq(index_con_hssum(i,t)) = 0;
    end
end

%% heat supply constraints
% for i=1:nChpplant
%     index_chp = find(dhs.chp(:,CHP_PLANT)==i);
%     node = dhs.chpplant(i,CHPPLANT_NODE);
%     pipe = find(dhs.pipe(:,PIPE_FROM)==dhs.chpplant(i,CHPPLANT_NODE) | dhs.pipe(:,PIPE_TO)==dhs.chpplant(i,CHPPLANT_NODE) );
%     for t=1:nPrd
%         Aeq(index_con_hs(i,t),index_var_qchp(index_chp,t)) = 1;     %未合
%         Aeq(index_con_hs(i,t),index_var_ugt(index_chp2gen(index_chp),t)) = dhs.chp(index_chp,CHP_HMIN);     %未合
% %         Aeq(index_con_hs(i,t),index_var_tns(node,t)) = -dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base;
% %         Aeq(index_con_hs(i,t),index_var_tnr(node,t)) = dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base;
%         Aeq(index_con_hs(i,t),index_var_tgs(i,t)) = -dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base; %合过的温度
%         Aeq(index_con_hs(i,t),index_var_tgr(i,t)) = dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base;  %合过的温度
%         beq(index_con_hs(i,t)) = 0;
%     end
% end

% % 矩阵
% for t=1:nPrd
%     Aeq(index_con_hs(:,t),index_var_tgs(:,t)) = -dhs.water_c*MG/dhs.base; %合过的温度
%     Aeq(index_con_hs(:,t),index_var_tgr(:,t)) = dhs.water_c*MG/dhs.base;  %合过的温度
%     Aeq(index_con_hs(:,t),index_var_qchpplant(:,t)) = eye(nChpplant);
%     beq(index_con_hs(:,t)) = 0;
% end

% 全矩阵     %Matrix Formulation 等值论文
Aeq(index_con_hs(:),index_var_tgs(:)) = -dhs.water_c*MGT; %合过的温度
Aeq(index_con_hs(:),index_var_tgr(:)) = dhs.water_c*MGT;  %合过的温度
Aeq(index_con_hs(:),index_var_qchpplant(:)) = eye(nChpplant*nPrd);
beq(index_con_hs(:)) = 0;



%% heat load constraints
% 松散
% for i=1:nLoad
%     node = index_load_new2old(i);
%     pipe = find(dhs.pipe(:,PIPE_FROM)==node | dhs.pipe(:,PIPE_TO)==node);    
%     for t=1:nPrd
% %         Aeq(index_con_hes(i,t),index_var_tns(node,t)) = dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base;
% %         Aeq(index_con_hes(i,t),index_var_tnr(node,t)) = -dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base;
%         Aeq(index_con_hes(i,t),index_var_tds(i,t)) = dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base;
%         Aeq(index_con_hes(i,t),index_var_tdr(i,t)) = -dhs.water_c*dhs.pipe(pipe,PIPE_FLOWRATE)/dhs.base;
%         beq(index_con_hes(i,t)) = dhs.node(node,NODE_LD)*dhs.loadrate(t);   %时变的d
%     end
% end

% %矩阵
% for t=1:nPrd
%     Aeq(index_con_hes(:,t),index_var_tds(:,t)) = dhs.water_c*MD/dhs.base;
%     Aeq(index_con_hes(:,t),index_var_tdr(:,t)) = -dhs.water_c*MD/dhs.base;
%     beq(index_con_hes(:,t)) = dhs.node(index_load_new2old,NODE_LD)*dhs.loadrate(t);   %时变的d
% end

%全矩阵
Aeq(index_con_hes(:),index_var_tds(:)) = dhs.water_c*MDT;
Aeq(index_con_hes(:),index_var_tdr(:)) = -dhs.water_c*MDT;
beq(index_con_hes(:)) = dT;   %时变的d

% %temperature mixing constraints
% temp_neg = im_pipe_neg.*(ones(nNode,1)*dhs.pipe(:,PIPE_FLOWRATE)');
% % 同我的版本 temp_neg = sparse(im_pipe_neg*diag(dhs.pipe(:,PIPE_FLOWRATE)));
% temp_pos = im_pipe_pos.*(ones(nNode,1)*dhs.pipe(:,PIPE_FLOWRATE)');

% for t=1:nPrd
%     Aeq(index_con_tns(:,t),index_var_tbsout(:,t)) = temp_neg;
%     Aeq(index_con_tns(:,t),index_var_tns(:,t)) = -diag(sum(temp_neg,2));
%     beq(index_con_tns(:,t)) = 0;
    
%     Aeq(index_con_tnr(:,t),index_var_tbrout(:,t)) = temp_pos;
%     Aeq(index_con_tnr(:,t),index_var_tnr(:,t)) = -diag(sum(temp_pos,2));
%     beq(index_con_tnr(:,t)) = 0;
% end

%% temperature mixing constraints 基于分布因子的版本
% for t=1:nPrd
%     Aeq(index_con_tns(:,t),index_var_tbsout(:,t)) = im_pipe_neg*DPS;
%     Aeq(index_con_tns(:,t),index_var_tgs(:,t)) = im_chp*DGS;
%     Aeq(index_con_tns(:,t),index_var_tns(:,t)) = -eye(nNode);
%     beq(index_con_tns(:,t)) = 0;
%     
%     Aeq(index_con_tnr(:,t),index_var_tbrout(:,t)) = im_pipe_pos*DPR;
%     Aeq(index_con_tnr(:,t),index_var_tdr(:,t)) = im_load*DDR;
%     Aeq(index_con_tnr(:,t),index_var_tnr(:,t)) = -eye(nNode);
%     beq(index_con_tnr(:,t)) = 0;
% end

%全矩阵
Aeq(index_con_tns(:),index_var_tbsout(:)) = As_neg*DPST;
Aeq(index_con_tns(:),index_var_tgs(:)) = Ag*DGST;
Aeq(index_con_tns(:),index_var_tns(:)) = -speye(nNode*nPrd);
beq(index_con_tns(:)) = 0;

Aeq(index_con_tnr(:),index_var_tbrout(:)) = Ar_neg*DPRT;
Aeq(index_con_tnr(:),index_var_tdr(:)) = Ad*DDRT;
Aeq(index_con_tnr(:),index_var_tnr(:)) = -eye(nNode*nPrd);
beq(index_con_tnr(:)) = 0;

%% outlet equation
% for t=1:nPrd
%     Aeq(index_con_tbsin(:,t),index_var_tns(:,t)) = -im_pipe_pos';
%     Aeq(index_con_tbsin(:,t),index_var_tbsin(:,t)) = speye(nPipe);
%     beq(index_con_tbsin(:,t)) = 0;
%     
%     Aeq(index_con_tbrin(:,t),index_var_tnr(:,t)) = -im_pipe_neg';
%     Aeq(index_con_tbrin(:,t),index_var_tbrin(:,t)) = speye(nPipe);
%     beq(index_con_tbrin(:,t)) = 0;
% end

%全矩阵
Aeq(index_con_tbsin(:),index_var_tns(:)) = -As_pos';
Aeq(index_con_tbsin(:),index_var_tbsin(:)) = speye(nPipe*nPrd);
beq(index_con_tbsin(:)) = 0;

Aeq(index_con_tbrin(:),index_var_tnr(:)) = -Ar_pos';
Aeq(index_con_tbrin(:),index_var_tbrin(:)) = speye(nPipe*nPrd);
beq(index_con_tbrin(:)) = 0;

% Aeq(index_con_tbsin(:),index_var_tns(:)) = -im_pipe_pos';
% Aeq(index_con_tbsin(:),index_var_tbsin(:)) = speye(nPipe);
% beq(index_con_tbsin(:)) = 0;

%% outlet generation and load
% for t=1:nPrd
%     Aeq(index_con_tgr(:,t),index_var_tnr(:,t)) = im_chp';
%     Aeq(index_con_tgr(:,t),index_var_tgr(:,t)) = -speye(nChpplant);
%     beq(index_con_tgr(:,t)) = 0;
%     
%     Aeq(index_con_tds(:,t),index_var_tns(:,t)) = im_load';
%     Aeq(index_con_tds(:,t),index_var_tds(:,t)) = -speye(nLoad);
%     beq(index_con_tds(:,t)) = 0;
% end

%全矩阵
Aeq(index_con_tgr(:),index_var_tnr(:)) = Ag';
Aeq(index_con_tgr(:),index_var_tgr(:)) = -speye(nChpplant*nPrd);
beq(index_con_tgr(:)) = 0;

Aeq(index_con_tds(:),index_var_tns(:)) = Ad';
Aeq(index_con_tds(:),index_var_tds(:)) = -speye(nLoad*nPrd);
beq(index_con_tds(:)) = 0;


%% heat losses in pipeline network
%%%%%%%%%%%Aug 25看到这里WC
% for t=1:nPrd
%     for p=1:nPipe
%         temp = ttr(ttr_map(p,t),:);
%         temp1 = fliplr(temp(1:t));
%         temp2 = fliplr(temp(t+1:nPrd0));
% %         Aeq(index_con_tbsout(p,t),index_var_tbsout(p,t)) = 1;
% %         Aeq(index_con_tbsout(p,t),index_var_tbsin(p,1:t)) = -JJ(p,t)*temp1;
% %         beq(index_con_tbsout(p,t)) = (1-JJ(p,t))*dhs.t0(t) + JJ(p,t)*temp2*tbsin0(p,t+1:nPrd0)';
%         
%         Aeq(index_con_tbrout(p,t),index_var_tbrout(p,t)) = 1;
%         Aeq(index_con_tbrout(p,t),index_var_tbrin(p,1:t)) = -JJ(p,t)*temp1;
%         beq(index_con_tbrout(p,t)) = (1-JJ(p,t))*dhs.t0(t) + JJ(p,t)*temp2*tbrin0(p,t+1:nPrd0)';
%     end
% end

Aeq(index_con_tbsout(:),index_var_tbsout(:)) = speye(nPrd*nPipe);
Aeq(index_con_tbsout(:),index_var_tbsin(:)) = -Phi;
beq(index_con_tbsout(:)) = t_PS_A;
Aeq(index_con_tbrout(:),index_var_tbrout(:)) = speye(nPrd*nPipe);
Aeq(index_con_tbrout(:),index_var_tbrin(:)) = -Phi;
beq(index_con_tbrout(:)) = t_PR_A;