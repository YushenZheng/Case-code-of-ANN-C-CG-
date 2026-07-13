%% 1. form the coefficient matrices
index_var_first = [index_var_ugt(:);index_var_xgt(:);index_var_ygt(:)];
index_var_second = setdiff((1:nHvar)',index_var_first);

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
    AeqEM(:, index_var_first);-AeqEM(:, index_var_first);
    Aineq(index_con_Bineq,index_var_first);
    AineqEM(:, index_var_first);
    sparse(size(index_var_second,1),size(index_var_first,1));
    sparse(size(index_var_second,1),size(index_var_first,1));
    ];
mat_D = [Aeq(index_con_Beq,index_var_second);-Aeq(index_con_Beq,index_var_second);
    AeqEM(:, index_var_second);-AeqEM(:, index_var_second);
    Aineq(index_con_Bineq,index_var_second);
    AineqEM(:, index_var_second);
    speye(size(index_var_second,1));
    -speye(size(index_var_second,1));
    ];
vec_e = [beq(index_con_Beq);-beq(index_con_Beq);
    beqEM;-beqEM;
    bineq(index_con_Bineq)
    bineqEM;
    ub(index_var_second);
    -lb(index_var_second);
    ];
mat_C = sparse(size(mat_B,1),nWind*nPrd);
mat_C(2*size(index_con_Beq,1)+size(index_con_Bineq,1)+2*size(AeqEM,1)+size(AineqEM,1)+index_var_pg(index_wind2gen,:),1:nWind*nPrd) = -speye(nWind*nPrd);
vec_e = vec_e + mat_C*reshape(ub(index_var_pg(index_wind2gen,:)),nWind*nPrd,1);
vec_e = max(min(vec_e,1e10),-1e10); % to prevent Inf;

% F*u <= f
mat_F = sparse(0,nWind*nPrd);
vec_f = zeros(0,1);

% G*(z_pos+z_neg) <= h
const_gamma = 24; %/4 for jilin
const_pi = ceil(nWind/4);
mat_G = sparse(nWind+nPrd,nWind*nPrd);
vec_h = zeros(nWind+nPrd,1);
temp_index = zeros(nWind,nPrd);
temp_index(:) = 1:nWind*nPrd;
count = 0;
for i=1:nWind
    count = count + 1;
    mat_G(count,temp_index(i,:)) = 1;
    vec_h(count) = const_gamma;
end
for t=1:nPrd
    count = count + 1;
    mat_G(count,temp_index(:,t)) = 1;
    vec_h(count) = const_pi;
end

% obj
vec_c = f(index_var_first);
vec_d = f(index_var_second);
vec_g = mpc.windpen*ones(nWind*nPrd,1);

vec_u0 = reshape(ub(index_var_pg(index_wind2gen,:)),nWind*nPrd,1);
vec_du_pos = vec_u0*0.6;
vec_du_neg = vec_u0*0.6;

vec_x0 = 0*index_var_first;

[ x_optimal, obj_optimal, time ] = two_stage_RO_CCG( mat_A, mat_B, mat_C, mat_D, mat_F, mat_G, vec_b, vec_c, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, vec_x0, vtype_x0);
ugt = round(x_optimal(index_var_ugt-index_var_ugt(1)+1));