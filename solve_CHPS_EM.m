% coefficients for the master UC problem
Aeq_first = Aeq(1:nFeq,1:nFvar);
beq_first = beq(1:nFeq);

Aineq_first = Aineq(1:nFineq,1:nFvar);
bineq_first = bineq(1:nFineq);

lb_first = lb(1:nFvar);
ub_first = ub(1:nFvar);

f_first = f(1:nFvar);

vtype_first = vtype(1:nFvar);

% coefficient for the SCUC problem
Aeq_SCUC = Aeq(1:nNeq,1:nNvar);
beq_SCUC = beq(1:nNeq);

Aineq_SCUC = Aineq(1:nNineq,1:nNvar);
bineq_SCUC = bineq(1:nNineq);

lb_SCUC = lb(1:nNvar);
ub_SCUC = ub(1:nNvar);

f_SCUC = f(1:nNvar);

vtype_SCUC = vtype(1:nNvar);

% % original setting 用Gurobi求解
% clear params;
% params.outputflag = 1;
% params.nodemethod = 2;  %0=primal simplex, 1=dual simplex, and 2=barrier
% % params.threads = 8;
% % params.timelimit = 60*30;
% params.concurrentmip = 1;
% params.mipgap = 1e-2;  %default: 1e-4
% params.intfeastol = 1e-2;   %default: 1e-5
% params.method = 2;  %-1=automatic, 0=primal simplex, 1=dual simplex, 2=barrier, 3=concurrent, 4=deterministic concurrent, 5=deterministic concurrent simplex
% % params.mipfocus = 3;

% new setting 用Gurobi求解
clear params;
params.outputflag = 1;
% params.nodemethod = 2;  %0=primal simplex, 1=dual simplex, and 2=barrier
% params.threads = 8;
% params.timelimit = 60*30;
% params.concurrentmip = 1;
params.mipgap = 1e-2;  %default: 1e-4
% params.intfeastol = 1e-2;   %default: 1e-5
% params.method = 2;  %-1=automatic, 0=primal simplex, 1=dual simplex, 2=barrier, 3=concurrent, 4=deterministic concurrent, 5=deterministic concurrent simplex
% params.mipfocus = 3;

% full problem
clear model;
model.obj = f;
model.A = [Aineq;Aeq;AineqEM;AeqEM];
model.rhs = full([bineq;beq;bineqEM;beqEM]);
model.sense = [char('<'*ones(size(Aineq,1),1));char('='*ones(size(Aeq,1),1)); ...
    char('<'*ones(size(AineqEM,1),1));char('='*ones(size(AeqEM,1),1))];
model.vtype = vtype;
model.modelsense = 'min';
model.lb = lb;
model.ub = ub;
model.objcon = sum(sum(mpc.windpen*ub(index_var_pg(index_wind2gen(:),:))));

% master problem
clear model_first
model_first.obj = f_first;
model_first.A = [Aineq_first;Aeq_first];
model_first.rhs = full([bineq_first;beq_first]);
model_first.sense = [char('<'*ones(size(Aineq_first,1),1));char('='*ones(size(Aeq_first,1),1))];
model_first.vtype = vtype_first;
model_first.modelsense = 'min';
model_first.lb = lb_first;
model_first.ub = ub_first;

% SCUC problem
clear model_SCUC;
model_SCUC.obj = f_SCUC;
model_SCUC.A = [Aineq_SCUC;Aeq_SCUC];
model_SCUC.rhs = full([bineq_SCUC;beq_SCUC]);
model_SCUC.sense = [char('<'*ones(size(Aineq_SCUC,1),1));char('='*ones(size(Aeq_SCUC,1),1))];
model_SCUC.vtype = vtype_SCUC;
model_SCUC.modelsense = 'min';
model_SCUC.lb = lb_SCUC;
model_SCUC.ub = ub_SCUC;

result = gurobi(model,params);
% result = gurobi(model_first,params);
% result = gurobi(model_SCUC,params);

if (strcmp(result.status,'OPTIMAL')==1)
    x = result.x;
end