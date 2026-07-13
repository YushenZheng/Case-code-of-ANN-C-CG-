% 定义热网模型有关常数
define_heatconstants;

% 读取模型
global dhs;
if strcmp(name, 'small')
    dhs = heatcase_006;
    dhs.pipe(:,PIPE_FLOWRATE) = dhs.pipe(:,PIPE_FLOWRATE)*0.9;
end
if strcmp(name, 'jilin2')
    dhs = heatcase_jilin2;
    dhs.pipe(:,PIPE_FLOWRATE) = dhs.pipe(:,PIPE_FLOWRATE)*0.85;
    dhs.load = dhs.load*0.63; %min: 0.3 只有一个热机组( max 0.7)；最高1.1; m  %0.65, 0.63
%     dhs.chppt(:, 2:end) = dhs.chppt(:, 2:end);
    % 3~6: Tsmin	Tsmax	Trmin	Trmax: 110	120	60	80
    dhs.node(:, 3) = 100;
    dhs.node(:, 4) = 120;
    dhs.node(:, 5) = 70;
    dhs.node(:, 6) = 100;
    %后面会加大CHP的nonload cost，使得CHP尽可能少开机
end
if strcmp(name, 'jilin')
    dhs = heatcase_jilin;   %flowrate减半，chp减半，热负荷减半
end
% dhs = heatcase_006_extreme;
% dhs = heatcase_008;
% dhs = heatcase_Ishoej;

nPipe = size(dhs.pipe,1); % 管道个数
nNode = size(dhs.node,1); % 节点个数
nChp = size(dhs.chp,1); % 热电机组个数
% nPump = size(dhs.pump,1); % 水泵个数
nLoad = nnz(dhs.node(:,NODE_LD)); % 热负荷节点个数
nChpplant = size(dhs.chpplant,1); % # of CHP plants 合并后

dhs.nPipe = nPipe;
dhs.nNode = nNode;
dhs.nChp = nChp;
% dhs.nPump = nPump;
dhs.nLoad = nLoad;
dhs.nPrd = nPrd;
dhs.dt = dt;

index_chp2gen = dhs.chp(:,CHP_GEN);
index_nonchp2gen = setdiff(index_nowind2gen,dhs.chp(:,CHP_GEN)); % non-chp thermal units
nNonchp = length(index_nonchp2gen);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% WC: 为何这么算？
% 计算温度衰减系数
dhs.pipe(:,PIPE_K) = dhs.pipe(:,PIPE_COND).*dhs.pipe(:,PIPE_L)/dhs.water_c;

% 计算流体摩擦阻力相关系数
temp = ((log(dhs.pipe(:,PIPE_RF)/3.71./dhs.pipe(:,PIPE_DM))/log(10)).^(-2))/4;
temp = temp * 8.*dhs.pipe(:,PIPE_L)/(pi^2)/dhs.water_dens./(dhs.pipe(:,PIPE_DM).^5);
dhs.pipe(:,PIPE_F) = temp;

% dhs.load = dhs.load(1,1)*ones(nPrd,1);

dhs.loadrate = dhs.load/sum(dhs.node(:,NODE_LD));

