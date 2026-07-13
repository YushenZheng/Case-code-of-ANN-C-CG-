clear;
tic;
fid = fopen('time_compare_test.csv', 'a');
eid1 = fopen('test_variable_obj.csv', 'a');
eid2 = fopen('test_variable_x.csv', 'a');
eid3 = fopen('test_variable_z.csv', 'a');
global eid4;
eid4 = fopen('every_iter.txt','a'); 
% fid = fopen('time_compare.csv', 'a');

global iii; 
global jj;
global num_u;

num_sa=5;
num_u=1296;  

% fprintf(fid,'iter_CCG,');   
% fprintf(fid,'iter_CCG_ANN_sp,');
% fprintf(fid,'iter_CCG_ANN,');
% fprintf(fid,'iter_CCG_try,');  
% fprintf(fid,'iter_CCG_ANN_addmain,');
% 
% fprintf(fid,'time_CCG,');
% fprintf(fid,'time_CCG_ANN_sp,');
% fprintf(fid,'time_CCG_ANN,');
% fprintf(fid,'time_CCG_try,');
% fprintf(fid,'time_CCG_ANN_addmain,');
% 
% fprintf(eid1,'obj_optimal,');
% fprintf(eid1,'obj_optimal_ANN_sp,');
% fprintf(eid1,'obj_optimal_ANN,');
% fprintf(eid1,'obj_optimal_try,');
% fprintf(eid1,'obj_optimal_ANN_addmain,');
% 
% fprintf(eid1,'dis_obj_ANN_sp,');
% fprintf(eid1,'dis_obj_ANN,');
% fprintf(eid1,'dis_obj_optimal_try,');
% fprintf(eid1,'dis_optimal_ANN_addmain,');
% 
% fprintf(eid1,'if_exit_ubsp,');
% fprintf(eid1,'if_exit_ubsp_ANN_sp,');
% fprintf(eid1,'if_exit_ubsp_ANN,');
% fprintf(eid1,'if_exit_ubsp_try,');
% fprintf(eid1,'if_exit_ubsp_ANN_addmain,');
% 
% for ttt=1:num_u*2
%     fprintf(eid3,'z_star%d,',ttt);
% end

%%预测主问题的u初始值
% for jj = 1:2
%     z_star_idex = strcat('model_u96_',num2str(jj),'.h5');
%     model_z_star(jj) = importKerasNetwork(z_star_idex);
% end
jj=1;
z_star_idex = strcat('model_u96_1.h5');
model_z_star(jj) = importKerasNetwork(z_star_idex);

%%预测每次子问题的u初始值
% for jj = 1:2
%     z_star_idex = strcat('smodel_u96_',num2str(jj),'.h5');
%     smodel_z_star(jj) = importKerasNetwork(z_star_idex);
% end
z_star_idex = strcat('smodel_u96_1.h5');
smodel_z_star(jj) = importKerasNetwork(z_star_idex);

