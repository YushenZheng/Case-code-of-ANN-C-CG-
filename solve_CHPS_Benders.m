%% Solve the CHPS problem via Benders decomposition
% obj是漏了常数项的   %%WC

% Initialize the master UC problem
Aeq_first = Aeq(1:nFeq,1:nFvar);
beq_first = beq(1:nFeq);

Aineq_first = Aineq(1:nFineq,1:nFvar);
bineq_first = bineq(1:nFineq);

lb_first = lb(1:nFvar);
ub_first = ub(1:nFvar);

f_first = f(1:nFvar);

vtype_first = vtype(1:nFvar);

% 用Gurobi求解
clear params;
params.outputflag = 0;
params.nodemethod = 2;
params.threads = 8;
params.timelimit = 60*30;
params.concurrentmip = 1;
params.mipgap = 1e-3;
params.intfeastol = 1e-4;
params.method = 2;

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

bFlag_network = false; % indicate the feasibility of network constraints
bFlag_DHS = false; % indeicate the feasibility of DHS constraints

nCount_master = 0;
nCount_network = 0;
nCount_DHS = 0;

coef_network_cut = sparse(nPrd,nFvar);
const_network_cut = zeros(nPrd,1);

coef_DHS_cut = sparse(2*nChpplant*nPrd,nFvar);
const_DHS_cut = zeros(2*nChpplant*nPrd,1);

ii = [index_con_hs(:)-nNeq;index_con_hs(:)-nNeq];
jj = (1:nChpplant*nPrd*2);
ss = [ones(nChpplant*nPrd,1);-ones(nChpplant*nPrd,1)];
Ce_DHS = sparse(ii,jj,ss,nHeq-nNeq,2*nChpplant*nPrd);

tic;
while (bFlag_network==false | bFlag_DHS==false)
    bFlag_network = true;
    
    %% Solve the master UC problem
    nCount_master = nCount_master + 1;
    display(sprintf('Solve the master problem (round %d) ...',nCount_master));
    result_master = gurobi(model_first,params);
    display(sprintf('master obj = %f',result_master.objval));
    
    if ( strcmp(result_master.status,'OPTIMAL')==1 )
        x_master = result_master.x;
    else
        display('Infeasible or unbounded in the master problem!');
        return;
    end
    
    %% Check the feasibility of network constraints
    nCount_network = nCount_network + 1;
    display(sprintf('\tChecking the network constraints (round %d) ...',nCount_network));
    
    bNcut = zeros(nPrd,1);
    parfor t=1:nPrd
        [coef_temp, const_temp, bFeas] = feasibility_check( ...
            [zeros(nBus,1);ones(2*nGen,1)], ... % f
            Aeq(index_con_node(:,t),1:nFvar), ... % Ae
            Aeq(index_con_node(:,t),index_var_a(:,t)), ... % Be
            [im_gen,-im_gen], ... % Ce
            beq(index_con_node(:,t)), ... %de
            Aineq([index_con_networkPos(:,t);index_con_networkNeg(:,t)],1:nFvar), ...% Ai
            Aineq([index_con_networkPos(:,t);index_con_networkNeg(:,t)],index_var_a(:,t)), ...% Bi
            bineq([index_con_networkPos(:,t);index_con_networkNeg(:,t)]), ... % Di
            lb(index_var_a(:,t)), ... % lb
            ub(index_var_a(:,t)), ... % ub
            x_master);% x
        
        if (bFeas==0)
            bNcut(t) = 1;
            coef_network_cut(t,:) = coef_temp;
            const_network_cut(t,:) = const_temp;
        end
    end
    
    index_temp = find(bNcut==1);
    if ( ~isempty(index_temp) )
        % Network constraints violated, add cuts
        bFlag_network = false;
        nCut = length(index_temp);
       
        model_first.A = [model_first.A;coef_network_cut(index_temp,:)];
        model_first.rhs = [model_first.rhs;const_network_cut(index_temp)];
        model_first.sense = [model_first.sense;char('<'*ones(nCut,1))];

        display(sprintf('\t\t Add %d network cuts.',length(index_temp)));
        continue;
    end
    