% 建立支路-节点关联矩阵(incidence matrix）
ii = [(1:nPipe)';(1:nPipe)'];
jj = [dhs.pipe(:,PIPE_FROM);dhs.pipe(:,PIPE_TO)];
ss = [ones(nPipe,1);-ones(nPipe,1)];
im_pipe = sparse(jj, ii, ss, nNode, nPipe);
im_pipe_pos = max(im_pipe,0);
im_pipe_neg = im_pipe_pos - im_pipe;

% 建立热源-节点关联矩阵
ii = (1:nChpplant)';
jj = dhs.chpplant(:,CHPPLANT_NODE);
ss = ones(nChpplant,1);
im_chp = sparse(jj, ii, ss, nNode, nChpplant);

% 建立热负荷-节点关联矩阵
index_load_new2old = find(dhs.node(:,NODE_LD));
ii = (1:nLoad)';
jj = dhs.node(index_load_new2old,NODE);
ss = ones(nLoad,1);
im_load = sparse(jj, ii, ss, nNode, nLoad);

%% 计算管道流速
vs = zeros(nPipe,nPrd); % 供水管流速
vr = vs; % 回水管流速
vs = dhs.pipe(:,PIPE_FLOWRATE)/dhs.water_dens*4/pi./dhs.pipe(:,PIPE_DM).^2*ones(1,nPrd);
vr = vs;
vs0 = vs;
vr0 = vr;

% 创造虚拟的历史记录，包括管道温度和流速
tbsin0 = dhs.pipe(:,PIPE_TBSIN)*ones(1,nPrd);
tbrin0 = dhs.pipe(:,PIPE_TBRIN)*ones(1,nPrd);

%% 计算node method中的n和m
calmn;

%% 计算热源流质  %%WC: 其实只考虑了源、荷只位于度为1的节点
MG = sparse(nChpplant, nChpplant);
for i=1:nChpplant
%     index_chp = find(dhs.chp(:,CHP_PLANT)==i);  %未合的chp编号
    node = dhs.chpplant(i,CHPPLANT_NODE);
    pipe = find(dhs.pipe(:,PIPE_FROM)==node | dhs.pipe(:,PIPE_TO)==node );  %%WC
    MG(i, i) = dhs.pipe(pipe,PIPE_FLOWRATE);
end

%% 计算热荷流质   %%WC: 其实只考虑了源、荷只位于度为1的节点
MD = sparse(nLoad, nLoad);
for i=1:nLoad
    node = index_load_new2old(i);
    pipe = find(dhs.pipe(:,PIPE_FROM)==node | dhs.pipe(:,PIPE_TO)==node );
    MD(i, i) = dhs.pipe(pipe,PIPE_FLOWRATE);
end

%% 计算分布因子矩阵
DPS = sparse(nPipe, nPipe);
DPR = sparse(nPipe, nPipe);
DGS = sparse(nChpplant, nChpplant);
DDR = sparse(nLoad, nLoad);
for node=1:nNode
    pipe_up = find(dhs.pipe(:,PIPE_TO)==node); %可能多个
    n_pipe_up = numel(pipe_up);
    if n_pipe_up > 0
        m_pipe_up = zeros(n_pipe_up, 1);
        for p = 1:n_pipe_up
            pipe = pipe_up(p);
            m_pipe_up(p) = dhs.pipe(pipe,PIPE_FLOWRATE);
        end
    else
        m_pipe_up = 0;
    end
    
    pipe_down = find(dhs.pipe(:,PIPE_FROM)==node); %可能多个
    n_pipe_down = numel(pipe_down);
    if n_pipe_down > 0
        m_pipe_down = zeros(n_pipe_down, 1);
        for p = 1:n_pipe_down
            pipe = pipe_down(p);
            m_pipe_down(p) = dhs.pipe(pipe,PIPE_FLOWRATE);
        end
    else
        m_pipe_down = 0;
    end
    
    g = find(im_chp(node,:)>0);
    n_g = numel(g);
    if n_g > 0
        pipe = [pipe_up, pipe_down];    %忽略了热源在中间节点的情况
        m_g = dhs.pipe(pipe,PIPE_FLOWRATE);
    else
        m_g = 0;
    end
    
    d = find(im_load(node,:)>0);
    n_d = numel(d);
    if n_d > 0
        pipe = [pipe_up, pipe_down];    %忽略了热荷在中间节点的情况
        m_d = dhs.pipe(pipe,PIPE_FLOWRATE);
    else
        m_d = 0;
    end
    
    demoninator_s = sum(m_pipe_up)+sum(m_g);    
    demoninator_r = sum(m_pipe_down)+sum(m_d);
    
    if n_pipe_up > 0
        for p = 1:n_pipe_up
            pipe = pipe_up(p);
            DPS(pipe, pipe) = m_pipe_up(p)/demoninator_s;
        end
    end
    
    if n_g > 0
        pipe = [pipe_up, pipe_down];    %忽略了热源在中间节点的情况
        m_g = dhs.pipe(pipe,PIPE_FLOWRATE);
        DGS(g, g) = m_g/demoninator_s;
    end
    
    if n_pipe_down > 0
        for p = 1:n_pipe_down
            pipe = pipe_down(p);
            DPR(pipe, pipe) = m_pipe_down(p)/demoninator_r;
        end
    end
    
    if n_d > 0
        pipe = [pipe_up, pipe_down];    %忽略了热荷在中间节点的情况
        m_d = dhs.pipe(pipe,PIPE_FLOWRATE);
        DDR(d, d) = m_d/demoninator_r;
    end    
end