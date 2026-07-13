function [ u_star, obj_star, time, z_pos_star, z_neg_star ] = second_stage_CCG( mat_B, mat_C, mat_D, mat_F, mat_G, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, bigM, vec_x)
% Second-stage of C&CG
%   Created by Lizg @ Aug 11th, 2015
%   Input parameter: B, C, D, F, d, e, f, u0, du_pos, du_neg, x, M
%   Output parameter: u_star, obj_star

nUvar = length(vec_u0); % # uncertain parameter
nDvar = size(mat_B,1); % # dual variables
nSvar = size(mat_D,2); % # second-stage variables

%% 1. Define variables
nVar = 0;

% var_u
var_u = zeros(nUvar,1);
var_u(:) = nVar + (1:nUvar);
nVar = nVar + nUvar;

% var_z_pos
var_z_pos = zeros(nUvar,1);
var_z_pos(:) = nVar + (1:nUvar);
nVar = nVar + nUvar;

% var_z_neg
var_z_neg = zeros(nUvar,1);
var_z_neg(:) = nVar + (1:nUvar);
nVar = nVar + nUvar;

% var_w
var_w = zeros(nDvar,1);
var_w(:) = nVar + (1:nDvar);
nVar = nVar + nDvar;

% var_eita_pos
var_eita_pos = zeros(nUvar,1);
var_eita_pos(:) = nVar + (1:nUvar);
nVar = nVar + nUvar;

% var_eita_neg
var_eita_neg = zeros(nUvar,1);
var_eita_neg(:) = nVar + (1:nUvar);
nVar = nVar + nUvar;

%% 2. Define constraints
nCon = 0;

% con_eita_pos1
con_eita_pos1 = zeros(nUvar,1);
con_eita_pos1(:) = nCon + (1:nUvar);
nCon = nCon + nUvar;

% con_eita_pos2
con_eita_pos2 = zeros(nUvar,1);
con_eita_pos2(:) = nCon + (1:nUvar);
nCon = nCon + nUvar;

% con_eita_neg1
con_eita_neg1 = zeros(nUvar,1);
con_eita_neg1(:) = nCon + (1:nUvar);
nCon = nCon + nUvar;

% con_eita_neg2
con_eita_neg2 = zeros(nUvar,1);
con_eita_neg2(:) = nCon + (1:nUvar);
nCon = nCon + nUvar;

% con_D
con_D = zeros(nSvar,1);
con_D(:) = nCon + (1:nSvar);
nCon = nCon + nSvar;

% con_F
con_F = zeros(size(mat_F,1),1);
con_F = nCon + (1:size(mat_F,1));
nCon = nCon + size(mat_F,1);

% con_u
con_u = zeros(nUvar,1);
con_u(:) = nCon + (1:nUvar);
nCon = nCon + nUvar;

% con_G
con_G = zeros(size(mat_G,1),1);
con_G(:) = nCon + (1:size(mat_G,1));
nCon = nCon + size(mat_G,1);

%% 3. Define bounds and types of variables
lb = zeros(nVar,1);
ub = zeros(nVar,1);
vtype = zeros(nVar,1);

lb(var_w) = 0;
ub(var_w) = Inf;
vtype(var_w) = char('C');

lb(var_eita_pos) = -Inf;
ub(var_eita_pos) = Inf;
vtype(var_eita_pos) = char('C');

lb(var_eita_neg) = -Inf;
ub(var_eita_neg) = Inf;
vtype(var_eita_neg) = char('C');

lb(var_z_pos) = 0;
ub(var_z_pos) = 1;
vtype(var_z_pos) = char('B');

lb(var_z_neg) = 0;
ub(var_z_neg) = 1;
vtype(var_z_neg) = char('B');

lb(var_u) = -Inf;
ub(var_u) = Inf;
vtype(var_u) = char('C');

%% 4. Define coefficients of constraints
coef_A = sparse(nCon,nVar);
coef_rhs = zeros(nCon,1);
ctype = zeros(nCon,1);

coef_A(con_eita_pos1,var_eita_pos) = speye(nUvar);
coef_A(con_eita_pos1,var_w) = -(mat_C*sparse(diag(vec_du_pos)))';
coef_A(con_eita_pos1,var_z_pos) = bigM*speye(nUvar);
coef_rhs(con_eita_pos1) = bigM;
ctype(con_eita_pos1) = char('<');

