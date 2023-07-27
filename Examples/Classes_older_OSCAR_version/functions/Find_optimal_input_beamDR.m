% Already defined the ifo

% Assume the perfect mode matching for the arm
[beam_parameter] = Check_Stability(West_arm);
West_arm.Laser_in = E_Field(G1,'w',beam_parameter(1),'R',beam_parameter(2));
West_arm = Cavity_Resonance_Phase(West_arm);

West_arm = Calculate_Fields_AC(West_arm);
%West_arm.Display_Results
Field_on_PR = Propagate_E(West_arm.Field_ref,0.5*(d_BS_W_IM+d_BS_N_IM));

Field_reflec = Transmit_Reflect_Optic(Field_on_PR,PRM);
Field_reflec =  Change_E_n(Field_reflec,PRM.n1);

Fit_TEM00(Field_reflec)

%% Test
disp(' ')
[beam_parameter] = Check_Stability(West_arm);
West_arm.Laser_in = E_Field(G1,'w',beam_parameter(1),'R',beam_parameter(2));
West_arm.Laser_in = Add_Sidebands(West_arm.Laser_in,'Mod_freq',SB_6M_freq,'Mod_depth',0.11);

[a,b] = Calculate_Power(West_arm.Laser_in,'include','SB')

West_arm = Cavity_Resonance_Phase(West_arm);
West_arm = Calculate_Fields_AC(West_arm);

[a2, b2] = Calculate_Power(West_arm.Field_ref,'include','SB')

%% Test2

Field_in = E_Field(G1,'w',beam_parameter(1),'R',beam_parameter(2));
Field_in = Add_Sidebands(Field_in,'Mod_freq',SB_6M_freq,'Mod_depth',0.11);

 Calculate_Power(Field_in,'include','SB')
[Field_in,Field_reflec] =  Transmit_Reflect_Mirror(Field_in,N_IM,'AR');
 Calculate_Power(Field_in,'include','SB')
 Calculate_Power(Field_reflec,'include','SB')
 
 %% Test3
 