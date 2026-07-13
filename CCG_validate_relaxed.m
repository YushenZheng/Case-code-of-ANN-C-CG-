function [ obj_first_stage, obj_second_stage, y_optimal, x_feasible, u_feasible ] = CCG_validate_relaxed( mat_A, mat_B, mat_C, mat_D, mat_F, mat_G, vec_b, vec_c, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, x_star, u_star, rho)
% Solving two-stage robust optimization with C&CG
%   min_x (c'*x + max_u ( g'*u + min_y (d'*y)))
%       A*x <= b
%       B*x + C*u + D*y <= e
%       F*u <= f
%       G*(z_pos+z_neg) <= h
%       u = u0 + dU_pos*z_pos - dU_neg*z_neg
%   Input parameters: A, B, C, D, F, b, c, d, e, f, u0, du_pos, du_neg; x, u
%   rho: penalty for constraint violation

nYvar = size(mat_D, 2);

%% recover z
zpos = max(u_star-vec_u0,0)./(vec_du_pos+eps);
zneg = min(u_star-vec_u0,0)./(vec_du_neg+eps);
if prod(mat_F*u_star <= vec_f+eps) && prod(mat_G*(zpos+zneg) <= vec_h+eps) && max(zpos) <= 1 && max(zneg) <= 1
    u_feasible = 1;
else
    u_feasible = 0;
end

if prod(mat_A*x_star-vec_b > eps)
    x_feasible = 0; obj_first_stage = 0; obj_second_stage = 0; y_optimal = NaN*ones(nYvar, 1);
    return
else
    x_feasible = 1;
end

nCon = size(mat_D,1);
nVar = nYvar+nCon; % # second-stage variables and slack var


lb = -Inf*ones(nVar,1);
ub = Inf*ones(nVar,1);
lb(nYvar+1:nVar) = 0;  %nonnegative slack
vtype = char('c'*ones(nVar,1));
sense = char('<'*ones(nCon,1));

clear model
model.obj = [vec_d;rho*ones(nCon, 1)];
model.A = [sparse(mat_D), -speye(nCon)];
model.rhs = vec_e-mat_B*x_star-mat_C*u_star;
model.sense = sense;
model.vtype = vtype;
model.modelsense = 'min';
model.lb = lb;
model.ub = ub;

clear params;
params.outputflag = 0;
% params.feasibilitytol = 1e-3; %default: 1e-6

result = gurobi(model,params);

if ( strcmp(result.status,'OPTIMAL') )
    y_optimal = result.x;
    obj_second_stage = vec_g'*u_star+result.objval;
    obj_first_stage = vec_c'*x_star;
else
%     model.obj = 0*vec_d;
%     result = gurobi(model,params);
%     y_optimal = result.x;
%     obj_second_stage = vec_g'*u_star+result.objval;
%     obj_first_stage = vec_c'*x_star;
    obj_first_stage = 0; obj_second_stage = 0; 
    y_optimal = NaN*ones(nYvar, 1);
end

end
