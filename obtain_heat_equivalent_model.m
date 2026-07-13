%% obtain constant matrixs and vectors in the heat equivalent model
Kmat = cell2mat(Kcell);
Jmat = cell2mat(Jcell);

%% vectors
tA = kron(dhs.t0(1:nPrd), ones(nPipe, 1)); %前面是系数，后面是移动的块
dT = kron(dhs.loadrate(1:nPrd), dhs.node(index_load_new2old,NODE_LD));

%% matrices
As_neg = kron(speye(nPrd), im_pipe_neg);
As_pos = kron(speye(nPrd), im_pipe_pos);
Ar_neg = As_pos; 
Ar_pos = As_neg;
Ag = kron(speye(nPrd), im_chp);
Ad = kron(speye(nPrd), im_load);
Phi = Jmat*Kmat;
DPST = kron(speye(nPrd), DPS);
DPRT = kron(speye(nPrd), DPR);
DGST = kron(speye(nPrd), DGS);
DDRT = kron(speye(nPrd), DDR);
MGT = kron(speye(nPrd), MG)/dhs.base;
MDT = kron(speye(nPrd), MD)/dhs.base;

%% derivation
t_PS_A = cell2mat(tpsA_cell);
t_PR_A = cell2mat(tprA_cell);
tic;
Qs = speye(nPipe*nPrd) - As_pos'*As_neg*DPST*Phi;
Qs_inv = speye(nPipe*nPrd)/Qs;
Qr = speye(nPipe*nPrd) - Ar_pos'*Ar_neg*DPRT*Phi;
Qr_inv = speye(nPipe*nPrd)/Qr;

Y_PSin_GS = Qs_inv*As_pos'*Ag*DGST;
t_PSin_GS = Qs_inv*As_pos'*As_neg*DPST*t_PS_A;
Y_PRin_DR = Qr_inv*Ar_pos'*Ad*DDRT;
t_PRin_DR = Qr_inv*Ar_pos'*Ar_neg*DPRT*t_PR_A;

Y_PSout_GS = Phi*Y_PSin_GS;
t_PSout_GS = Phi*t_PSin_GS+t_PS_A;
Y_PRout_DR = Phi*Y_PRin_DR;
t_PRout_DR = Phi*t_PRin_DR+t_PR_A;

Y_DS_GS = Ad'*(As_neg*DPST*Y_PSout_GS+Ag*DGST);
t_DS_GS = Ad'*As_neg*DPST*t_PSout_GS;
Y_GR_DR = Ag'*(Ar_neg*DPRT*Y_PRout_DR+Ad*DDRT);
t_GR_DR = Ag'*Ar_neg*DPRT*t_PRout_DR;

Y_g_GS = dhs.water_c*MGT*(speye(nChpplant*nPrd) - Y_GR_DR*Y_DS_GS);
Y_g_d = MGT*Y_GR_DR/MDT;
g_hat = -dhs.water_c*MGT*(t_GR_DR+Y_GR_DR*t_DS_GS);


Y_NS_GS = As_neg*DPST*Phi*Qs_inv*As_pos'*Ag*DGST + Ag*DGST;
% t_PSout_GS = (Phi*Qs_inv*As_pos'*As_neg*DPST*t_PS_A + t_PS_A);
t_NS_GS = As_neg*DPST*t_PSout_GS;
% 
Y_NR_DR = Ar_neg*DPRT*Phi*Qr_inv*Ar_pos'*Ad*DDRT + Ad*DDRT;
% Y_DS_GS = Ad'*(As_neg*DPST*Phi*Qs_inv*As_pos'*Ag*DGST + Ag*DGST);
Y_NR_GS = Y_NR_DR*Y_DS_GS;
% t_PRout_DR = (Phi*Qr_inv*Ar_pos'*Ar_neg*DPRT*t_PR_A + t_PR_A);
t_NR_GS = Ar_neg*DPRT*t_PRout_DR+Y_NR_DR*t_DS_GS;
Y_NR_d = -1/dhs.water_c*Y_NR_DR/MDT;
% 
% t_DS_GS = Ad'*As_neg*DPST*t_PSout_GS;
% t_GR_DR = Ag'*Ar_neg*DPRT*t_PRout_DR;
% Y_GR_DR = Ag'*(Ar_neg*DPRT*Phi*Qr_inv*Ar_pos'*Ad*DDRT + Ad*DDRT);
% Y_g_GS = dhs.water_c*MGT*(speye(nChpplant) - Y_GR_DR*Y_DS_GS);
% Y_g_d = MGT*Y_GR_DR/MDT;
% g_hat = -dhs.water_c*MGT*(t_GR_DR+Y_GR_DR*t_DS_GS);
timeEM = toc;