%% 1. form the coefficient matrices
index_var_first = [index_var_ugt(:);index_var_xgt(:);index_var_ygt(:)];
index_var_second = setdiff((1:nHvar)',index_var_first);
%% index var u: 
% output: index_var_wind_max,index_var_heat_load,nUvar
initial_uncertain_variables;

%% Ax <= b
mat_A = [Aeq(index_con_logic(:),index_var_first);-Aeq(index_con_logic(:),index_var_first); ...
    Aineq(index_con_timeUp(:),index_var_first); ...
    Aineq(index_con_timeDn(:),index_var_first); ...
    speye(size(index_var_first,1)); ...
    -speye(size(index_var_first,1))];
vec_b = [beq(index_con_logic(:));-beq(index_con_logic(:)); ...
    bineq(index_con_timeUp(:)); ...
    bineq(index_con_timeDn(:)); ...
    ub(index_var_first); ...
    -lb(index_var_first)];
vtype_x0 = vtype(index_var_first);

%% Bx + Cu + Dy <= e
index_con_Beq = setdiff((1:nHeq)',index_con_logic(:));
index_con_Bineq = setdiff((1:nHineq)',[index_con_timeUp(:);index_con_timeDn(:)]);
mat_B = [AeqEM(:, index_var_first);-AeqEM(:, index_var_first);
    Aeq(index_con_Beq,index_var_first);-Aeq(index_con_Beq,index_var_first);    
    Aineq(index_con_Bineq,index_var_first);
    AineqEM(:, index_var_first);
    sparse(size(index_var_second,1),size(index_var_first,1));
    sparse(size(index_var_second,1),size(index_var_first,1));
    ];
mat_D = [AeqEM(:, index_var_second);-AeqEM(:, index_var_second);
    Aeq(index_con_Beq,index_var_second);-Aeq(index_con_Beq,index_var_second);    
    Aineq(index_con_Bineq,index_var_second);
    AineqEM(:, index_var_second);
    speye(size(index_var_second,1));
    -speye(size(index_var_second,1));
    ];
vec_e = [beqEM;-beqEM;
    beq(index_con_Beq);-beq(index_con_Beq);    
    bineq(index_con_Bineq)
    bineqEM;
    ub(index_var_second);
    -lb(index_var_second);
    ];
%% generate C
mat_C = sparse(size(mat_B,1),nUvar);
u0 = zeros(nUvar, 1);  %原来define cons的时候，是Bx + Dy <= e-Cu的形式，此处须两边同时加Cu，u为参数
u0(index_var_heat_load(:)) = dT;
% heat load (AeqEM): g-Y_G_GS*tgs <= Y_G_D*d+g_hat
row_heat_load = reshape(index_con_tgs(:), nChpplant*nPrd, 1);
mat_C(row_heat_load, index_var_heat_load(:)) = -Y_g_d;
% heat load (AeqEM): -(g-Y_G_GS*tgs) <= -Y_G_D*d-g_hat
mat_C(size(AeqEM,1)+row_heat_load, index_var_heat_load(:)) = Y_g_d;
offset_con_AeqEM = 2*size(AeqEM,1)+2*size(index_con_Beq,1)+size(index_con_Bineq,1);
% tnr upper bound (AineqEM): Y_NR_GS*tgs <= TRMAX - Y_NR_d*d - t_NR_GS
mat_C(offset_con_AeqEM+index_con_tnr_max(:), index_var_heat_load(:)) = Y_NR_d;
% tnr lower bound (AineqEM): TRMIN <= Y_NR_GS*tgs+Y_NR_d*d+t_NR_GS ---> -Y_NR_GS*tgs <= Y_NR_d*d+t_NR_GS-TRMIN
mat_C(offset_con_AeqEM+index_con_tnr_min(:), index_var_heat_load(:)) = -Y_NR_d;

% wind (在lb,ub里) 
u0(index_var_wind_max(:)) = reshape(ub(index_var_pg(index_wind2gen,:)),nWind*nPrd,1);
row_wind_max = reshape(index_var_pg(index_wind2gen,:),nWind*nPrd,1);
% 原约束：pwg <=pwg_max，要变为:D*pwg-I*pwg_max <= 0
offset_con_ub = 2*size(index_con_Beq,1)+size(index_con_Bineq,1)+2*size(AeqEM,1)+size(AineqEM,1);
mat_C(offset_con_ub+row_wind_max,index_var_wind_max(:)) = -speye(nWind*nPrd);   %%---------pwg-pwg_max <=0
% if delta_rate_wind < eps || budget_pct_wind < eps %%without considering uncertainties of wind, then set the wind as max, add -pwg <=-pwg_max
%     % 注意：不考虑风的不确定性时，风机下界已设为容量极值
%     % 风电机组出力，var index是排在最前面的，因此在index_var_second中也在最前面，无需做偏移
%     % 原约束：-I*pwg <= -pwg_max, 变为:-I*pwg + pwg_max <= 0
%     offset_con_lb = offset_con_ub+size(index_var_second,1);
%     mat_C(offset_con_lb+row_wind_max,index_var_wind_max(:)) = speye(nWind*nPrd);
%     ------------------   pwg+pwg_max >=0
% end
vec_e = vec_e + mat_C*u0;
vec_e = max(min(vec_e,vec_e_cut),-vec_e_cut); % to prevent Inf;

%% F*u <= f
mat_F = sparse(0,nUvar);
vec_f = zeros(0,1);

%% G*(z_pos+z_neg) <= h
const_gamma_wind = ceil(nPrd*budget_pct_wind); %/4 for jilin 每台风机
const_pi_wind = ceil(nWind*budget_pct_wind);   %每个时段所有风机
const_gamma_hl = ceil(nPrd*budget_pct_hl);
const_pi_hl = ceil(nLoad*budget_pct_hl);
% indexing constraints
row_wind_g = [1:nWind]';
row_wind_t = row_wind_g(end)+[1:nPrd]';
row_heat_d = row_wind_t(end)+[1:nLoad]';
row_heat_t = row_heat_d(end)+[1:nPrd]';
row_G = numel([row_wind_g;row_wind_t;row_heat_d;row_heat_t]);
mat_G = sparse(row_G,nUvar);
vec_h = zeros(row_G,1);
for i=1:nWind
    mat_G(row_wind_g(i),index_var_wind_max(i,:)) = 1;
    vec_h(row_wind_g(i)) = const_gamma_wind;
end
for t=1:nPrd
    mat_G(row_wind_t(t),index_var_wind_max(:,t)) = 1;
    vec_h(row_wind_t(t)) = const_pi_wind;
end
for i=1:nLoad
    mat_G(row_heat_d(i),index_var_heat_load(i,:)) = 1;
    vec_h(row_heat_d(i)) = const_gamma_hl;
end
for t=1:nPrd
    mat_G(row_heat_t(t),index_var_heat_load(:,t)) = 1;
    vec_h(row_heat_t(t)) = const_pi_hl;
end

%% obj
vec_c = f(index_var_first);
vec_d = f(index_var_second);
vec_g = zeros(nUvar,1);
vec_g(index_var_wind_max(:)) = mpc.windpen;
vec_u0 = u0;
vec_du_pos=0*u0; vec_du_neg=0*u0;
vec_du_pos(index_var_wind_max(:)) = vec_u0(index_var_wind_max(:))*delta_rate_wind;
vec_du_neg(index_var_wind_max(:)) = vec_u0(index_var_wind_max(:))*delta_rate_wind;
vec_du_pos(index_var_heat_load(:)) = vec_u0(index_var_heat_load(:))*delta_rate_hl;
vec_du_neg(index_var_heat_load(:)) = vec_u0(index_var_heat_load(:))*delta_rate_hl;
z_pos_guess = 0*u0; %max(z_worst_guess,0);
z_pos_guess(index_var_heat_load(:)) = 1;
z_neg_guess = 0*u0;
z_neg_guess(index_var_wind_max(:)) = 1;

% big M
% bigM method
bigM = 1e5; % big-M 1e5 for jilin
% vec_x0 = zeros(numel(index_var_first), 1);
% vec_x0(1:numel(index_var_ugt)) = 1;
% [ x_optimal, obj_optimal, time_CCG ] = two_stage_RO_CCG( mat_A, mat_B, mat_C, mat_D, mat_F, mat_G, vec_b, vec_c, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, vec_x0, vtype_x0);
CCG_itermax = 7;
CCG_reltol = 5e-3;% 1e-5 for small; 5e-3 for jilin
rng('shuffle'); %reset seed
ADseed = rng; 
[ x_optimal, obj_optimal, time_CCG, iter_CCG] = CCG_with_feas_check( mat_A, mat_B, mat_C, mat_D, mat_F, mat_G, vec_b, vec_c, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, vtype_x0, bigM, CCG_reltol, CCG_itermax, ADseed, z_pos_guess, z_neg_guess, 'AD');
ugt = round(x_optimal(index_var_ugt-index_var_ugt(1)+1));