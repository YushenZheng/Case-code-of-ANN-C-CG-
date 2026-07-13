clear;clc;
name = 'small';
% name = 'jilin';
% name = 'jilin2';
if strcmp(name, 'small')
    rho = 1e6;
elseif strcmp(name, 'jilin2')
    rho = 1e7;
end
loop = 1;

% while loop
    disp('A new loop of Monte Carlo...')
    NewRun = false;
    EM = true;
    delta_pct = 0.5;
    budget_pct = [];
    budget_pct = [0.5;0];
%     budget_pct = [budget_pct, ones(2,1)];
% %     budget_pct = [budget_pct, [0;1]];
%     budget_pct = [budget_pct, zeros(2, 1)];
%     if EM
% %         budget_pct = [budget_pct, 0.05*ones(2,1)];
% %         budget_pct = [budget_pct, 0.5*ones(2,1)];
% %         budget_pct = [budget_pct, 0.25*ones(2,1)];
% %         budget_pct = [budget_pct, 0.01*ones(2,1)];
% %         budget_pct = [budget_pct, kron(delta_pct:delta_pct:1-delta_pct, ones(2, 1))];
% %         budget_pct = [budget_pct, kron([0.05, 0.3, 0.4, 0.8], ones(2, 1))];
%         budget_pct = [budget_pct, [delta_pct:delta_pct:1; zeros(1,numel(delta_pct:delta_pct:1))]];
%         budget_pct = [budget_pct, [zeros(1,numel(delta_pct:delta_pct:1)); delta_pct:delta_pct:1]];
%     end
        
    nBudget = size(budget_pct, 2);    
    nSample = 1;

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
    feasible_rate = 2*ones(nBudget, 1);
    heat_loss_supply_basecase = cell(nBudget, 1);
    heat_loss_return_basecase = cell(nBudget, 1);
    heat_loss_total = zeros(nBudget, 24);

    for idx_budget = 1:nBudget
        disp(['budget#',num2str(idx_budget)]);
        budget_pct_wind = budget_pct(1, idx_budget);
        budget_pct_load = budget_pct(2, idx_budget);
        if EM
            load([name,'_wg',num2str(budget_pct_wind),'_hl',num2str(budget_pct_load),'_EM.mat']);
        else 
            load([name,'_wg',num2str(budget_pct_wind),'_hl',num2str(budget_pct_load),'.mat']);
        end
        
        heat_loss_supply_basecase{idx_budget} = zeros(nPrd*nPipe, 1);
        heat_loss_return_basecase{idx_budget} = zeros(nPrd*nPipe, 1);
        
        
        
        if idx_budget == 1
            mat_A0=mat_A; mat_B0=mat_B; mat_C0=mat_C;
            mat_D0=mat_D; vec_b0=vec_b; vec_e0=vec_e;
        end
        nU = size(vec_u0,1);

        if NewRun && (idx_budget <= 1)%budget_pct_wind*budget_pct_load >= 1
            du = 0; %(vec_du_pos+vec_du_neg)/2; %%%%注意对于budget含0的情况，du人为改为0了，因此要拿不含0的情况来生成样本
            rng('shuffle'); %reset seed
            verification_seed = rng;
           %% normal distribution
            uSample = zeros(nU, nSample);            
            for i = 1:nSample
                
                uSample(:, i) = normrnd(vec_u0, du/3);  %du/3 for small system; du/5
%                 if i == 1
%                     uSample(:, i) = vec_u0+vec_du_pos;
%                 end
            end
%            %% uniformal distribution
%             uSample = kron(vec_u0-vec_du_neg,ones(1,nSample))+rand(nU,nSample).*kron(vec_du_pos+vec_du_neg,ones(1,nSample));            
            save([name,'_samples.mat'], 'uSample', 'verification_seed');
        else
            load([name,'_samples.mat'], 'uSample', 'verification_seed');
        end

        nSample = size(uSample, 2);
        nXvar = numel(index_var_first);
        nYvar = numel(index_var_second);

        calmn;
        
        shown = 0; pop = 0;
        for i = 1:nSample
            u_star_test = uSample(:, i);
            dT_test = u_star_test(index_var_heat_load(:));
            [ obj_first_stage_all(idx_budget, i), obj_second_stage_all(idx_budget, i), y_optimal_temp, x_feasible_all(idx_budget, i), u_feasible_all(idx_budget, i) ] ...
                = CCG_validate( mat_A0, mat_B0, mat_C0, mat_D0, mat_F, mat_G, vec_b0, vec_c, vec_d, vec_e0, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, x_optimal, u_star_test);
            
