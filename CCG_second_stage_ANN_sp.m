function [ u_star, z_pos_star, z_neg_star, obj_sub, time_sub] = CCG_second_stage_ANN_sp( normal_input_23, smodel_z_star, mat_B, mat_C, mat_D, mat_F, mat_G, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, x_star, w_max, ADiter_max, ADtol_rel)
% Second-stage of C&CG solved by ANN
%   Created by WC @ Jan 16th, 2019
%   u = u0 + dU_pos*z_pos - dU_neg*z_neg
%   Input parameter: B, C, D, F, d, e, f, u0, du_pos, du_neg, x, M
%   Output parameter: u_star, obj_star

nUvar = length(vec_u0); % # uncertain parameter
nDvar = size(mat_B,1); % # dual variables
nSvar = size(mat_D,2); % # second-stage variables

%% z-fixed problem
%% 1. Define variables
nVar_fixz = 0;
% var_w
var_w = zeros(nDvar,1);
var_w(:) = nVar_fixz + (1:nDvar);
nVar_fixz = nVar_fixz + nDvar;
%% 2. Define constraints
nCon_fixz = 0;
% con_D
con_D = zeros(nSvar,1);
con_D(:) = nCon_fixz + (1:nSvar);
nCon_fixz = nCon_fixz + nSvar;
%% 3. Define bounds and types of variables
lb_fixz = zeros(nVar_fixz,1);
ub_fixz = zeros(nVar_fixz,1);
vtype_fixz = zeros(nVar_fixz,1);
lb_fixz(var_w) = 0;
ub_fixz(var_w) = w_max;
vtype_fixz(var_w) = char('C');
%% 4. Define constraints and obj
% A_fixz = sparse(nCon_fixz,nVar_fixz);
% rhs_fixz = zeros(nCon_fixz,1);
ctype_fixz = zeros(nCon_fixz,1);
obj_fixz = zeros(nCon_fixz,1);
A_fixz = mat_D';
rhs_fixz = -vec_d;
ctype_fixz(:) = char('=');

%% w-fixed problem
%% 1. Variables
nVar_fixw = 0;
% var_u
var_u = zeros(nUvar,1);
var_u(:) = nVar_fixw + (1:nUvar);
nVar_fixw = nVar_fixw + nUvar;
% var_z_pos
var_z_pos = zeros(nUvar,1);
var_z_pos(:) = nVar_fixw + (1:nUvar);
nVar_fixw = nVar_fixw + nUvar;
% var_z_neg
var_z_neg = zeros(nUvar,1);
var_z_neg(:) = nVar_fixw + (1:nUvar);
nVar_fixw = nVar_fixw + nUvar;
%% 2. Constraints
nCon_fixw = 0;
% con_F
con_F = zeros(size(mat_F,1),1);
con_F = nCon_fixw + (1:size(mat_F,1));
nCon_fixw = nCon_fixw + size(mat_F,1);
% con_u
con_u = zeros(nUvar,1);
con_u(:) = nCon_fixw + (1:nUvar);
nCon_fixw = nCon_fixw + nUvar;
% con_G
con_G = zeros(size(mat_G,1),1);
con_G(:) = nCon_fixw + (1:size(mat_G,1));
nCon_fixw = nCon_fixw + size(mat_G,1);
%% 3. Define bounds and types of variables
lb_fixw = zeros(nVar_fixw,1);
ub_fixw = zeros(nVar_fixw,1);
vtype_fixw = zeros(nVar_fixw,1);
lb_fixw(var_z_pos) = 0;
ub_fixw(var_z_pos) = 1;
vtype_fixw(var_z_pos) = char('C');
lb_fixw(var_z_neg) = 0;
ub_fixw(var_z_neg) = 1;
vtype_fixw(var_z_neg) = char('C');
lb_fixw(var_u) = vec_u0-vec_du_neg;
ub_fixw(var_u) = vec_u0+vec_du_pos;
vtype_fixw(var_u) = char('C');
%% 3. Define bounds and types of variables
A_fixw = sparse(nCon_fixw,nVar_fixw);
rhs_fixw = zeros(nCon_fixw,1);
ctype_fixw = zeros(nCon_fixw,1);
% con_F
A_fixw(con_F,var_z_pos) = mat_F*sparse(diag(vec_du_pos));
A_fixw(con_F,var_z_neg) = -mat_F*sparse(diag(vec_du_neg));
rhs_fixw(con_F) = vec_f - mat_F * vec_u0;
ctype_fixw(con_F) = char('<');
% con_u
A_fixw(con_u,var_u) = speye(nUvar);
A_fixw(con_u,var_z_pos) = -sparse(diag(vec_du_pos));
A_fixw(con_u,var_z_neg) = sparse(diag(vec_du_neg));
rhs_fixw(con_u) = vec_u0;
ctype_fixw(con_u) = char('=');
% con_G
A_fixw(con_G,var_z_pos) = mat_G;
A_fixw(con_G,var_z_neg) = mat_G;
rhs_fixw(con_G) = vec_h;
ctype_fixw(con_G) = char('<');
% obj
obj_fixw = zeros(nVar_fixw,1);