coef_A(con_eita_pos2,var_eita_pos) = speye(nUvar);
coef_A(con_eita_pos2,var_z_pos) = -bigM*speye(nUvar);
coef_rhs(con_eita_pos2) = 0;
ctype(con_eita_pos2) = char('<');

coef_A(con_eita_neg1,var_eita_neg) = speye(nUvar);
coef_A(con_eita_neg1,var_w) = (mat_C*sparse(diag(vec_du_neg)))';
coef_A(con_eita_neg1,var_z_neg) = bigM*speye(nUvar);
coef_rhs(con_eita_neg1) = bigM;
ctype(con_eita_neg1) = char('<');

coef_A(con_eita_neg2,var_eita_neg) = speye(nUvar);
coef_A(con_eita_neg2,var_z_neg) = -bigM*speye(nUvar);
coef_rhs(con_eita_neg2) = 0;
ctype(con_eita_neg2) = char('<');

coef_A(con_D,var_w) = mat_D';
coef_rhs(con_D) = -vec_d;
ctype(con_D) = char('=');

coef_A(con_F,var_z_pos) = mat_F*sparse(diag(vec_du_pos));
coef_A(con_F,var_z_neg) = -mat_F*sparse(diag(vec_du_neg));
coef_rhs(con_F) = vec_f - mat_F * vec_u0;
ctype(con_F) = char('<');

coef_A(con_u,var_u) = speye(nUvar);
coef_A(con_u,var_z_pos) = -sparse(diag(vec_du_pos));
coef_A(con_u,var_z_neg) = sparse(diag(vec_du_neg));
coef_rhs(con_u) = vec_u0;
ctype(con_u) = char('=');

coef_A(con_G,var_z_pos) = mat_G;
coef_A(con_G,var_z_neg) = mat_G;
coef_rhs(con_G) = vec_h;
ctype(con_G) = char('<');

%% 5. Define the obj coefficients
coef_obj = zeros(nVar,1);
coef_obj(var_w) = mat_B*vec_x + mat_C*vec_u0 - vec_e;
coef_obj(var_eita_pos) = 1;
coef_obj(var_eita_neg) = 1;
coef_obj(var_u) = vec_g;

%% 6. Solve the problem
% 用Gurobi求解
clear params;
params.outputflag = 1;
% params.nodemethod = 2;
% params.threads = 8;
params.timelimit = 60*10;
% params.concurrentmip = 1;
params.mipgap = 1e-2; % 1e-2 for jilin
params.intfeastol = 1e-4; % 5e-2 for jilin
% params.method = 2;
% params.mipfocus = 3;

% full problem
clear model;
model.obj = coef_obj;
model.A = coef_A;
model.rhs = coef_rhs;
model.sense = char(ctype);
model.vtype = char(vtype);
model.modelsense = 'max';
model.lb = lb;
model.ub = ub;

result = gurobi(model,params);
time = result.runtime;

%% Final: calculate u
if ( strcmp(result.status,'OPTIMAL') )
    model.lb(var_z_pos) = round(result.x(var_z_pos));
    model.ub(var_z_pos) = round(result.x(var_z_pos));
    model.lb(var_z_neg) = round(result.x(var_z_neg));
    model.ub(var_z_neg) = round(result.x(var_z_neg));
    result = gurobi(model,params);
    u_star = result.x(var_u);
    obj_star = result.objval;
    
    z_pos_star = max(u_star-vec_u0, 0)./vec_du_pos;   %%计算z
    z_neg_star = max(-u_star+vec_u0, 0)./vec_du_neg;
    
    % verify if big-M is big enough
    temp = (mat_C*diag(vec_du_pos))'*result.x(var_w);
    if ( max(abs(temp)-bigM)>=-1e-3 )
        display(sprintf('bigM = %f is not big enough!',bigM));
    end
elseif ( strcmp(result.status,'TIME_LIMIT') )
     u_star=NaN;
     obj_star=NaN;
     z_pos_star=NaN;
     z_neg_star=NaN;
else
    % unbounded
    model.ub(var_w) = 1e0;
    model.rhs(con_D) = 0;
    model.obj(var_u) = 0;
    result = gurobi(model,params);
    u_star = result.x(var_u);
    
    z_pos_star = max(u_star-vec_u0, 0)./vec_du_pos;   %%计算z
    z_neg_star = max(-u_star+vec_u0, 0)./vec_du_neg;
    
    obj_star = 1e10;
end

end

