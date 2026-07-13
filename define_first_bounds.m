%% Define bounds for first-stage varaibles
% 包括风电出力的机组出力向量
lb(index_var_pg) = -Inf;
ub(index_var_pg) = Inf;

% for wind farm
ub(index_var_pg(index_wind2gen,:)) = mpc.windexp(:,2:nPrd+1);  %WC: 应为预测值
% if delta_rate_wind < eps || budget_pct_wind < eps
%     lb(index_var_pg(index_wind2gen,:)) = ub(index_var_pg(index_wind2gen,:));   %deterministic
% else
    lb(index_var_pg(index_wind2gen,:)) = 0;
% end

% commitment variables 
lb(index_var_ugt) = 0;
ub(index_var_ugt) = 1;
vtype(index_var_ugt) = 'b';

% for wind farm
lb(index_var_ugt(index_wind2gen,:)) = 1;
vtype(index_var_ugt(index_wind2gen,:)) = 'c';

% startup variables
lb(index_var_xgt) = 0;
ub(index_var_xgt) = 1;

% shutdown variables
lb(index_var_ygt) = 0;
ub(index_var_ygt) = 1;

% 上旋备
lb(index_var_ru) = 0;
ub(index_var_ru) = mpc.gen(:,RAMP_AGC)*ones(1,nPrd);

% no reserve is provded by wind farm or CHP
ub(index_var_ru(index_wind2gen,:)) = 0;
ub(index_var_ru(index_chp2gen,:)) = 0;

% 下旋备
lb(index_var_rd) = 0;
ub(index_var_rd) = mpc.gen(:,RAMP_AGC)*ones(1,nPrd);
ub(index_var_rd(index_wind2gen,:)) = 0;
ub(index_var_rd(index_chp2gen,:)) = 0;

% heat output of CHP
lb(index_var_qchp) = -Inf;
ub(index_var_qchp) = Inf;

% convex combination of feasible extreme points
for i=1:nChp
    for t=1:nPrd
        lb(index_var_achp(i,t,1:dhs.chppt(i,CHPPT_NPT))) = 0;
        ub(index_var_achp(i,t,1:dhs.chppt(i,CHPPT_NPT))) = 1;
    end
end

% piecewise generation output
for i=1:nNonchp
    for t=1:nPrd
        lb(index_var_pgpw(i,t,:)) = 0;
        ub(index_var_pgpw(i,t,:)) = mpc.gencost_pw(index_nonchp2gen(i),1);
    end
end