%% constant part of two problems
clear fixz; clear fixw;
fixz.A = A_fixz;
fixz.rhs = rhs_fixz;
fixz.sense = char(ctype_fixz);
fixz.vtype = char(vtype_fixz);
fixz.obj = obj_fixz;
fixz.modelsense = 'max';
fixz.lb = lb_fixz;
fixz.ub = ub_fixz;
fixw.A = A_fixw;
fixw.rhs = rhs_fixw;
fixw.sense = char(ctype_fixw);
fixw.vtype = char(vtype_fixw);
fixw.obj = obj_fixw;
fixw.modelsense = 'max';
fixw.lb = lb_fixw;
fixw.ub = ub_fixw;

%% preparing z_pos0
% n_z0_max = 2^nUvar;
% n_z0 = min(n_z0, n_z0_max); %z0个数，也是外层最大迭代次数
% n_z0 = numel(zpos0_set); 
% obj_sub_log = -inf*ones(n_z0, 1);   %记录max-min子问题在不同初值z0下的最优值，越大越好
% u_star_log = NaN*ones(nUvar, n_z0); %记录max-min子问题在不同初值z0下的最优解u*
% z_pos_star_log = NaN*ones(nUvar, n_z0);
% z_neg_star_log = NaN*ones(nUvar, n_z0);
% time_log = zeros(n_z0, 1);
% solved_log = zeros(n_z0, 1);

% while 1
%     if isempty(zpos0_indices) || idx > n_z0     %抽干了或抽够了就停止
%         break
%     end
%     if idx <= 1
%         zpos0_index = n_z0_max; zpos0_indices(n_z0_max) = [];
%     elseif idx <= 2
%         zpos0_index = 1; zpos0_indices(1) = [];
%     else
%         [zpos0_index, zpos0_indices] = mysample_wo_replace(zpos0_indices);
%     end
%     zpos0 = [dec2bin(zpos0_index-1,nUvar)-'0']'; zneg0 = abs([dec2bin(zpos0_index-1,nUvar)-'1'])'; %换算成真实zpos0向量
% shown = 0; pop = 0;
% for idx = 1:n_z0   
%     zpos0 = zpos0_set{idx}; 
%     zneg0 = zneg0_set{idx};    
%% 获得ANN的输入
    normal_input_1 = x_star';
    normal_input_model = [normal_input_1, normal_input_23];
%% 
    
%     pop = floor(idx/n_z0*10);
    [u_temp, z_pos_temp, z_neg_temp, obj_temp, time_temp] = alternating_direction_ANN_sp(normal_input_model, smodel_z_star, fixz, fixw, mat_B, mat_C, vec_u0, vec_du_pos, vec_du_neg, x_star, vec_e, vec_g, var_u,ADiter_max, ADtol_rel);    
    obj_sub = obj_temp;
    u_star = u_temp;
    z_pos_star = z_pos_temp;
    z_neg_star = z_neg_temp;
    time_sub = time_temp;
    
%     u_star_log(:, idx) = u_temp;
%     z_pos_star_log(:, idx) = z_pos_temp;
%     z_neg_star_log(:, idx) = z_neg_temp;
%     obj_sub_log(idx) = obj_temp;
%     time_log(idx) = time_temp;
%     solved_log(idx) = solved_temp;
%     if pop>shown
%         shown = pop;
%         display(sprintf('[%.1f%%] of the %d initial values solved in CCG_second_stage_AD.', idx/n_z0*100, n_z0));
%     end
% end

% [obj_wrst, idx_wrst] = max(obj_sub_log);
% if solved_log(idx_wrst) > 0
%     obj_sub = obj_wrst;
%     u_star = u_star_log(:, idx_wrst);
%     z_pos_star = z_pos_star_log(:, idx_wrst);
%     z_neg_star = z_neg_star_log(:, idx_wrst);
% else
%     obj_sub = -inf;
%     u_star = NaN*vec_u0;
%     z_pos_star = u_star;
%     z_neg_star = u_star;
% end
% time_sub = sum(time_log);

end