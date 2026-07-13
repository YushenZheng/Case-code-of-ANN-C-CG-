%% Define constraints for the master UC problem
% 1. Polyhedarl operating region
% eq. (1)
for t=1:nPrd
    for i=1:nChp
        Aeq(index_con_pachp(i,t),index_var_pg(index_chp2gen(i),t)) = 1;
        Aeq(index_con_qachp(i,t),index_var_qchp(i,t)) = 1;
        for k=1:dhs.chppt(i,CHPPT_NPT)
            Aeq(index_con_pachp(i,t),index_var_achp(i,t,k)) = -(dhs.chppt(i,CHPPT_NPT+2*k-1)-dhs.chp(i,CHP_PMIN));
            Aeq(index_con_qachp(i,t),index_var_achp(i,t,k)) = -(dhs.chppt(i,CHPPT_NPT+2*k)-dhs.chp(i,CHP_HMIN));
        end
        beq(index_con_pachp(i,t)) = 0;
        beq(index_con_qachp(i,t)) = 0;
    end
end

% sum(alpha) - u = 0
for t=1:nPrd
    for i=1:nChp
        Aeq(index_con_auchp(i,t),index_var_achp(i,t,1:dhs.chppt(i,CHPPT_NPT))) = 1;
        Aeq(index_con_auchp(i,t),index_var_ugt(index_chp2gen(i),t)) = -1;
        beq(index_con_auchp(i,t)) = 0;        
    end
end

% 2. Power balance constraints
%eq (28)
for t=1:nPrd
    Aeq(index_con_pb(t),index_var_pg(:,t)) = 1;
    Aeq(index_con_pb(t),index_var_ugt(:,t)) = mpc.gen(:,PMIN);
    beq(index_con_pb(t)) = mpc.load(t);
end

% 3. Spinning reserve constraints
%待读
for i=1:nGen   
    mpc.gen(i,RAMP_10) = mpc.gen(i,PMIN);
    if ( mpc.gen(i,MIN_UP)==1 )
        Aineq(index_con_ru(i,:),index_var_pg(i,:)) = speye(nPrd);
        Aineq(index_con_ru(i,:),index_var_ru(i,:)) = speye(nPrd);
        Aineq(index_con_ru(i,:),index_var_ugt(i,:)) = -(mpc.gen(i,PMAX)-mpc.gen(i,PMIN))*speye(nPrd);
        Aineq(index_con_ru(i,:),index_var_xgt(i,:)) = (mpc.gen(i,PMAX)-mpc.gen(i,RAMP_10))*speye(nPrd);
        bineq(index_con_ru(i,:)) = 0;
        
        Aineq(index_con_ru(i,1:nPrd-1)+1,index_var_pg(i,1:nPrd-1)) = speye(nPrd-1);
        Aineq(index_con_ru(i,1:nPrd-1)+1,index_var_ru(i,1:nPrd-1)) = speye(nPrd-1);
        Aineq(index_con_ru(i,1:nPrd-1)+1,index_var_ugt(i,1:nPrd-1)) = -(mpc.gen(i,PMAX)-mpc.gen(i,PMIN))*speye(nPrd-1);
        Aineq(index_con_ru(i,1:nPrd-1)+1,index_var_ygt(i,2:nPrd)) = (mpc.gen(i,PMAX)-mpc.gen(i,RAMP_10))*speye(nPrd-1);
        bineq(index_con_ru(i,1:nPrd-1)+1) = 0;  
    end
    
    if ( mpc.gen(i,MIN_UP)>=2 )
        Aineq(index_con_ru(i,1:nPrd-1),index_var_pg(i,1:nPrd-1)) = speye(nPrd-1);
        Aineq(index_con_ru(i,1:nPrd-1),index_var_ru(i,1:nPrd-1)) = speye(nPrd-1);
        Aineq(index_con_ru(i,1:nPrd-1),index_var_ugt(i,1:nPrd-1)) = -(mpc.gen(i,PMAX)-mpc.gen(i,PMIN))*speye(nPrd-1);
        Aineq(index_con_ru(i,1:nPrd-1),index_var_xgt(i,1:nPrd-1)) = (mpc.gen(i,PMAX)-mpc.gen(i,RAMP_10))*speye(nPrd-1);
        Aineq(index_con_ru(i,1:nPrd-1),index_var_ygt(i,2:nPrd)) = (mpc.gen(i,PMAX)-mpc.gen(i,RAMP_10))*speye(nPrd-1);
        bineq(index_con_ru(i,1:nPrd-1)) = 0;           
    end
