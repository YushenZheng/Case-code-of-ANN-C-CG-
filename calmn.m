nPrd0 = size(vs0,2);
nn = zeros(nPipe,nPrd0);
mm = nn;
ttr = sparse(nPipe*nPrd,nPrd0+nPrd); % temporal temperature correlation[0, 1, 2, ..., nPrd] WC:稀疏结构不支持多维数组，此处idx_col为t-delta_t的delta_t
ttr_map = zeros(nPipe,nPrd0);  %实现三维稀疏数组

Kcell = cell(nPrd, nPrd);
Jcell = cell(nPrd, nPrd);
tpsA_cell = cell(nPrd, 1);
tprA_cell = cell(nPrd, 1);

tpsout_hat = zeros(nPipe*nPrd,1);
tprout_hat = zeros(nPipe*nPrd,1);

%init
for ti = 1:nPrd
    tpsA_cell{ti} = zeros(nPipe, 1);
    tprA_cell{ti} = zeros(nPipe, 1);
    for tj = 1:nPrd
        Kcell{ti, tj} = sparse(nPipe, nPipe);
        Jcell{ti, tj} = sparse(nPipe, nPipe);
    end
end

count = 0;
for t=1:nPrd
    for p=1:nPipe
        count = count + 1;
        ttr_map(p,t) = count;
        
        % 计算m(i.e., phi),n(i.e., gamma),R(相当于对论文中R/(rho*A)),Z
        n = 0;
        R = 0;
        while (1)
            temp = sum(vs(p,max(t-n,1):t)); %WC: 对应UC eq.(15)
            temp = temp + sum(vs0(p,t-n+nPrd0:nPrd0));
            R = dt*temp;
            if ( R>dhs.pipe(p,PIPE_L) )
                break;
            end
            n = n + 1;
        end
        
        m = n;
        while (1)
            temp = sum(vs(p,max(t-m,1):t));
            temp = temp + sum(vs0(p,t-m+nPrd0:nPrd0));
            if ( dt*temp>(dhs.pipe(p,PIPE_L)+vs(p,t)*dt) )
                break;
            end
            m = m + 1;
        end
        if ( m>n )
            temp = sum(vs(p,max(t-m+1,1):t));
            temp = temp + sum(vs0(p,t-m+1+nPrd0:nPrd0));
            S = dt*temp; %WC: eq.(18)
        else
            S = R;
        end
                
        mm(p,t) = m;
        nn(p,t) = n;
        SS(p,t) = S;
        RR(p,t) = R;
        
        % 计算时间相关系数
        ttr(count,n+1) = (R-dhs.pipe(p,PIPE_L))/vs(p,t)/dt; %k=t-gamma in eq.(20), n+1是因为n可能为0
        if ( m>=n+2 ) %在这个条件下，才存在这一类
            for i = m-1:n+1
                if ( t-i>=1 )
                    ttr(count,i+1) = ttr(count,i+1) + vs(p,t-i)/vs(p,t);
                else
                    ttr(count,i+1) = ttr(count,i+1) + vs0(p,t-i+nPrd0)/vs(p,t); 
                end
            end
        end
        ttr(count,m+1) = ttr(count,m+1) + (1-(S-dhs.pipe(p,PIPE_L))/vs(p,t)/dt); %k=t-phi in eq.(20)
    end
end

% 计算温度衰减系数K1和K2
K1 = zeros(nPipe,nPrd);
K2 = K1;
JJ = K1;
for t=1:nPrd
    for p=1:nPipe
        K1(p,t) = dhs.pipe(p,PIPE_K)*(nn(p,t)+0.5)*dt/dhs.water_c/dhs.water_dens*4/pi/dhs.pipe(p,PIPE_DM)^2;
        %K2(p,t) = dhs.pipe(p,PIPE_K)*(SS(p,t)-RR(p,t))/dhs.water_c;        %原版有错误，漏了一项
        K2(p,t) = dhs.pipe(p,PIPE_K)*(SS(p,t)-RR(p,t))/dhs.water_c/dhs.water_dens*4/pi/dhs.pipe(p,PIPE_DM)^2;   %corrected by WC
        JJ(p,t) = exp(-K1(p,t)-K2(p,t)/dhs.pipe(p,PIPE_FLOWRATE));
    end
    Jcell{t, t} = sparse(diag(JJ(:, t)));
end

for t=1:nPrd
    for p=1:nPipe
        temp = ttr(ttr_map(p,t),:);
        temp1 = fliplr(temp(1:t));
        temp2 = fliplr(temp(t+1:nPrd0));
%         Aeq(index_con_tbsout(p,t),index_var_tbsout(p,t)) = 1;
%         Aeq(index_con_tbsout(p,t),index_var_tbsin(p,1:t)) = -JJ(p,t)*temp1;
%         beq(index_con_tbsout(p,t)) = (1-JJ(p,t))*dhs.t0(t) + JJ(p,t)*temp2*tbsin0(p,t+1:nPrd0)';
        for tj = 1:t
            Kcell{t, tj}(p, p) = temp1(tj);
        end

        idx = (t-1)*nPipe+p;
        tpsout_hat(idx) = temp2*tbsin0(p,t+1:nPrd0)';
        tpsA_cell{t}(p) = (1-JJ(p,t))*dhs.t0(t) + JJ(p,t)*tpsout_hat(idx);
        
%         Aeq(index_con_tbrout(p,t),index_var_tbrout(p,t)) = 1;
%         Aeq(index_con_tbrout(p,t),index_var_tbrin(p,1:t)) = -JJ(p,t)*temp1;
%         beq(index_con_tbrout(p,t)) = (1-JJ(p,t))*dhs.t0(t) + JJ(p,t)*temp2*tbrin0(p,t+1:nPrd0)';

        tprout_hat(idx) = temp2*tbrin0(p,t+1:nPrd0)';
        tprA_cell{t}(p) = (1-JJ(p,t))*dhs.t0(t) + JJ(p,t)*tprout_hat(idx);
    end
end