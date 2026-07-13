tgs = x(index_var_tgs(:));
tdr = x(index_var_tdr(:));
qchpplant = x(index_var_qchpplant(:));
tbsin = x(index_var_tbsin(:));
tbrin = x(index_var_tbrin(:));
tbsout = x(index_var_tbsout(:));
tbrout = x(index_var_tbrout(:));
tds = x(index_var_tds(:));
tgr = x(index_var_tgr(:));
tns = x(index_var_tns(:));
tnr = x(index_var_tnr(:));

delta = Y_g_GS*tgs+(-Y_g_d)*dT-g_hat-qchpplant

delta8s = max(abs(tbsin-(Y_PSin_GS*tgs+t_PSin_GS)))
delta8r = max(abs(tbrin-(Y_PRin_DR*tdr+t_PRin_DR)))
delta8s2 = max(abs(tbsout-(Y_PSout_GS*tgs+t_PSout_GS)))
delta8r2 = max(abs(tbrout-(Y_PRout_DR*tdr+t_PRout_DR)))
delta9s = max(abs( Y_DS_GS*tgs+t_DS_GS - tds ))
delta9r = max(abs( Y_GR_DR*tdr+t_GR_DR - tgr ))

delta10 = max(abs( Y_g_GS*tgs+Y_g_d*dT+g_hat-qchpplant ))

delta11 = max(abs( 1/dhs.water_c*inv(MGT)*qchpplant- (tgs+Y_GR_DR*(1/dhs.water_c*inv(MDT)*dT)-t_GR_DR-Y_GR_DR*(Y_DS_GS*tgs+t_DS_GS)) ))

delta12 = max(abs( (speye(nChpplant*nPrd)-Y_GR_DR*Y_DS_GS)*tgs ...
    + Y_GR_DR*1/dhs.water_c*inv(MDT)*dT - (t_GR_DR+Y_GR_DR*t_DS_GS) ...
    - 1/dhs.water_c*inv(MGT)*qchpplant ))

%% g, tgs, d
delta13 = max(abs( dhs.water_c*MGT*(speye(nChpplant*nPrd)-Y_GR_DR*Y_DS_GS)*tgs ...
    + MGT*Y_GR_DR*inv(MDT)*dT - dhs.water_c*MGT*(t_GR_DR+Y_GR_DR*t_DS_GS) ...
    - qchpplant ))

%% tns
delta_tns = max(abs( Y_NS_GS*tgs+t_NS_GS- tns ))
%% tnr
delta_tnr = max(abs( Y_NR_GS*tgs+Y_NR_d*dT+t_NR_GS- tnr ))