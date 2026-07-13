% Define constants for district heating system analysis
% Created by Lizg @ Feb. 21st, 2015

PIPE_FROM = 1;
PIPE_TO = 2;
PIPE_L = 3;
PIPE_DM = 4;
PIPE_RF = 5;
PIPE_COND = 6;
PIPE_MMIN = 7;
PIPE_MMAX = 8;
PIPE_FLOWRATE = 9; % nominal flow rate of pipe (Kg/s)
PIPE_TBSIN = 10;
PIPE_TBRIN = 11;
PIPE_K = 12; %论文中的lambda
PIPE_F = 13;

NODE = 1;
NODE_LD = 2;
NODE_TSMIN = 3;
NODE_TSMAX = 4;
NODE_TRMIN = 5;
NODE_TRMAX = 6;
NODE_PRMIN = 7;
NODE_PRMAX = 8;
NODE_PLMIN = 9; % 供热负荷所需的最小压差

CHP_PLANT = 1;
CHP_PMIN = 2;
CHP_PMAX = 3;
CHP_HMIN = 4;
CHP_HMAX = 5;
CHP_EFFI = 6;
CHP_MMIN = 7;
CHP_MMAX = 8;
CHP_GEN = 9; % 

CHPPLANT_NO = 1;
CHPPLANT_NODE = 2;

PUMP_NODE = 1;
PUMP_PMIN = 2;
PUMP_PMAX = 3;
PUMP_EFFI = 4;
PUMP_MMIN = 5;
PUMP_MMAX = 6;

% cost of CHP
CHPCOST_H1 = 1;
CHPCOST_H2 = 2;
CHPCOST_HP = 3;

% extreme points of CHP feasible operation region
CHPPT_NPT = 1;
CHPPT_P1 = 2;
CHPPT_H1 = 3;
CHPPT_P2 = 4;
CHPPT_H2 = 5;
CHPPT_P3 = 6;
CHPPT_H3 = 7;
CHPPT_P4 = 8;
CHPPT_H4 = 9;

PUMPCOST_STARTUP = 1;
PUMPCOST_SHUTDOWN = 2;
PUMP_ORDER = 3;
PUMP_P1 = 4;
PUMP_P2 = 5;
PUMP_P3 = 6;
