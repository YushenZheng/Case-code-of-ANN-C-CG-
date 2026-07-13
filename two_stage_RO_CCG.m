function [ x_optimal, obj_optimal, time ] = two_stage_RO_CCG( mat_A, mat_B, mat_C, mat_D, mat_F, mat_G, vec_b, vec_c, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, vec_x0, vtype_x0)
% Solving two-stage robust optimization with C&CG
%   min_x (c'*x + max_u ( g'*u + min_y (d'*y)))
%       A*x <= b
%       B*x + C*u + D*y <= e
%       F*u <= f
%       G*(z_pos+z_neg) <= h
%       u = u0 + dU_pos*z_pos - dU_neg*z_neg
%   Input parameters: A, B, C, D, F, b, c, d, e, f, u0, du_pos, du_neg

time = 0;
nFvar = size(mat_A,2); % # first-stage variable
[nScon,nSvar] = size(mat_D); % # second-stage variable

%% 1. Define indices of variables
nVar = 0;
var_x = zeros(nFvar,1);
var_x(:) = nVar + (1:nFvar);
nVar = nVar + nFvar;

var_alpha = zeros(1,1);
var_alpha = nVar + 1;
nVar = nVar + 1;

%% 2. Define variable bounds
lb = zeros(nVar,1);
ub = lb;
vtype = zeros(nVar,1);

lb(var_x) = -Inf;
ub(var_x) = Inf;
vtype(var_x) = char(vtype_x0);

lb(var_alpha) = -Inf;
ub(var_alpha) = Inf;
vtype(var_alpha) = 'c';

%% 3. Define indices of constraints
nCon = 0;
con_A = zeros(size(mat_A,1),1);
con_A(:) = nCon + (1:size(mat_A,1));
nCon = nCon + size(mat_A,1);

%% 4. Define constraint coefficients
coef_A = [sparse(mat_A),zeros(size(mat_A,1),1)];
coef_rhs = vec_b;
ctype = char(ones(nCon,1)*'<');

%% 5. Define obj coefficients
coef_obj = zeros(nVar,1);
coef_obj(var_x) = vec_c;
coef_obj(var_alpha) = 1;

%% 6. Start the C&CG procedure
LB = -1e8;
UB = 1e8;
obj_x = 1e8;
gap_tol = 5e-3;% percentage 5e-3 for jilin
% bigM method
bigM = 1e6; % big-M 1e5 for jilin
% AD method
n_z0 = 100;
ADiter_max = 5;
ADtol_rel = 1e-3;

iter = 0;

loop = true;

x_star = vec_x0;

while (loop)
    iter = iter + 1;
    
    % solve the subproblem
    [ u_star, obj_sub, time_sub ] = second_stage_CCG( mat_B, mat_C, mat_D, mat_F, mat_G, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, bigM, x_star);
%     [ u_star, obj_sub, time_sub ] = second_stage_CCG_AD( mat_B, mat_C, mat_D, mat_F, mat_G, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, x_star, n_z0, ADiter_max, ADtol_rel);
    time = time + time_sub;    
    
    % Check convergence
    UB = min(UB, obj_x+obj_sub);
    display(sprintf('[Iter %d] UB = %.0f, LB = %.0f, gap = %.2f%%', iter, UB, LB, 200*(UB-LB)/(UB+LB)));
    if ( (UB-LB)<gap_tol*(UB+LB)*0.5 )
        loop = false;
        continue;
    end
          
    % Expand the master problem
    expand_master_problem;
    
    % Solve the master problem
    solve_master_problem;
    time = time + time_master;    
    
    % Check convergence
    LB = max(LB, obj);
    display(sprintf('[Iter %d] UB = %.0f, LB = %.0f, gap = %.2f%%', iter, UB, LB, 200*(UB-LB)/(UB+LB)));
    if ( (UB-LB)<gap_tol*(UB+LB)*0.5 )
        loop = false;
        continue;
    end
    
end

x_optimal = x_star;
obj_optimal = obj;

end