for iii=1:num_sa
    fprintf(eid4,'第%d次重复实验\n',iii);
    CHPS_Equivalent;
    
    fprintf(eid4,'\n');

    fprintf(fid,'\n');
    fprintf(fid,'%d,',iter_CCG);
    fprintf(fid,'%d,',iter_CCG_ANN_sp);
    fprintf(fid,'%d,',iter_CCG_ANN);
    fprintf(fid,'%d,',iter_CCG_try);
    fprintf(fid,'%d,',iter_CCG_ANN_addmain);
    
    fprintf(fid,'%f3,',time_CCG);
    fprintf(fid,'%f3,',time_CCG_ANN_sp);
    fprintf(fid,'%f3,',time_CCG_ANN);
    fprintf(fid,'%f3,',time_CCG_try);
    fprintf(fid,'%f3,',time_CCG_ANN_addmain);
    
    fprintf(eid1,'\n');
    fprintf(eid1,'%f3,',obj_optimal);
    fprintf(eid1,'%f3,',obj_optimal_ANN_sp); 
    fprintf(eid1,'%f3,',obj_optimal_ANN);
    fprintf(eid1,'%f3,',obj_optimal_try);
    fprintf(eid1,'%f3,',obj_optimal_ANN_addmain);
    dis_obj_ANN_sp = (obj_optimal_ANN_sp-obj_optimal)/obj_optimal;
    dis_obj_ANN = (obj_optimal_ANN-obj_optimal)/obj_optimal;
    dis_obj_optimal_try = (obj_optimal_try-obj_optimal)/obj_optimal;
    dis_obj_ANN_addmain = (obj_optimal_ANN_addmain-obj_optimal)/obj_optimal;
    fprintf(eid1,'%f3%%,',dis_obj_ANN_sp*100);
    fprintf(eid1,'%f3%%,',dis_obj_ANN*100);
    fprintf(eid1,'%f3%%,',dis_obj_optimal_try*100);
    fprintf(eid1,'%f3%%,',dis_obj_ANN_addmain*100);
    
    fprintf(eid1,'%d,',if_exit_ubsp);
    fprintf(eid1,'%d,',if_exit_ubsp_ANN_sp);
    fprintf(eid1,'%d,',if_exit_ubsp_ANN);
    fprintf(eid1,'%d,',if_exit_ubsp_try);
    fprintf(eid1,'%d,',if_exit_ubsp_ANN_addmain);
    
    fprintf(eid2,'\n');
    fprintf(eid2,'%f3,',x_optimal);
    fprintf(eid2,'\n');
    fprintf(eid2,'%f3,',x_optimal_ANN_sp);
    dis_x_ANN_sp=0;
    for ttt=1:length(x_optimal)
        if(abs(x_optimal(ttt)-x_optimal_ANN_sp(ttt))>0.5)
            dis_x_ANN_sp=dis_x_ANN_sp+1;
        end
    end
    acc_x_ANN_sp=(length(x_optimal)-dis_x_ANN_sp)/(length(x_optimal));
    fprintf(eid2,'%f3%%,',acc_x_ANN_sp*100);
    
    fprintf(eid2,'\n');
    fprintf(eid2,'%d,',x_optimal_ANN);
    dis_x_ANN=0;
    for ttt=1:length(x_optimal)
        if(abs(x_optimal(ttt)-x_optimal_ANN(ttt))>0.5)
            dis_x_ANN=dis_x_ANN+1;
        end
    end
    acc_x_ANN=(length(x_optimal)-dis_x_ANN)/(length(x_optimal));
    fprintf(eid2,'%f3%%,',acc_x_ANN*100);

    fprintf(eid2,'\n');
    fprintf(eid2,'%f3,',x_optimal_try);
    dis_x_try=0;
    for ttt=1:length(x_optimal)
        if(abs(x_optimal(ttt)-x_optimal_try(ttt))>0.5)
            dis_x_try=dis_x_try+1;
        end
    end
    acc_x_try=(length(x_optimal)-dis_x_try)/(length(x_optimal));
    fprintf(eid2,'%f3%%,',acc_x_try*100);
    
    fprintf(eid2,'\n');
    fprintf(eid2,'%d,',x_optimal_ANN_addmain);
    dis_x_ANN_addmain=0;
    for ttt=1:length(x_optimal)
        if(abs(x_optimal(ttt)-x_optimal_ANN_addmain(ttt))>0.5)
            dis_x_ANN_addmain=dis_x_ANN_addmain+1;
        end
    end
    acc_x_ANN_addmain=(length(x_optimal)-dis_x_ANN_addmain)/(length(x_optimal));
    fprintf(eid2,'%f3%%,',acc_x_ANN_addmain*100);
    fprintf(eid2,'\n');

    fprintf(eid3,'\n');
    fprintf(eid3,'%d,',z_pos_star);
    fprintf(eid3,'%d,',z_neg_star);
    num_z_pos_1=0;
    num_z_neg_1=0;
    for ttt=1:length(z_pos_star)
        if(abs(z_pos_star(ttt)-1)<0.5)
            num_z_pos_1=num_z_pos_1+1;
        end
        if(abs(z_neg_star(ttt)-1)<0.5)
            num_z_neg_1=num_z_neg_1+1;
        end
    end
    fprintf(eid3,'%d,',num_z_pos_1);
    fprintf(eid3,'%d,',num_z_neg_1);

    fprintf(eid3,'\n');
    fprintf(eid3,'%d,',z_pos_star_ANN_sp);
    fprintf(eid3,'%d,',z_neg_star_ANN_sp);
    dis_z_ANN_sp=0;
    num_z_pos_ANN_sp_1=0;
    num_z_neg_ANN_sp_1=0;
    for ttt=1:length(z_pos_star)
        if(abs(z_pos_star(ttt)-z_pos_star_ANN_sp(ttt))>0.5)
            dis_z_ANN_sp=dis_z_ANN_sp+1;
        end
        if(abs(z_neg_star(ttt)-z_neg_star_ANN_sp(ttt))>0.5)
            dis_z_ANN_sp=dis_z_ANN_sp+1;
        end
        if(abs(z_pos_star_ANN_sp(ttt)-1)<0.5)
            num_z_pos_ANN_sp_1=num_z_pos_ANN_sp_1+1;
        end
        if(abs(z_neg_star_ANN_sp(ttt)-1)<0.5)
            num_z_neg_ANN_sp_1=num_z_neg_ANN_sp_1+1;
        end
    end
    acc_z_ANN_sp=(length(z_pos_star)+length(z_neg_star)-dis_z_ANN_sp)/(length(z_pos_star)+length(z_neg_star));
    fprintf(eid3,'%d,',num_z_pos_ANN_sp_1);
    fprintf(eid3,'%d,',num_z_neg_ANN_sp_1);
    fprintf(eid3,'%f3%%,',acc_z_ANN_sp*100);
    
    fprintf(eid3,'\n');
    fprintf(eid3,'%d,',z_pos_star_ANN);
    fprintf(eid3,'%d,',z_neg_star_ANN);
    dis_z_ANN=0;
    num_z_pos_ANN_1=0;
    num_z_neg_ANN_1=0;
    for ttt=1:length(z_pos_star)
        if(abs(z_pos_star(ttt)-z_pos_star_ANN(ttt))>0.5)
            dis_z_ANN=dis_z_ANN+1;
        end
        if(abs(z_neg_star(ttt)-z_neg_star_ANN(ttt))>0.5)
            dis_z_ANN=dis_z_ANN+1;
        end
        if(abs(z_pos_star_ANN(ttt)-1)<0.5)
            num_z_pos_ANN_1=num_z_pos_ANN_1+1;
        end
        if(abs(z_neg_star_ANN(ttt)-1)<0.5)
            num_z_neg_ANN_1=num_z_neg_ANN_1+1;
        end
    end
    acc_z_ANN=(length(z_pos_star)+length(z_neg_star)-dis_z_ANN)/(length(z_pos_star)+length(z_neg_star));
    fprintf(eid3,'%d,',num_z_pos_ANN_1);
    fprintf(eid3,'%d,',num_z_neg_ANN_1);
    fprintf(eid3,'%f3%%,',acc_z_ANN*100);
   
    fprintf(eid3,'\n');
    fprintf(eid3,'%d,',z_pos_star_try);
    fprintf(eid3,'%d,',z_neg_star_try);
    dis_z_try=0;
    num_z_pos_try_1=0;
    num_z_neg_try_1=0;
    for ttt=1:length(z_pos_star)
        if(abs(z_pos_star(ttt)-z_pos_star_try(ttt))>0.5)
            dis_z_try=dis_z_try+1;
        end
        if(abs(z_neg_star(ttt)-z_neg_star_try(ttt))>0.5)
            dis_z_try=dis_z_try+1;
        end
        if(abs(z_pos_star_try(ttt)-1)<0.5)
            num_z_pos_try_1=num_z_pos_try_1+1;
        end
        if(abs(z_neg_star_try(ttt)-1)<0.5)
            num_z_neg_try_1=num_z_neg_try_1+1;
        end
    end
    acc_z_try=(length(z_pos_star)+length(z_neg_star)-dis_z_try)/(length(z_pos_star)+length(z_neg_star));
    fprintf(eid3,'%d,',num_z_pos_try_1);
    fprintf(eid3,'%d,',num_z_neg_try_1);
    fprintf(eid3,'%f3%%,',acc_z_try*100);
    
    fprintf(eid3,'\n');
    fprintf(eid3,'%d,',z_pos_star_ANN_addmain);
    fprintf(eid3,'%d,',z_neg_star_ANN_addmain);
    dis_z_ANN_addmain=0;
    num_z_pos_ANN_addmain_1=0;
    num_z_neg_ANN_addmain_1=0;
    for ttt=1:length(z_pos_star)
        if(abs(z_pos_star(ttt)-z_pos_star_ANN_addmain(ttt))>0.5)
            dis_z_ANN_addmain=dis_z_ANN_addmain+1;
        end
        if(abs(z_neg_star(ttt)-z_neg_star_ANN_addmain(ttt))>0.5)
            dis_z_ANN_addmain=dis_z_ANN_addmain+1;
        end
        if(abs(z_pos_star_ANN_addmain(ttt)-1)<0.5)
            num_z_pos_ANN_addmain_1=num_z_pos_ANN_addmain_1+1;
        end
        if(abs(z_neg_star_ANN(ttt)-1)<0.5)
            num_z_neg_ANN_addmain_1=num_z_neg_ANN_addmain_1+1;
        end
    end
    acc_z_ANN_addmain=(length(z_pos_star)+length(z_neg_star)-dis_z_ANN_addmain)/(length(z_pos_star)+length(z_neg_star));
    fprintf(eid3,'%d,',num_z_pos_ANN_addmain_1);
    fprintf(eid3,'%d,',num_z_neg_ANN_addmain_1);
    fprintf(eid3,'%f3%%,',acc_z_ANN_addmain*100);
    fprintf(eid3,'\n');
    
end


                    