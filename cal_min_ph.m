% Calculate P_min and H_min according to the given extreme points of CHPs
for i=1:nChp
    temp_min= Inf;
    temp_max = -Inf;
    index_min = 0;
    index_max = 0;
    for k=1:dhs.chppt(i,CHPPT_NPT) %CHPi的极点个数
        if (dhs.chppt(i,CHPPT_NPT+2*k-1)<temp_min)%依次判断p1,p2,p3,p4，选择最小的
            index_min = k;
            temp_min = dhs.chppt(i,CHPPT_NPT+2*k-1);
        end
        
        if (dhs.chppt(i,CHPPT_NPT+2*k-1)>temp_max)%选择最大的
            index_max = k;
            temp_max = dhs.chppt(i,CHPPT_NPT+2*k-1);
        end
    end
    dhs.chp(i,CHP_PMIN) = temp_min;
    dhs.chp(i,CHP_PMAX) = temp_max;
    dhs.chp(i,CHP_HMIN) = dhs.chppt(i,CHPPT_NPT+2*index_min);%由CHPi中p最小的那个极点，同样也是h最小的
    mpc.gen(index_chp2gen(i),PMIN) = temp_min;
    mpc.gen(index_chp2gen(i),PMAX) = temp_max;
end