% Combined heat and power scheduling
% by Zhigang Li @ Apr. 23rd, 2015
% by Weiye Zheng @ Oct. 27, 2019

% function CHPS_Equivalent(name, budget_pct_wind, budget_pct_hl, EM, bSimpleHeat)
%% a function for cycling

% Switch for considering detailed DHN or simple heat balance
% clear;
bSimpleHeat = 0;
EM = 0;
% name = 'jilin2';
name = 'jilin';
% name = 'small';
budget_pct_wind = 1; %0.25; 
% budget_pct_wind = 0; 
% budget_pct_hl = budget_pct_wind;
budget_pct_hl = 1; %0.25;
% budget_pct_hl = 0;

%% Initializing data
nPrd = 24; % total # of periods
dt = 3600; % time interval per period

if strcmp(name, 'small')
    delta_rate_wind = 0.3;      %0.5;
    delta_rate_hl = 0.1;        %0.2;
    vec_e_cut = 1e7;
elseif strcmp(name, 'jilin2')
    delta_rate_wind = 0.5;
    delta_rate_hl = 0.3; %0.1
    vec_e_cut = 1e7;
elseif strcmp(name, 'jilin')
    delta_rate_wind = 0.1;
    delta_rate_hl = 0.1;
    vec_e_cut = 1e7;
end

if budget_pct_hl < eps
    delta_rate_hl=0;
end
if budget_pct_wind < eps
    delta_rate_wind=0;
end

% Initial the electric part
initial_electric;

% Initial the heat part
initial_heat;

% Calculate the min P/H of CHP
cal_min_ph;

%% Initializing model
% Variables
nVar = 0;
initial_first_variables;
nFvar = nVar; % # of first-stage variables

initial_network_variables;
nNvar = nVar;

if EM
    initial_heat_variables_reduced;
else
    initial_heat_variables;
end
nHvar = nVar;

% Constraints
nEq = 0; % # of equality constraints
nIneq = 0; % # of inequality constraints
nEqEM = 0;
nIneqEM = 0;
initial_electric_constraints;
nFeq = nEq;
nFineq = nIneq;

initial_network_constraints;
nNeq = nEq;
nNineq = nIneq;

if ( bSimpleHeat==0 )
    if EM
        initial_heat_constraints_reduced;
    else
        initial_heat_constraints;
    end
else
    initial_simple_heat_constraints;
end
nHeq = nEq;
nHineq = nIneq;

% Bounds for variables
lb = -Inf*ones(nVar,1);
ub = -lb;
vtype = char('c'*ones(nVar,1));  %定义变量类型，b代表01变量，c代表连续变量
define_first_bounds;
define_network_bounds;
if ~EM 
    if ( bSimpleHeat==0 )
        define_heat_bounds;
    end
end
% if ( bSimpleHeat==1 )
%     lb(index_var_ugt(index_chp2gen,:)) = 1;
% end

% coefficients for constraints
Aeq = sparse(nEq,nVar);
beq = zeros(nEq,1);
Aineq = sparse(nIneq,nVar);
bineq = zeros(nIneq,1);
AeqEM = sparse(nEqEM,nVar);
beqEM = zeros(nEqEM,1);
AineqEM = sparse(nIneqEM,nVar);
bineqEM = zeros(nIneqEM,1);

define_first_constraints;
define_network_constraints;
obtain_heat_equivalent_model;
if ( bSimpleHeat==0 )
    if EM
        define_heat_constraints_EM;
    else
        define_heat_constraints;
    end
else
    define_simple_heat_constraints;
end

% Cost coefficients
f = zeros(nVar,1);
define_cost_coefficients;                %加碳交易的成本

%% Solve the robust model
if EM
%     solve_robust_CHPS_EM_onlyWind;
    solve_robust_CHPS_EM;
    time_robust_EM = time_CCG;
%     obj_robust_EM = obj_optimal;
else
    solve_robust_CHPS;%不预测，用AD解SP
    solve_robust_CHPS_ANN_sp;%()只预测SP，用AD法解SP(√)只预测SP，不迭代解SP
    solve_robust_CHPS_ANN; %()只预测MP，用AD法解SP
    solve_robust_CHPS_try;
    solve_robust_CHPS_ANN_addmain;
%     time_robust = time_CCG;
%     obj_robust = obj_optimal;
end
%% 取结果
% ugt_chp = round(x_optimal(index_var_ugt(index_chp2gen, :)-index_var_ugt(1)+1)) %此处是第一阶段，下标应做偏移
% ugt_nonchp = round(x_optimal(index_var_ugt(index_nonchp2gen, :)-index_var_ugt(1)+1))

% save
if EM
    save([name,'_wg',num2str(budget_pct_wind),'_hl',num2str(budget_pct_hl),'_EM.mat']);
else
    save([name,'_wg',num2str(budget_pct_wind),'_hl',num2str(budget_pct_hl),'.mat']);
end

% %% Solve the deterministic model
% % by gurobi directly
% if EM
%     solve_CHPS_EM;
% else
%     solve_CHPS_directly;
% end
% ub(index_var_pg(index_wind2gen(:),:))-x(index_var_pg(index_wind2gen, :))
% ugt_det = round(x(index_var_ugt));
% % ugt_det(index_nonchp2gen, :)
% ugt_det(index_chp2gen, :)
% obj_det = result.objval;
% if EM
%     save([name,'_det_EM.mat']);
% else
%     save([name,'_det.mat']);
% end


% by Benders decomposition;
% solve_CHPS_Benders;  %parfor
% solve_CHPS_Benders_WC;  %no parfor

% 
% %% Calculate the average temperature of hot water
% cal_mean_temp;

% tgs = x(index_var_tgs(:));
% qchpplant = x(index_var_qchpplant(:));
% delta = -Y_g_GS*tgs+speye(nChpplant*nPrd)*qchpplant-(Y_g_d*dT+g_hat)

x = x_optimal;
% %% result analysis
% total_heat_generation = sum(x(index_var_qchp)+kron(dhs.chp(:,CHP_HMIN), ones(1, 24)).*x(index_var_ugt(index_chp2gen, :)))';
% total_heat_load = dhs.load(1:24);
% [ub(index_var_pg(index_wind2gen(:),:)),x(index_var_pg(index_wind2gen, :))] %wind curtailment

% ugt_chp_00 = ugt_chp; ugt_nonchp_00 = ugt_nonchp;
% ugt_chp_10-ugt_chp_00

% [y Fs] = audioread('victory.mp3');sound(y,Fs);

% end