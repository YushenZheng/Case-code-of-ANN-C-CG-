function [ coef_cut, rhs_cut, flag ] = feasibility_check( f, Ae, Be, Ce, de, Ai, Bi, Di, lb, ub, x0)
%% Check the feasibility of the following problem in a general form
% min f*s
% s.t.
% Be*y + Ce*s = de - Ae*x0
% Bi*y <= di - Ai*x0
% lb <= y <= ub
% s >= 0

nEq = size(Ae,1);
nIneq = size(Ai,1);
nX = size(Ae,2);
nY = size(Be,2);
nS = size(Ce,2);

Aeq = [Be, Ce];
beq = de - Ae*x0;

Aineq = [Bi, sparse(nIneq,nS)];
bineq = Di - Ai*x0;

llb = [lb;zeros(nS,1)];
uub = [ub;Inf*ones(nS,1)];

clear params;
params.outputflag = 0;
% params.nodemethod = 2;
% params.threads = 8;
% params.timelimit = 60*30;
% params.concurrentmip = 1;
% params.mipgap = 1e-3;
% params.intfeastol = 1e-4;
% params.method = 2;

model.obj = f;
model.A = [Aeq;Aineq];
model.rhs = [beq;bineq];
model.sense = [char('='*ones(nEq,1));char('<'*ones(nIneq,1))];
model.modelsense = 'min';
model.lb = llb;
model.ub = uub;

result = gurobi(model,params);

% Feasible
if ( result.objval<1e-6 )
    flag = 1;
    coef_cut = [];
    rhs_cut = [];
else
    % infeasible
    flag = 0;
    coef_cut = -sparse(result.pi(1:nEq))'*Ae;
    rhs_cut = -result.objval+coef_cut*x0;
end

end