%     %% Check the feasibility of DHS constraints
%     bFlag_DHS = true;
%     
%     nCount_DHS = nCount_DHS + 1;
%     display(sprintf('\tChecking the DHS constraints (round %d) ...',nCount_DHS));
%     
%     bHcut = 0;
%     [coef_temp, const_temp, bFeas] = feasibility_check( ...
%         ones(2*nChpplant*nPrd,1), ... %f
%         Aeq(nNeq+1:nHeq,1:nFvar), ... % Ae
%         Aeq(nNeq+1:nHeq,nNvar+1:nHvar), ... % Be
%         Ce_DHS, ... % Ce
%         beq(nNeq+1:nHeq), ... %de
%         Aineq(nNineq+1:nHineq,1:nFvar), ...% Ai
%         Aineq(nNineq+1:nHineq,nNvar+1:nHvar), ...% Bi
%         bineq(nNineq+1:nHineq), ... % Di
%         lb(nNvar+1:nHvar), ... % lb
%         ub(nNvar+1:nHvar), ... % ub
%         x_master);% x
% 
%     if (bFeas==0)
%         bHcut = 1;
%         coef_DHS_cut = coef_temp;
%         const_DHS_cut = const_temp;
%     end
%     
%     if ( bHcut )
%         % Network constraints violated, add cuts
%         bFlag_DHS = false;
%         nCut = length(1);
%        
%         model_first.A = [model_first.A;coef_DHS_cut];
%         model_first.rhs = [model_first.rhs;const_DHS_cut];
%         model_first.sense = [model_first.sense;'<'];
% 
%         display(sprintf('\t\t Add 1 DHS cuts.'));
%         continue;
%     end    

    %% Check the feasibility of DHS constraints
    bFlag_DHS = true;
    
    nCount_DHS = nCount_DHS + 1;
    display(sprintf('\tChecking the DHS constraints (round %d) ...',nCount_DHS));
    
    bHcut = zeros(2*nChpplant*nPrd,1);
    parfor s=1:2*nChpplant*nPrd
        [coef_temp, const_temp, bFeas] = feasibility_check( ...
            [zeros(1,nHvar-nNvar),s:2*nChpplant*nPrd,1:s-1]', ... %f
            Aeq(nNeq+1:nHeq,1:nFvar), ... % Ae
            Aeq(nNeq+1:nHeq,nNvar+1:nHvar), ... % Be
            Ce_DHS, ... % Ce
            beq(nNeq+1:nHeq), ... %de
            Aineq(nNineq+1:nHineq,1:nFvar), ...% Ai
            Aineq(nNineq+1:nHineq,nNvar+1:nHvar), ...% Bi
            bineq(nNineq+1:nHineq), ... % Di
            lb(nNvar+1:nHvar), ... % lb
            ub(nNvar+1:nHvar), ... % ub
            x_master);% x

        if (bFeas==0)
            bHcut(s) = 1;
            coef_DHS_cut(s,:) = coef_temp;
            const_DHS_cut(s) = const_temp;
        end
    end
    
    index_temp = find(bHcut==1);
    if ( ~isempty(index_temp) )
        % Network constraints violated, add cuts
        bFlag_DHS = false;
        nCut = length(index_temp);
       
        model_first.A = [model_first.A;coef_DHS_cut(index_temp,:)];
        model_first.rhs = [model_first.rhs;const_DHS_cut(index_temp)];
        model_first.sense = [model_first.sense;char('<'*ones(nCut,1))];

        display(sprintf('\t\t Add %d DHS cuts.',nCut));
        continue;
    end    
end
toc;
if ( bFlag_network==true && bFlag_DHS==true)
    display(sprintf('Converge in %d master iterations!', nCount_master));
end