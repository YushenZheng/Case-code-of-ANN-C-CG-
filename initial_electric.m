%%  1.读取数据
tic;
display('Modelling...');
define_constants;
MIN_DN = 22;
MIN_UP = 23;

global mpc;

if strcmp(name, 'small')
    %   读取电网数据
    mpc = loadcase('case_6bus'); % 6节点系统
    %   读取负荷数据
    mpc.load = sysload_6bus; % 2*6节点系统
    mpc.load(1:end)=mpc.load(1:end).*(0.9+0.2*rand(1,96)');
    % 读取风电数据
    [mpc.windmax, mpc.windmin] = winddata_6bus; % 2*6节点系统
    mpc.windmax(2:end) = mpc.windmax(2:end)*0.7;
    mpc.windmin(2:end) = mpc.windmin(2:end)*0.7;
     %% 增大chp nonload cost，使其尽可能不开机
    dhs_temp = heatcase_006;
    define_heatconstants;
    index_chp2gen = dhs_temp.chp(:,CHP_GEN);
    mpc.gencost(index_chp2gen,7) = mpc.gencost(index_chp2gen,7) + 100;
end

if strcmp(name, 'jilin2')  %% 网上的版本
    mpc = loadcase('case_jilin2'); % 吉林系统
    mpc.load = sysload_jilin2; % 吉林系统
%     mpc.load = sysload_jilin2_reduced; % 吉林系统  负荷从4000减到40%
    mpc.load = mpc.load*0.3;
    mpc.areas(4) = mpc.areas(4)*0.1;  %reduce the requirement of downward reserve %0.1
    [mpc.windmax, mpc.windmin] = winddata_jilin2; % 吉林系统
    % 后面还加大了对弃风的惩罚
    %% 增大chp nonload cost，使其尽可能不开机
    dhs_temp = heatcase_jilin2;
    define_heatconstants;
    index_chp2gen = dhs_temp.chp(:,CHP_GEN);
    mpc.gencost(index_chp2gen,7) = mpc.gencost(index_chp2gen,7) + 40;
    clear dhs_temp
end

if strcmp(name, 'jilin')   %% 临时的不用管：电负荷减半，风机减半，常规机组容量翻倍数量几乎减半，下备用要求减半
    mpc = loadcase('case_jilin'); % 吉林系统
    mpc.load = sysload_jilin; % 吉林系统
    mpc.load(1:end)=mpc.load(1:end).*(0.9+0.2*rand(size(mpc.load,1),size(mpc.load,2)));
    [mpc.windmax, mpc.windmin] = winddata_jilin; % 吉林系统
end

    
% mpc = loadcase('case118_3'); % 118节点系统

% mpc.load = sysload_118_3; % 118节点系统
% mpc.load = sysload_jilin; % 吉林系统


% mpc.load = mpc.load(1,1)*ones(nPrd,1);

% [mpc.windmax, mpc.windmin] = winddata_118_3; % 118节点系统
% [mpc.windmax, mpc.windmin] = winddata_jilin; % 吉林系统


% mpc.windmax(:,2:end) = mpc.windmax(:,2)*ones(1,nPrd);
% mpc.windmin(:,2:end) = mpc.windmin(:,2)*ones(1,nPrd);

mpc.windexp = 0.5*(mpc.windmax+mpc.windmin); % 中间预测值
mpc.windexp(:,2:end) = mpc.windexp(:,2:end).*(0.9+0.2*rand(size(mpc.windexp,1),size(mpc.windexp,2)-1));

mpc.winddel = 0.5*(mpc.windmax-mpc.windmin); % 波动范围
index_wind2gen = mpc.windmax(:,1);

% modify the parameters of wind farms
mpc.gen(index_wind2gen,PMIN) = 0;
mpc.gen(index_wind2gen,PMAX) = Inf;
mpc.gen(index_wind2gen,MIN_UP) = 0;
mpc.gen(index_wind2gen,MIN_DN) = 0;
mpc.gen(index_wind2gen,RAMP_AGC) = Inf;
mpc.gen(index_wind2gen,RAMP_10) = Inf;
toc;

%%  2. 建立ED模型，为CPLEX准备输入
tic;
display('Preparing data...');
%   时段数
mpc.nPrd = nPrd;
t = 0;
mpc.load = mpc.load(1+t:nPrd+t);
mpc.windmax = mpc.windmax(:,[1,2+t:nPrd+t+1]);
mpc.windmin = mpc.windmin(:,[1,2+t:nPrd+t+1]);
mpc.windexp = mpc.windexp(:,[1,2+t:nPrd+t+1]);
mpc.winddel = mpc.winddel(:,[1,2+t:nPrd+t+1]);

load0 = sum(mpc.bus(:,PD)); % 基态负荷
mpc.load0 = load0;
mpc.loadrate = mpc.load/load0;

co_load0=mpc.bus(:,PD);   %基态负荷（6bus独立）---------------------------为了生成每个负荷的loadrate:mpc.loadrate1
lplace=find(co_load0~=0);
load1=co_load0(lplace);
num_load0=length(co_load0);
num_load1=length(load1(:));

co_load1=zeros(num_load1,nPrd);
co_load2=zeros(num_load0,nPrd);
mpc.loadrate1=zeros(num_load0,nPrd);
co_load1=repmat(load1,1,nPrd);

for ti=t+1:t+nPrd
    sum_load1=mpc.load(ti);
    tr=1;
    while tr==1
        co_load1(1:num_load1-1,ti)=mpc.loadrate(ti)*load1(1:num_load1-1).*(0.9+0.2*rand(1,num_load1-1)');
        co_load1(num_load1,ti)=sum_load1-sum(co_load1(1:num_load1-1,ti));
        
        z1=abs(co_load1(1:end,ti))>abs(co_load0(lplace))*2;  %保证每一个load的变化范围在20%-200%之间
        z2=abs(co_load1(1:end,ti))<abs(co_load0(lplace))*0.2;
        z3=co_load1(num_load1,ti)*load1(num_load1);%确保t=24时的load波动后正负号不发生变化
        
        if(all(z1==0)&&all(z2==0)&&z3>0)  
            break;
        end
        continue;
    end
    co_load2(lplace,ti)=co_load1(1:num_load1,ti);
end
mpc.loadrate1(lplace,1:nPrd)=co_load1./repmat(load1,1,nPrd);

% mpc.gen(:,RAMP_AGC) = mpc.gen(:,RAMP_AGC)*dt/60; % 正常爬坡
% mpc.gen(:,RAMP_10) = mpc.gen(:,PMIN);% 开/停机爬坡

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mpc.gen(:,RAMP_AGC) = min(max(mpc.gen(:,RAMP_AGC)*dt/60,mpc.gen(:,PMIN)),mpc.gen(:,PMAX)); % 正常爬坡
mpc.gen(:,RAMP_10) = max(mpc.gen(:,RAMP_AGC),mpc.gen(:,PMIN));% 开/停机爬坡

% mpc.gen(1:2,RAMP_AGC) = mpc.gen(1:2,RAMP_AGC)*0.5;

%   母线数量nBus
nBus = size(mpc.bus,1);
%	机组数量nGen
nGen = size(mpc.gen,1);
%   区域数量nArea
nArea = max(mpc.bus(:,BUS_AREA));
%   支路数量nBranch
nBranch = size(mpc.branch,1);
%   风电场数量nWind
nWind = size(mpc.windmax,1);

mpc.nBus = nBus;
mpc.nGen = nGen;
mpc.nArea = nArea;
mpc.nBranch = nBranch;
mpc.nWind = nWind;

index_nowind2gen = setdiff(1:nGen,index_wind2gen);
nNonwind = length(index_nowind2gen);
mpc.windpen = max(2*mpc.gencost(index_nowind2gen,5).*mpc.gen(index_nowind2gen,PMAX)+mpc.gencost(index_nowind2gen,6));

if strcmp(name, 'jilin2')% || strcmp(name, 'small')  %% 网上的版本，对吉林加大弃风惩罚
    mpc.windpen = 1e1*mpc.windpen;
end

% form the node-generator incidence matrix
jj = (1:nGen)';
ii = mpc.gen(:,GEN_BUS);
im_gen = sparse(ii,jj,ones(nGen,1),nBus,nGen);

% 生成各个机组的分段线性曲线
nSeg = 5; % 分段数
mpc.gencost_pw = zeros(nGen, nSeg+2);
% gencost_pw格式
% 分段功率 成本常数 斜率1 斜率2 ...
for i=1:nGen
    % 分段功率
    mpc.gencost_pw(i,1) = (mpc.gen(i,PMAX)-mpc.gen(i,PMIN))/nSeg;
    % 成本常数项
    mpc.gencost_pw(i,2) = mpc.gencost(i,5)*mpc.gen(i,PMIN)*mpc.gen(i,PMIN) + mpc.gencost(i,6)*mpc.gen(i,PMIN) + mpc.gencost(i,7);
    % 分段斜率
    for j=1:nSeg
        pj = mpc.gen(i,PMIN) + j*mpc.gencost_pw(i,1);
        pj1 = pj-mpc.gencost_pw(i,1);
        dC = mpc.gencost(i,5)*(pj*pj-pj1*pj1) + mpc.gencost(i,6)*(pj-pj1);
        if (mpc.gencost_pw(i,1)>1e-6)
            mpc.gencost_pw(i,2+j) = dC/mpc.gencost_pw(i,1);
        else
            mpc.gencost_pw(i,2+j) = 0;
        end
    end
end