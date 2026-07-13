%% Define cost coefficients
% 1. Dispatch cost of non-CHP units
% f = sum (cost(seg)*pgpw(seg))
for t=1:nPrd
    for i=1:nNonchp
        f(index_var_pgpw(i,t,:)) = mpc.gencost_pw(index_nonchp2gen(i),2+(1:nSeg));
    end
end

% 2. Operation cost of CHP units
for i=1:nChp
    % f = a*p + b*p^2 + c*h + d*h^2 + e*p*h
    a = mpc.gencost(index_chp2gen(i),6);
    b = mpc.gencost(index_chp2gen(i),5);
    c = dhs.chpcost(i,1);
    d = dhs.chpcost(i,2);
    e = dhs.chpcost(i,3);
    
    for k=1:dhs.chppt(i,CHPPT_NPT)
        p = dhs.chppt(i,CHPPT_NPT+2*k-1);
        h = dhs.chppt(i,CHPPT_NPT+2*k);
        cost = a*p + b*p*p + c*h + d*h*h + e*p*h; %极点对应的成本
        f(index_var_achp(i,:,k)) = cost; 
    end
end

% 3. Commitment cost of non-wind units
for i=1:nNonwind
    % no-load cost
    f(index_var_ugt(index_nowind2gen(i),:)) = mpc.gencost_pw(index_nowind2gen(i),2);
    f(index_var_xgt(index_nowind2gen(i),:)) = mpc.gencost(index_nowind2gen(i),1);
    f(index_var_ygt(index_nowind2gen(i),:)) = mpc.gencost(index_nowind2gen(i),2);
end

% 4. Penalty cost of wind farms
for i=1:nWind
    f(index_var_pg(index_wind2gen(i),:)) = -mpc.windpen;
%     f(index_var_ugt(index_wind2gen(i),:)) = mpc.windpen*ub(index_var_pg(index_wind2gen(i),:));
end

%碳交易
pi_co2 = 0.5;%碳交易价格
E_chp = 0.5647; e_chp = 0.424; %CHP每kwh供电的碳排放强度/定额
E_tu = 0.5647; e_tu = 0.152; %TU每kwh供电的碳排放强度/定额

for t=1:nPrd
    for i=1:nChp
        f(index_var_pg(index_chp2gen(i),t)) = f(index_var_pg(index_chp2gen(i),t)) + pi_co2*(E_chp-e_chp);
    end
end
for t=1:nPrd
    for i=1:nChpplant
         f(index_var_qchpplant(i,t)) = f(index_var_qchpplant(i,t)) + pi_co2*(E_chp-e_chp);
    end
end


for t=1:nPrd
    for i=1:nNonchp
        f(index_var_pgpw(i,t,:)) = f(index_var_pgpw(i,t,:)) + pi_co2*(E_tu-e_tu);
    end
end
