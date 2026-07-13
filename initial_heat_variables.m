% 注意：对于供水网，管道首末端与定义一直；对于回水网，管道首末端与定义相反
index_var_tbsin = zeros(nPipe, nPrd); % 供水管首端温度
index_var_tbrin = zeros(nPipe, nPrd); % 回水管首端温度
index_var_tbsout = zeros(nPipe, nPrd); % 供水管末端温度
index_var_tbrout = zeros(nPipe, nPrd); % 回水管末端温度

index_var_tns = zeros(nNode, nPrd); % 供水管节点流出温度   %%混合温度
index_var_tnr = zeros(nNode, nPrd); % 回水管节点流出温度

%热源的供水端温度,合并后的热源总出力 在initial_first_variables.m里 % added by wc

% 合并后的热源总出力
index_var_qchpplant = zeros(nChpplant, nPrd); 
index_var_qchpplant(:) = nVar+1:nVar+nChpplant*nPrd;
nVar = nVar + nChpplant*nPrd;

% 热源供水端温度  %wc: 合并的，外层是时间，内层是CHP
index_var_tgs = zeros(nChpplant,nPrd);
index_var_tgs(:) = nVar+1:nVar+nChpplant*nPrd;
nVar = nVar + nChpplant*nPrd;

% 热源回水端温度
index_var_tgr = zeros(nChpplant,nPrd);
index_var_tgr(:) = nVar+1:nVar+nChpplant*nPrd;
nVar = nVar + nChpplant*nPrd;

index_var_tds = zeros(nLoad, nPrd); % 热荷供水端温度（高温）   added by wc
index_var_tdr = zeros(nLoad, nPrd); % 热荷回水端温度（低温）   added by wc

index_var_tbsin(:) = nVar+1:nVar+nPipe*nPrd;
nVar = nVar + nPipe*nPrd;
index_var_tbrin(:) = nVar+1:nVar+nPipe*nPrd;
nVar = nVar + nPipe*nPrd;
index_var_tbsout(:) = nVar+1:nVar+nPipe*nPrd;
nVar = nVar + nPipe*nPrd;
index_var_tbrout(:) = nVar+1:nVar+nPipe*nPrd;
nVar = nVar + nPipe*nPrd;
index_var_tns(:) = nVar+1:nVar+nNode*nPrd;
nVar = nVar + nNode*nPrd;
index_var_tnr(:) = nVar+1:nVar+nNode*nPrd;
nVar = nVar + nNode*nPrd;
index_var_tds(:) = nVar+1:nVar+nLoad*nPrd;
nVar = nVar + nLoad*nPrd;
index_var_tdr(:) = nVar+1:nVar+nLoad*nPrd;
nVar = nVar + nLoad*nPrd;

% % 建立索引
% for t=1:nPrd
%     for p=1:nPipe
%         nVar = nVar + 1;
%         index_var_tbsin(p,t) = nVar;
%         
%         nVar = nVar + 1;
%         index_var_tbrin(p,t) = nVar;
%         
%         nVar = nVar + 1;
%         index_var_tbsout(p,t) = nVar;
%         
%         nVar = nVar + 1;
%         index_var_tbrout(p,t) = nVar;
%     end
%     
%     for i=1:nNode
%         nVar = nVar + 1;
%         index_var_tns(i,t) = nVar;
%         
%         nVar = nVar + 1;
%         index_var_tnr(i,t) = nVar;
%     end
%     
%     for i=1:nLoad
%         nVar = nVar + 1;
%         index_var_tds(i,t) = nVar;
%         
%         nVar = nVar + 1;
%         index_var_tdr(i,t) = nVar;
%     end
% end