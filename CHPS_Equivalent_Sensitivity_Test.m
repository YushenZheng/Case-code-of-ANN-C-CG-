clear;clc;
% name = 'small';
% name = 'jilin';
name = 'jilin2';
bSimpleHeat = 0;
EM = true;
delta_pct = 0.5;
budget_pct = [];
budget_pct = [budget_pct, zeros(2, 1)];
budget_pct = [budget_pct, ones(2, 1)];


% if EM
% %     budget_pct = [budget_pct, kron(delta_pct:delta_pct:1-delta_pct, ones(2, 1))];
%     budget_pct = [budget_pct, kron([0.05, 0.1, 0.4, 0.8], ones(2, 1))];
%     budget_pct = [budget_pct, [delta_pct:delta_pct:1; zeros(1,numel(delta_pct:delta_pct:1))]];
%     budget_pct = [budget_pct, [zeros(1,numel(delta_pct:delta_pct:1)); delta_pct:delta_pct:1]];
% end
nBudget = size(budget_pct, 2);

for idx_budget = 1:nBudget
    budget_pct_wind = budget_pct(1, idx_budget);
    budget_pct_hl = budget_pct(2, idx_budget);
    CHPS_Equivalent(name, budget_pct_wind, budget_pct_hl, EM, bSimpleHeat)
end
% monte_carlo;
load chirp
sound(y,Fs)


% sum(sum(abs(ugt_r-ugt_d)))