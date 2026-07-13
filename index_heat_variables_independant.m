function [index_var_tbsin, index_var_tbrin, index_var_tbsout, index_var_tbrout, index_var_tns, index_var_tnr] = index_heat_variables_independant(nNode, nPipe, nPrd, nVar0)
    % 注意：对于供水网，管道首末端与定义一直；对于回水网，管道首末端与定义相反
    index_var_tbsin = zeros(nPipe, nPrd); % 供水管首端温度
    index_var_tbrin = zeros(nPipe, nPrd); % 回水管首端温度
    index_var_tbsout = zeros(nPipe, nPrd); % 供水管末端温度
    index_var_tbrout = zeros(nPipe, nPrd); % 回水管末端温度

    index_var_tns = zeros(nNode, nPrd); % 供水管节点流出温度
    index_var_tnr = zeros(nNode, nPrd); % 回水管节点流出温度

    nVar = nVar0;
    % 建立索引
    for t=1:nPrd
        for p=1:nPipe
            nVar = nVar + 1;
            index_var_tbsin(p,t) = nVar;

            nVar = nVar + 1;
            index_var_tbrin(p,t) = nVar;

            nVar = nVar + 1;
            index_var_tbsout(p,t) = nVar;

            nVar = nVar + 1;
            index_var_tbrout(p,t) = nVar;
        end

        for i=1:nNode
            nVar = nVar + 1;
            index_var_tns(i,t) = nVar;

            nVar = nVar + 1;
            index_var_tnr(i,t) = nVar;
        end
    end
end