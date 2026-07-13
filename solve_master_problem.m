clear params;
params.outputflag = 1;
% params.nodemethod = 2;
params.threads = 4;
if det ~= 1
    params.timelimit = 300;  % for jilin2
    % params.concurrentmip = 2;
    params.mipgap = 5e-2;    % for jilin2
    % if det
    %     params.mipgap = 5e-3;
    % else
    %     params.mipgap = 5e-2; %for jilin: 5e-2 for robust and 5e-3 for deterministic
    % end
    params.intfeastol = 1e-5;
    params.method = 2;
    % params.mipfocus = 3;
end

% full problem
clear model;
model.obj = coef_obj;
model.A = coef_A;
model.rhs = coef_rhs;
model.sense = char(ctype);
model.vtype = char(vtype);
model.modelsense = 'min';
model.lb = lb;
model.ub = ub;

result = gurobi(model,params);
time_master = result.runtime;

if ( strcmp(result.status,'OPTIMAL') || (strcmp(result.status,'TIME_LIMIT') && result.mipgap <= 5e-2) )
    x_star = result.x(var_x);
%     x_star = [1;0;1;1;1;1;0;1;1;1;1;0;1;1;1;1;0;1;1;1;1;0;1;1;1;1;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;0;1;1;1;1;0;1;1;1;1;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;0;1;1;1;1;0;1;1;1;1;0;1;1;1;1;0;0;1;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-1.77635683940025e-15;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0];
    obj = result.objval;
    obj_x = obj - result.x(var_alpha);
else
    error('CCG master problem infeasible!')
end

