%% Calculate the weighted average temperature of hot water in the DHN
average_temp = zeros(nPrd,1);

pipe_vol = dhs.pipe(:,PIPE_L)' * dhs.pipe(:,PIPE_DM).^2;

for t=1:nPrd
    pipe_temp_supply = (x(index_var_tbsin(:,t)) + x(index_var_tbsout(:,t)))/2 .* dhs.pipe(:,PIPE_L) .* dhs.pipe(:,PIPE_DM).^2;
    pipe_temp_return = (x(index_var_tbrin(:,t)) + x(index_var_tbrout(:,t)))/2 .* dhs.pipe(:,PIPE_L) .* dhs.pipe(:,PIPE_DM).^2;
    average_temp(t) = sum(pipe_temp_supply+pipe_temp_return)/2/pipe_vol;
end