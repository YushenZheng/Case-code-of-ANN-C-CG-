%% 1. form the coefficient matrices
index_var_first = [index_var_ugt(:);index_var_xgt(:);index_var_ygt(:)];
index_var_second = setdiff((1:nHvar)',index_var_first);
%% index var u: 
% output: index_var_wind_max,index_var_heat_load,nUvar
initial_uncertain_variables;

% Ax <= b
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

% Bx + Cu + Dy <= e
index_con_Beq = setdiff((1:nHeq)',index_con_logic(:));
index_con_Bineq = setdiff((1:nHineq)',[index_con_timeUp(:);index_con_timeDn(:)]);
mat_B = [Aeq(index_con_Beq,index_var_first);-Aeq(index_con_Beq,index_var_first);
    Aineq(index_con_Bineq,index_var_first);
    sparse(size(index_var_second,1),size(index_var_first,1));
    sparse(size(index_var_second,1),size(index_var_first,1));
    ];
mat_D = [Aeq(index_con_Beq,index_var_second);-Aeq(index_con_Beq,index_var_second);
    Aineq(index_con_Bineq,index_var_second);
    speye(size(index_var_second,1));
    -speye(size(index_var_second,1));
    ];
vec_e = [beq(index_con_Beq);-beq(index_con_Beq);
    bineq(index_con_Bineq)
    ub(index_var_second);
    -lb(index_var_second);
    ];

%% generate C
u0 = zeros(nUvar, 1);
u0(index_var_heat_load(:)) = dT;
u0(index_var_wind_max(:)) = reshape(ub(index_var_pg(index_wind2gen,:)),nWind*nPrd,1);

mat_C = sparse(size(mat_B,1),nUvar);%全零稀疏矩阵
%原来define cons的时候，是Bx + Dy <= e-Cu的形式，此处须两边同时加Cu，u为参数
% heat load (AeqEM): g-Y_G_GS*tgs <= Y_G_D*d+g_hat  new:cM*(tds-tdr)<=d
if index_con_hes(1) > index_con_logic(end)
    row_heat_load = index_con_hes(:)-numel(index_con_logic); %reshape(, nLoad*nPrd, 1);
else
    row_heat_load = index_con_hes(:); %reshape(, nLoad*nPrd, 1);
end
mat_C(row_heat_load, index_var_heat_load(:)) = -speye(nLoad*nPrd);

% heat load (AeqEM): -(g-Y_G_GS*tgs) <= -Y_G_D*d-g_hat new:-cM*(tds-tdr)<=-d
mat_C(numel(index_con_Beq)+row_heat_load, index_var_heat_load(:)) = eye(nLoad*nPrd);

% wind (在lb,ub里) 
row_wind_max = reshape(index_var_pg(index_wind2gen,:),nWind*nPrd,1);
offset_con_ub=2*numel(index_con_Beq)+numel(index_con_Bineq);
mat_C(offset_con_ub+row_wind_max,index_var_wind_max(:)) = -speye(nWind*nPrd);
% if delta_rate_wind < eps || budget_pct_wind < eps %%without considering uncertainties of wind, then set the wind as max, add -pwg <=-pwg_max
%     % 注意：不考虑风的不确定性时，风机下界已设为容量极值
%     % 风电机组出力，var index是排在最前面的，因此在index_var_second中也在最前面，无需做偏移
%     % 原约束：-I*pwg <= -pwg_max, 变为:-I*pwg + pwg_max <= 0
%     offset_con_lb = offset_con_ub+size(index_var_second,1);
%     mat_C(offset_con_lb+row_wind_max,index_var_wind_max(:)) = speye(nWind*nPrd);
% end

vec_e = vec_e + mat_C*u0;
vec_e = max(min(vec_e,vec_e_cut),-vec_e_cut); % to prevent Inf;


% mat_C = sparse(size(mat_B,1),nWind*nPrd);
% mat_C(2*size(index_con_Beq,1)+size(index_con_Bineq,1)+index_var_pg(index_wind2gen,:),1:nWind*nPrd) = -speye(nWind*nPrd);
% vec_e = vec_e + mat_C*reshape(ub(index_var_pg(index_wind2gen,:)),nWind*nPrd,1);
% vec_e = max(min(vec_e,1e10),-1e10); % to prevent Inf;

% F*u <= f
mat_F = sparse(0,nUvar);
vec_f = zeros(0,1);

% % G*(z_pos+z_neg) <= h
% const_gamma = 24; %/4 for jilin
% const_pi = ceil(nWind/4);
% mat_G = sparse(nWind+nPrd,nWind*nPrd);
% vec_h = zeros(nWind+nPrd,1);
% temp_index = zeros(nWind,nPrd);
% temp_index(:) = 1:nWind*nPrd;
% count = 0;
% for i=1:nWind
%     count = count + 1;
%     mat_G(count,temp_index(i,:)) = 1;
%     vec_h(count) = const_gamma;
% end
% for t=1:nPrd
%     count = count + 1;
%     mat_G(count,temp_index(:,t)) = 1;
%     vec_h(count) = const_pi;
% end

%% G*(z_pos+z_neg) <= h
const_gamma_wind = ceil(nPrd*budget_pct_wind); %/4 for jilin 每台风机
const_pi_wind = ceil(nWind*budget_pct_wind);   %每个时段所有风机
const_gamma_heat_load = ceil(nPrd*budget_pct_hl);
const_pi_heat_load = ceil(nLoad*budget_pct_hl);
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
    vec_h(row_heat_d(i)) = const_gamma_heat_load;
end
for t=1:nPrd
    mat_G(row_heat_t(t),index_var_heat_load(:,t)) = 1;
    vec_h(row_heat_t(t)) = const_pi_heat_load;
end

% obj
vec_c = f(index_var_first);
vec_d = f(index_var_second);
vec_g = zeros(nUvar,1);
vec_g(index_var_wind_max(:)) = mpc.windpen;

vec_u0 = reshape(ub(index_var_pg(index_wind2gen,:)),nWind*nPrd,1);
vec_u0 = u0;
vec_du_pos=0*u0; vec_du_neg=0*u0;
vec_du_pos(index_var_wind_max(:)) = vec_u0(index_var_wind_max(:))*delta_rate_wind;
vec_du_neg(index_var_wind_max(:)) = vec_u0(index_var_wind_max(:))*delta_rate_wind;
vec_du_pos(index_var_heat_load(:)) = vec_u0(index_var_heat_load(:))*delta_rate_hl;
vec_du_neg(index_var_heat_load(:)) = vec_u0(index_var_heat_load(:))*delta_rate_hl;
z_worst_guess = 0*u0;
z_worst_guess(index_var_wind_max(:)) = -1;
z_worst_guess(index_var_heat_load(:)) = 1;
z_pos_guess = max(z_worst_guess,0);
z_neg_guess = max(-z_worst_guess,0);

normal_input_2 = mapminmax(mpc.load',0,1);
normal_input_3 = mapminmax(mpc.windexp(:,2:nPrd+1),0,1);
tra_normal_input_3=[];  %大系统需要转变矩阵形式
for ttt=1:34 
    tra_normal_input_3 = cat(2,tra_normal_input_3, normal_input_3(ttt,:));
end

normal_input_23 = [normal_input_2, tra_normal_input_3];

z_star_ANN = zeros(1,num_u*2);
z_star_tran = zeros(1,num_u*2);
time_ANN=0;

% for jj = 1:2
%     tic;
%     z_star_ANN(1,(jj-1)*num_u+1:jj*num_u) = model_z_star(jj).predict(normal_input_23);
%     time_ANN = time_ANN + toc;
% end
jj=1;
tic;
z_star_ANN(1,1:num_u*2) = model_z_star(jj).predict(normal_input_23);
time_ANN = time_ANN + toc;

for ttt = 1:num_u
    if(z_star_ANN(1,ttt) >= 0.3)
        z_star_tran(1,ttt)=1;
    else
        z_star_tran(1,ttt)=0;
    end
end
for ttt = num_u+1:num_u*2
    if(z_star_ANN(1,ttt) >= 0.65)
        z_star_tran(1,ttt)=1;
    else
        z_star_tran(1,ttt)=0;
    end
end
    zpos0_ANN = z_star_tran (1,1:num_u);
    zneg0_ANN = z_star_tran(1,num_u+1:num_u*2);

CCG_itermax = 7;
rng('shuffle'); %reset seed
ADseed = rng;
CCG_reltol = 15e-3; %1e-5 for small
bigM = 1e5; % big-M 1e6 for small
sp_solver='AD';

[ x_optimal_try, obj_optimal_try, time_CCG_try, iter_CCG_try, u_optimal_try, z_pos_star_try, z_neg_star_try, if_exit_ubsp_try ] = CCG_with_feas_check_try(zpos0_ANN, zneg0_ANN, normal_input_23, smodel_z_star, mat_A, mat_B, mat_C, mat_D, mat_F, mat_G, vec_b, vec_c, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, vtype_x0, bigM, CCG_reltol, CCG_itermax, ADseed, z_pos_guess, z_neg_guess, sp_solver);
% vec_x0 = 0*index_var_first;
% [ x_optimal,obj_optimal ] = two_stage_RO_CCG( mat_A, mat_B, mat_C, mat_D, mat_F, mat_G, vec_b, vec_c, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, vec_x0, vtype_x0);
% ugt = round(x_optimal(index_var_ugt-index_var_ugt(1)+1));

time_CCG_try = time_CCG_try+time_ANN;