end

% eq (32)
for i=1:nGen
    Aineq(index_con_rd(i,:),index_var_rd(i,:)) = speye(nPrd);
    Aineq(index_con_rd(i,:),index_var_pg(i,:)) = -speye(nPrd);
    bineq(index_con_rd(i,:)) = 0;
end

% eq (33)
for t=1:nPrd
    Aineq(index_con_reserveUp(t),index_var_ru(:,t)) = -1;
    bineq(index_con_reserveUp(t)) = -mpc.areas(1,3);
end
for t=1:nPrd
    Aineq(index_con_reserveDn(t),index_var_rd(:,t)) = -1;
    bineq(index_con_reserveDn(t)) = -mpc.areas(1,4);
end

% 4. Ramping constraints
% eq (34)
% 此处t即为nPrd
for i=1:nGen
    Aineq(index_con_rampUp(i,2:t),index_var_pg(i,2:t)) = Aineq(index_con_rampUp(i,2:t),index_var_pg(i,2:t))+speye(nPrd-1);
    Aineq(index_con_rampUp(i,2:t),index_var_pg(i,1:t-1)) = Aineq(index_con_rampUp(i,2:t),index_var_pg(i,1:t-1))-speye(nPrd-1);
    bineq(index_con_rampUp(i,2:t)) = mpc.gen(i,RAMP_AGC);
    
    Aineq(index_con_rampDn(i,2:t),index_var_pg(i,2:t)) = Aineq(index_con_rampDn(i,2:t),index_var_pg(i,2:t))-speye(nPrd-1);
    Aineq(index_con_rampDn(i,2:t),index_var_pg(i,1:t-1)) = Aineq(index_con_rampDn(i,2:t),index_var_pg(i,1:t-1))+speye(nPrd-1);
    bineq(index_con_rampDn(i,2:t)) = mpc.gen(i,RAMP_AGC);
end

% 5. Logic constraints of generation unit status
% eq (36)
for i=1:nGen
    Aeq(index_con_logic(i,2:nPrd),index_var_ugt(i,2:nPrd)) = Aeq(index_con_logic(i,2:nPrd),index_var_ugt(i,2:nPrd)) + speye(nPrd-1);  %对应的系数分别为1和-1
    Aeq(index_con_logic(i,2:nPrd),index_var_ugt(i,1:nPrd-1)) = Aeq(index_con_logic(i,2:nPrd),index_var_ugt(i,1:nPrd-1))-speye(nPrd-1);
    Aeq(index_con_logic(i,2:nPrd),index_var_xgt(i,2:nPrd)) = Aeq(index_con_logic(i,2:nPrd),index_var_xgt(i,2:nPrd))-speye(nPrd-1);
    Aeq(index_con_logic(i,2:nPrd),index_var_ygt(i,2:nPrd)) = Aeq(index_con_logic(i,2:nPrd),index_var_ygt(i,2:nPrd))+speye(nPrd-1);
    beq(index_con_logic(i,2:nPrd)) = 0;
end

% 6. Minimum down/uptime constraints
% eq (37)-(38)
for i=1:nGen
    if (mpc.gen(i,MIN_UP)==0)
        continue;
    end
    for t=1:nPrd
        Aineq(index_con_timeUp(i,t),index_var_xgt(i,max(1,t-mpc.gen(i,MIN_UP)+1):t)) = 1;
        Aineq(index_con_timeUp(i,t),index_var_ugt(i,t)) = -1;
        bineq(index_con_timeUp(i,t)) = 0;
        
        Aineq(index_con_timeDn(i,t),index_var_ygt(i,max(1,t-mpc.gen(i,MIN_DN)+1):t)) = 1;
        Aineq(index_con_timeDn(i,t),index_var_ugt(i,t)) = 1;
        bineq(index_con_timeDn(i,t)) = 1;
    end
end

% 7. Piecewise generation output of non-CHP units
% pg = sum (pgpw(seg))
for t=1:nPrd
    for i=1:nNonchp
        Aeq(index_con_piecewise(i,t),index_var_pg(index_nonchp2gen(i),t)) = 1;
        Aeq(index_con_piecewise(i,t),index_var_pgpw(i,t,1:nSeg)) = -1;
        beq(index_con_piecewise(i,t)) = 0;
    end
end