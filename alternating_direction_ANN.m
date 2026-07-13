function [u_temp, z_pos_temp, z_neg_temp, obj_temp, time_temp] = alternating_direction_ANN(normal_input_model, smodel_z_star, fixz,fixw, mat_B, mat_C, vec_u0, vec_du_pos, vec_du_neg, x_star, vec_e, vec_g, var_u, ADiter_max, ADtol_rel)
global num_u;

u_temp=NaN*vec_u0; z_pos_temp = u_temp; z_neg_temp = u_temp; obj_temp=-inf; time_temp=0;
z_star_ANN = zeros(1,num_u*2);
z_star_tran = zeros(1,num_u*2);

% for jj = 1:2
%     tic;
%     z_star_ANN(1,(jj-1)*num_u+1:jj*num_u) = smodel_z_star(jj).predict(normal_input_model);
%     time_ANN = toc;
%     time_temp = time_temp + time_ANN;
% end
tic;
z_star_ANN(1,1:2*num_u) = smodel_z_star(1).predict(normal_input_model);
time_ANN = toc;
time_temp = time_temp + time_ANN;

for ttt =1:num_u
    if(z_star_ANN(1,ttt) >= 0.3)
        z_star_tran(1,ttt)=1;
    else
        z_star_tran(1,ttt)=0;
    end
end

for ttt =num_u+1:num_u*2
    if(z_star_ANN(1,ttt) >= 0.65)
        z_star_tran(1,ttt)=1;
    else
        z_star_tran(1,ttt)=0;
    end
end
    zpos0 = z_star_tran (1,1:num_u);
    zneg0 = z_star_tran (1,num_u+1:num_u*2);
    u_star = vec_u0+diag(vec_du_pos)*zpos0'-diag(vec_du_neg)*zneg0';
        
    % ”√Gurobi«ÛΩ‚    
    clear params;
    params.outputflag = 0;
     for k = 1:ADiter_max
        %% z fixed problem
        fixz.obj = mat_C*u_star+mat_B*x_star-vec_e;
        fixz.objcon = vec_g'*u_star;
        result_fixz = gurobi(fixz,params);
        if ( strcmp(result_fixz.status,'OPTIMAL') )
            w_star = result_fixz.x;
            objval_fixz = result_fixz.objval;
            time_temp = time_temp+result_fixz.runtime;
%             time_temp_1 = time_temp_1+result_fixz.runtime;
        else
            return  %infeasible
        end
        %% w fixed problem
        fixw.obj(:) = 0;
        fixw.obj(var_u) = mat_C'*w_star+vec_g;
        fixw.objcon = w_star'*(mat_B*x_star-vec_e);
        result_fixw = gurobi(fixw,params);
        if ( strcmp(result_fixw.status,'OPTIMAL') )
            u_star = result_fixw.x(var_u);
            objval_fixw = result_fixw.objval;
            time_temp = time_temp+result_fixw.runtime;
        else
            return  %infeasible
        end
        %% convergence check
         if abs((objval_fixz-objval_fixw)*2/(objval_fixz+objval_fixw)) < ADtol_rel
            u_temp = u_star; obj_temp = objval_fixz;
%             z_pos_temp = max(u_temp-vec_u0, 0)./vec_du_pos;
%             z_neg_temp = max(-u_temp+vec_u0, 0)./vec_du_neg;
            z_pos_temp = zpos0;
            z_neg_temp = zneg0;
            return
         end
     end
 end