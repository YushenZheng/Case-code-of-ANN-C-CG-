[nConOld,nVarOld] = size(coef_A);
if ~exist('OC_add')   %%与李志刚程序兼容
    OC_add = 1;
end
if OC_add
    nConNew = nConOld+1+nScon;%nScon第二阶段变量对应的约束数量
else
    nConNew = nConOld+nScon;
end
nVarNew = nVarOld+nSvar;%nSvar第二阶段变量
A_temp = sparse(nConNew,nVarNew);
rhs_temp = zeros(nConNew,1);

A_temp(1:nConOld,1:nVarOld) = coef_A;
rhs_temp(1:nConOld) = coef_rhs;

%% feasibility cut            %B*x+D*y1<=e-C*u
A_temp(nConOld+[1:nScon],var_x) = mat_B;
A_temp(nConOld+[1:nScon],nVarOld+1:nVarNew) = mat_D;
rhs_temp(nConOld+[1:nScon]) = vec_e - mat_C*u_star;

%% optimality cut             %var_alpha>=g*u+d*y1
if OC_add   
    A_temp(nConNew,var_alpha) = -1;%var_alpha代表max_u()整部分
    A_temp(nConNew,nVarOld+1:nVarNew) = vec_d;
    rhs_temp(nConNew) = -vec_g'*u_star;
end

ctype = [ctype;char('<'*ones(nConNew-nConOld,1))];

coef_A = A_temp;
coef_rhs = rhs_temp;
coef_obj = [coef_obj;zeros(nVarNew-nVarOld,1)];
lb = [lb;-Inf*ones(nVarNew-nVarOld,1)];
ub = [ub;Inf*ones(nVarNew-nVarOld,1)];
vtype = [vtype;char('C'*ones(nVarNew-nVarOld,1))];

clear A_temp;
clear rhs_temp;