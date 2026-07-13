%% Define constraint indices
% 1. Polyhedarl operating region
index_con_pachp = zeros(nChp,nPrd);
index_con_pachp(:) = nEq+1:nEq+nChp*nPrd;
nEq = nEq + nChp*nPrd;

index_con_qachp = zeros(nChp,nPrd);
index_con_qachp(:) = nEq+1:nEq+nChp*nPrd;
nEq = nEq + nChp*nPrd;

index_con_auchp = zeros(nChp,nPrd);
index_con_auchp(:) = nEq+1:nEq+nChp*nPrd;
nEq = nEq + nChp*nPrd;

% 2. Power balance constraints
index_con_pb = zeros(1,nPrd);
index_con_pb(:) = nEq+1:nEq+nPrd;
nEq = nEq + nPrd;

% 3. Spinning reserve constraints
index_con_ru = zeros(nGen,nPrd);
for i=1:nGen
    if ( mpc.gen(i,MIN_UP)==1 )
        index_con_ru(i,:) = (1:nPrd)*2-1+nIneq;
        nIneq = nIneq + 2*nPrd;
    else
        index_con_ru(i,:) = nIneq+1:nIneq+nPrd;
        nIneq = nIneq + nPrd;
    end
end

index_con_rd = zeros(nGen,nPrd);
index_con_rd(:) = nIneq+1:nIneq+nGen*nPrd;
nIneq = nIneq + nGen*nPrd;

index_con_reserveUp = zeros(1,nPrd);
index_con_reserveUp(:) = nIneq+1:nIneq+nPrd;
nIneq = nIneq + nPrd;

index_con_reserveDn = zeros(1,nPrd);
index_con_reserveDn(:) = nIneq+1:nIneq+nPrd;
nIneq = nIneq + nPrd;

% 4. Ramping constraints
index_con_rampUp = zeros(nGen,nPrd);
index_con_rampUp(:) = nIneq+1:nIneq+nGen*nPrd;
nIneq = nIneq + nGen*nPrd;

index_con_rampDn = zeros(nGen,nPrd);
index_con_rampDn(:) = nIneq+1:nIneq+nGen*nPrd;
nIneq = nIneq + nGen*nPrd;

% 5. Logic constraints of generation unit status
index_con_logic = zeros(nGen,nPrd);
index_con_logic(:) = nEq+1:nEq+nGen*nPrd;
nEq = nEq + nGen*nPrd;

% 6. Minimum down/uptime constraints
index_con_timeUp = zeros(nGen,nPrd);
index_con_timeUp(:) = nIneq+1:nIneq+nGen*nPrd;
nIneq = nIneq + nGen*nPrd;

index_con_timeDn = zeros(nGen,nPrd);
index_con_timeDn(:) = nIneq+1:nIneq+nGen*nPrd;
nIneq = nIneq + nGen*nPrd;

% 7. Piecewise generation output of non-CHP units
index_con_piecewise = zeros(nNonchp,nPrd);
index_con_piecewise(:) = nEq+1:nEq+nNonchp*nPrd;
nEq = nEq + nNonchp*nPrd;