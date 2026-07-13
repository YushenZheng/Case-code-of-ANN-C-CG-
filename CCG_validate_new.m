function [ x_optimal, obj_optimal, time, iter ] = CCG_validate_new( mat_A, mat_B, mat_C, mat_D, mat_F, mat_G, vec_b, vec_c, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, vtype_x0, CCG_reltol, CCG_itermax, ADseed, z_pos_guess, z_neg_guess, x_star)
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

% var_alpha = zeros(1,1);
var_alpha = nVar + 1;
nVar = nVar + 1;

%% 2. Define variable bounds
lb = zeros(nVar,1);
ub = lb;
vtype = zeros(nVar,1);

lb(var_x) = x_star-1e-2;
ub(var_x) = x_star+1e-2;
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
% gap_tol = 5e-3;% percentage 5e-3 for others
gap_tol = CCG_reltol;
% bigM method
bigM = 1e6; % big-M 1e5 for jilin
% AD method
n_z0 = 10;
ADiter_max = 6;
ADtol_rel = 1e-3;

iter = 0;

succeed = false;

u_star = vec_u0;

OC_add = 1;

%% initial values for AD
nUvar = size(mat_C, 2);
n_z0 = max(n_z0, 5);    %最少要试4个初值
rng(ADseed);
zpos0_set = cell(n_z0, 1); zneg0_set = cell(n_z0, 1);
% seed = rng;
idx = 1;
while idx <= n_z0
    if idx <= 1
        zpos0_set{idx} = zeros(nUvar, 1);
        zneg0_set{idx} = zeros(nUvar, 1);
    elseif idx <= 2
        zpos0_set{idx} = zeros(nUvar, 1);
        zneg0_set{idx} = ones(nUvar, 1);
    elseif idx <= 3
        zpos0_set{idx} = ones(nUvar, 1);
        zneg0_set{idx} = zeros(nUvar, 1);
    elseif idx <= 4
        zpos0_set{idx} = z_pos_guess;
        zneg0_set{idx} = z_neg_guess;
%     elseif idx <= nUvar+4
%         zpos0_set{idx} = zeros(nUvar, 1);
%         zneg0_set{idx} = zeros(nUvar, 1);
%         zpos0_set{idx}(idx-4) = 1;
%     elseif idx <= 2*nUvar+4
%         zpos0_set{idx} = zeros(nUvar, 1);
%         zneg0_set{idx} = zeros(nUvar, 1);
%         zneg0_set{idx}(idx-nUvar-4) = 1;
    else
        verified = 0;   %redundancy check
        while ~verified
            redundant = 0;
            zpos0_temp = randi([0,1], nUvar,1);
            zneg0_temp = randi([0,1], nUvar,1);
%             if sum(mat_G*(zpos0_temp+zneg0_temp) - vec_h > 0) > 0  %初值不在可行域内，抛弃，重新抽初值
%                 continue
%             end
            for idx_check = 1:idx-1
                if nnz(zpos0_temp-zpos0_set{idx_check}) < 1 && nnz(zneg0_temp-zneg0_set{idx_check}) < 1
                    redundant = 1;
                    break
                end                    
            end
            if ~redundant
                zpos0_set{idx} = zpos0_temp;
                zneg0_set{idx} = zneg0_temp;
                verified = 1;
            end
        end        
    end
    idx=idx+1;
end

first_sp_infeasible = 1;
while iter < CCG_itermax
    iter = iter + 1;
    
    % Expand the master problem
    expand_master_problem;
    
    % Solve the master problem
    solve_master_problem;
    time = time + time_master;    
    
    % Check convergence
    LB = max(LB, obj);
    display(sprintf('[Iter %d] UB = %.0f, LB = %.0f, gap = %.2f%%', iter, UB, LB, 200*(UB-LB)/(UB+LB)));
    if ( abs(UB-LB)<gap_tol*(UB+LB)*0.5 )
        succeed = true;
        break;
    end
        
    % [ u_star, obj_sub, time_sub ] = second_stage_CCG( mat_B, mat_C, mat_D, mat_F, mat_G, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, bigM, x_star);
    [ u_star, z_pos_star, z_neg_star, obj_sub, time_sub] = CCG_second_stage_AD( mat_B, mat_C, mat_D, mat_F, mat_G, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, x_star, inf, zpos0_set, zneg0_set, ADiter_max, ADtol_rel);
    if sum(isnan(u_star)) < 1
        OC_add = 1;
        UB = min(UB, obj_x+obj_sub);
        % Check convergence
        display(sprintf('[Iter %d] UB = %.0f, LB = %.0f, gap = %.2f%%', iter, UB, LB, 200*(UB-LB)/(UB+LB)));
        if ( abs(UB-LB)<gap_tol*(UB+LB)*0.5 )
            succeed = true;
            break;
        end 
        time = time + time_sub;
    else
        error('CCG subproblem infeasible!')
        OC_add = 0;
        if first_sp_infeasible
            z_pos_star = z_pos_guess; z_neg_star = z_neg_guess;
            u_star = vec_u0+diag(vec_du_pos)*z_pos_star-diag(vec_du_neg)*z_neg_star;
            first_sp_infeasible = 0;
        else
            % relaxed problem
            [ u_star, z_pos_star, z_neg_star, obj_feas_check, time_feas] = CCG_second_stage_AD( mat_B, mat_C, mat_D, mat_F, mat_G, 0*vec_d, vec_e, vec_f, 0*vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, x_star, 1, zpos0_set, zneg0_set, ADiter_max, ADtol_rel);
            time = time + time_feas;
        end
    end
end

if succeed
    disp('CCG succeeded!')
    x_optimal = x_star;
    obj_optimal = obj;
else
    error('CCG failed!')
%     x_optimal = NaN;
%     obj_optimal = inf;
end    

end