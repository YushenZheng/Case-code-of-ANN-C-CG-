% Combined heat and power scheduling
% by Zhigang Li @ Apr. 23rd, 2015
% by Weiye Zheng @ Oct. 27, 2019

clear;clc;

%% Switch for considering detailed DHN or simple heat balance
bSimpleHeat = 0;

%% Initializing data
nPrd = 24; % total # of periods
dt = 3600; % time interval per period

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

initial_heat_variables;
nHvar = nVar;

% Constraints
nEq = 0; % # of equality constraints
nIneq = 0; % # of inequality constraints
initial_electric_constraints;
nFeq = nEq;
nFineq = nIneq;

initial_network_constraints;
nNeq = nEq;
nNineq = nIneq;

if ( 1)%bSimpleHeat==0 )
    initial_heat_constraints;
else
    initial_simple_heat_constraints;
end
nHeq = nEq;
nHineq = nIneq;

% Bounds for variables
lb = -Inf*ones(nVar,1);
ub = -lb;
vtype = char('c'*ones(nVar,1));
define_first_bounds;
define_network_bounds;
obtain_heat_equivalent_model;
if ( 1)%bSimpleHeat==0 )
    define_heat_bounds;
end
% if ( bSimpleHeat==1 )
%     lb(index_var_ugt(index_chp2gen,:)) = 1;
% end

% coefficients for constraints
Aeq = sparse(nEq,nVar);
beq = zeros(nEq,1);
Aineq = sparse(nIneq,nVar);
bineq = zeros(nIneq,1);
define_first_constraints;
define_network_constraints;
if ( bSimpleHeat==0 )
    define_heat_constraints;
else
    define_simple_heat_constraints;
end

% Cost coefficients
f = zeros(nVar,1);
define_cost_coefficients;

%% Solve the robust model
% solve_robust_CHPS;
solve_robust_CHPS_EM;

%% Solve the deterministic model
% by gurobi directly
% solve_CHPS_directly;

% 
% % by Benders decomposition;
% solve_CHPS_Benders;
% 
% %% Calculate the average temperature of hot water
% cal_mean_temp;