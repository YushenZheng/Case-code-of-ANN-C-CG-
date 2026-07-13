% 合并后的热源总出力
index_var_qchpplant = zeros(nChpplant, nPrd); 
index_var_qchpplant(:) = nVar+1:nVar+nChpplant*nPrd;
nVar = nVar + nChpplant*nPrd;

% 热源供水端温度  %wc: 合并的，外层是时间，内层是CHP
index_var_tgs = zeros(nChpplant,nPrd);
index_var_tgs(:) = nVar+1:nVar+nChpplant*nPrd;
nVar = nVar + nChpplant*nPrd;