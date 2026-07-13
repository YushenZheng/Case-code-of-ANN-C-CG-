idx_temp = 0;
% 风电容量
index_var_wind_max = zeros(nWind, nPrd); 
index_var_wind_max(:) = idx_temp+1:idx_temp+nWind*nPrd;
idx_temp = idx_temp + nWind*nPrd;

% 热负荷  %wc: 合并的，外层是时间，内层是CHP
index_var_heat_load = zeros(nLoad,nPrd);
index_var_heat_load(:) = idx_temp+1:idx_temp+nLoad*nPrd;
idx_temp = idx_temp + nLoad*nPrd;
nUvar = idx_temp;