%             %% 以下是用全模型的
%             t_PS_in_val = y_optimal_temp( index_var_tbsin(:)-numel(index_var_first) );
%             heat_loss_supply_basecase{idx_budget} = dhs.water_c*kron( eye(24), diag(dhs.pipe(:,PIPE_FLOWRATE)) )*(eye(24*nPipe) - Jmat)*(Kmat*t_PS_in_val + tpsout_hat + tA);
%             heat_loss_supply_basecase{idx_budget} = reshape(heat_loss_supply_basecase{idx_budget}, nPipe, nPrd);
%             t_PR_in_val = y_optimal_temp( index_var_tbrin(:)-numel(index_var_first) );
%             heat_loss_return_basecase{idx_budget} = dhs.water_c*kron( eye(24), diag(dhs.pipe(:,PIPE_FLOWRATE)) )*(eye(24*nPipe) - Jmat)*(Kmat*t_PR_in_val + tprout_hat + tA);
%             heat_loss_return_basecase{idx_budget} = reshape(heat_loss_return_basecase{idx_budget}, nPipe, nPrd);
%             heat_loss_total(idx_budget, :) = sum(heat_loss_supply_basecase{idx_budget}+heat_loss_return_basecase{idx_budget}, 1);
            
            %% validate 是否需要为不考虑风电的写一个版本？
                                
            if sum(isnan(y_optimal_temp)) > 0
                y_feasible_all(idx_budget, i) = 0;
                
                [ obj_first_stage_all(idx_budget, i), obj_second_stage_all(idx_budget, i), y_optimal_temp, ~, ~ ] ...
                    = CCG_validate_relaxed( mat_A0, mat_B0, mat_C0, mat_D0, mat_F, mat_G, vec_b0, vec_c, vec_d, vec_e0, vec_f, vec_g, vec_h, vec_u0, vec_du_pos, vec_du_neg, x_optimal, u_star_test, rho);
%                 [ x_temp, obj_temp, time_temp, iter_temp ] = CCG_validate_new( mat_A, mat_B, mat_C, mat_D, mat_F, mat_G, vec_b, vec_c, vec_d, vec_e, vec_f, vec_g, vec_h, u_star_test, 0*vec_du_pos, 0*vec_du_neg, vtype_x0, CCG_reltol, CCG_itermax, ADseed, z_pos_guess, z_neg_guess, x_optimal);
% 
%                 tgs_temp = y_optimal_temp(index_var_tgs(:)-nXvar);
%                 tns_temp = Y_NS_GS*tgs_temp + t_NS_GS;
%                 tnr_temp = Y_NR_GS*tgs_temp + Y_NR_d*dT_test + t_NR_GS;
            else
                y_feasible_all(idx_budget, i) = 1;
            end
            pop = floor(i/nSample*10);
            if pop>shown
                shown = pop;
                display(sprintf('[%.1f%%] of the %d Monte Carlo simulation samples tested.', i/nSample*100, nSample));
            end
        end

        if sum(y_feasible_all(idx_budget, :)) >= 1
%             obj_first_stage_avg(idx_budget) = mean(obj_first_stage_all(idx_budget, y_feasible_all(idx_budget, :)>0));
            obj_first_stage_avg(idx_budget) = mean(obj_first_stage_all(idx_budget, :));
            obj_second_stage_avg(idx_budget) = mean(obj_second_stage_all(idx_budget, :));
            obj_avg(idx_budget) = obj_first_stage_avg(idx_budget)+obj_second_stage_avg(idx_budget);
            obj_all(idx_budget, :) = obj_first_stage_all(idx_budget, :)+obj_second_stage_all(idx_budget, :);
            obj_wrst(idx_budget) = max(obj_all(idx_budget, :));
            feasible_rate(idx_budget) = round(sum(y_feasible_all(idx_budget, :)))/nSample
        else
            feasible_rate(idx_budget) = 0
        end
        time_CCG_all(idx_budget) = time_CCG;
        iter_all(idx_budget) = iter_CCG;
%         if EM
%             save([name, '_wg',num2str(budget_pct_wind),'_hl',num2str(budget_pct_load), '_EM_verify.mat']);
%         else
%             save([name, '_wg',num2str(budget_pct_wind),'_hl',num2str(budget_pct_load), '_verify.mat']);
%         end

%         if feasible_rate(1) < 1
%             break
%         end
%         if idx_budget >= 2 && min(feasible_rate) < feasible_rate(2)
%             break
%         end
        
%         if idx_budget == 2
%             if feasible_rate(2) >= feasible_rate(1)
%                 break
%             else
%                 loop = 0;
%             end
%         end  
        if idx_budget == nBudget
            loop = 0;
        end  
    end
    feasible_rate    
% end
if EM
%     save([name, '_EM_verify_sum.mat'],'budget_pct','obj_first_stage_avg','obj_second_stage_avg',...
%         'obj_avg','obj_all', 'obj_wrst','feasible_rate','time_CCG_all','iter_all');
    save([name, '_EM_verify_sum.mat']);
else
    save([name, '_verify_sum.mat']);
end
yval = y_optimal_temp;
% solution = zeros(nHvar, 1);
% solution(index_var_first) = x_optimal;
% solution(index_var_second) = yval;
% [solution(index_var_pg(index_wind2gen,:)), u_star_test(index_var_wind_max)]
% [y Fs] = audioread('victory.mp3');
load('chirp');
sound(y,Fs);
% clear sound