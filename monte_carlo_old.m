clear;clc;
% name = 'small';
name = 'jilin';
% name = 'jilin2';

loop = 1;

% while loop

    NewRun = false;
    EM = true;

    budget_pct = [];
%     budget_pct = [budget_pct, ones(2,1)];
    budget_pct = [budget_pct, [0;1]];
    budget_pct = [budget_pct, zeros(2, 1)];
    % if EM
    %     budget_pct = [budget_pct, kron(delta_pct:delta_pct:1-delta_pct, ones(2, 1))];
    %     budget_pct = [budget_pct, [delta_pct:delta_pct:1; zeros(1,numel(delta_pct:delta_pct:1))]];
    %     budget_pct = [budget_pct, [zeros(1,numel(delta_pct:delta_pct:1)); delta_pct:delta_pct:1]];
    % end
    nBudget = size(budget_pct, 2);    
    nSample = 3e1;

    obj_first_stage_all = inf*ones(nBudget, nSample);
    obj_first_stage_avg = inf*ones(nBudget, 1);
    obj_second_stage_all = inf*ones(nBudget, nSample);
    obj_second_stage_avg = inf*ones(nBudget, 1);
    obj_all = inf*ones(nBudget, nSample);
    obj_avg = inf*ones(nBudget, 1);
    obj_wrst = inf*ones(nBudget, 1);
    feasible_flag_all = zeros(nBudget, nSample);
    time_CCG_all = zeros(nBudget, 1);
    iter_all = zeros(nBudget, 1);
    x_feasible_all = zeros(nBudget, nSample);
    u_feasible_all = zeros(nBudget, nSample);
    y_feasible_all = zeros(nBudget, nSample);

    for idx_budget = 1:nBudget
        budget_pct_wind = budget_pct(1, idx_budget);
        budget_pct_load = budget_pct(2, idx_budget);
        if EM
            load([name,'_wg',num2str(budget_pct_wind),'_hl',num2str(budget_pct_load),'_EM.mat']);
        else 
            load([name,'_wg',num2str(budget_pct_wind),'_hl',num2str(budget_pct_load),'.mat']);
        end
        nU = size(vec_u0,1);

        if NewRun && (idx_budget <= 1)%budget_pct_wind*budget_pct_load >= 1
            du = (vec_du_pos+vec_du_neg)/2; %%%%注意对于budget含0的情况，du人为改为0了，因此要拿不含0的情况来生成样本
            rng('shuffle'); %reset seed
            verification_seed = rng;
           %% normal distribution
            uSample = zeros(nU, nSample);            
            for i = 1:nSample
                uSample(:, i) = normrnd(vec_u0, du/6);
            end
%            %% uniformal distribution
%             uSample = kron(vec_u0-vec_du_neg,ones(1,nSample))+rand(nU,nSample).*kron(vec_du_pos+vec_du_neg,ones(1,nSample));            
            save([name,'_samples.mat'], 'uSample', 'verification_seed');
        else
            load([name,'_samples.mat'], 'uSample', 'verification_seed');
        end

        nSample = size(uSample, 2);
        nYvar = numel(index_var_second);

%         y_optimal_all = zeros(nYvar, nSample);

        shown = 0; pop = 0;
        for i = 1:nSample
            u_star_test = uSample(:, i);
            [ obj_first_stage_all(idx_budget, i), obj_second_stage_all(idx_budget, i), y_optimal_temp, x_feasible_all(idx_budget, i), u_feasible_all(idx_budget, i) ] ...
                = CCG_validate( mat_A, mat_B, mat_C, mat_D, mat_F, mat_G, vec_b, vec_c, vec_d, vec_e, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, x_optimal, u_star_test);
            if sum(isnan(y_optimal_temp)) > 0
                y_feasible_all(idx_budget, i) = 0;
            else
                y_feasible_all(idx_budget, i) = 1;
            end
            pop = floor(i/nSample*10);
            if pop>shown
                shown = pop;
                display(sprintf('[%.1f%%] of the %d Monte Carlo simulation samples tested.', i/nSample*100, nSample));
            end
        end

        obj_first_stage_avg(idx_budget) = mean(obj_first_stage_all(idx_budget, y_feasible_all(idx_budget, :)>0));
        obj_second_stage_avg(idx_budget) = mean(obj_second_stage_all(idx_budget, y_feasible_all(idx_budget, :)>0));
        obj_avg(idx_budget) = obj_first_stage_avg(idx_budget)+obj_second_stage_avg(idx_budget);
        obj_all(idx_budget, :) = obj_first_stage_all(idx_budget, :)+obj_second_stage_all(idx_budget, :);
        obj_wrst(idx_budget) = max(obj_all(idx_budget, y_feasible_all(idx_budget, :)>0));
%         feasible_rate(idx_budget) = round(sum(y_feasible_all(idx_budget, :)))/nSample;
        time_CCG_all(idx_budget) = time_CCG;
        iter_all(idx_budget) = iter_CCG;
        if EM
            save([name, '_wg',num2str(budget_pct_wind),'_hl',num2str(budget_pct_load), '_EM_verify.mat']);
        else
            save([name, '_wg',num2str(budget_pct_wind),'_hl',num2str(budget_pct_load), '_verify.mat']);
        end
    end
    feasible_rate
%     if feasible_rate(1) >= 0.995 && feasible_rate(2) < 0.9
%         loop = 0;
%     end    
% end
if EM
    save([name, '_EM_verify_sum.mat'],'budget_pct','obj_first_stage_avg','obj_second_stage_avg',...
        'obj_avg','obj_wrst','feasible_rate','time_CCG_all','iter_all');
else
    save([name, '__verify_sum.mat'],'budget_pct','obj_first_stage_avg','obj_second_stage_avg',...
        'obj_avg','obj_wrst','feasible_rate','time_CCG_all','iter_all');
end
yval = y_optimal_temp;
solution = zeros(nHvar, 1);
solution(index_var_first) = x_optimal;
solution(index_var_second) = yval;
% [solution(index_var_pg(index_wind2gen,:)), u_star_test(index_var_wind_max)]