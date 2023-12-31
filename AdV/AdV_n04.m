% Advanced LIGO dual recycling CITF

clear all; close all; clear classes;
addpath(genpath('Classes'));

disp('---------------------------------------------------------------------------')
disp('                  OSCAR V3.2  - DR nominal    ')
disp('  ')

G1 = Grid(128,0.4); %128 de base, 10 pour etre plus rapide

SB_6M_freq = 6.270777E6;

E_input = E_Field(G1,'w',0.0491,'R',-986);

E_input = Add_Sidebands(E_input,'Mod_freq',SB_6M_freq,'Mod_depth',0.11);
E_input = Add_Sidebands(E_input,'Mod_freq',SB_6M_freq*9,'Mod_depth',0.11);

%--------------------------------------------
% Define the arm cavities first:
% Create the North arm cavity

% Create the thick IM substrate
N_IM_AR = Interface(G1,'RoC',-1420,'CA',0.33,'T',1);
N_IM_HR = Interface(G1,'RoC',1420,'CA',0.33,'T',0.014);
N_IM = Mirror(N_IM_HR,N_IM_AR,0.2); N_IM = Add_prop_mat(N_IM,E_input); % recommended to preallocate the propagation matrix

% Then add the end mirror
N_EM_HR = Interface(G1,'RoC',1683,'CA',0.33,'T',5E-6,'L',70E-6);

North_arm = Cavity1(N_IM,N_EM_HR,2999.8,E_input); % input field to be replaced later by a closer value
North_arm.Propagation_mat.Use_DI = true; % To use digital integration (or not)

% Create the West arm cavity

% Create the thick ITM substrate
W_IM_AR = Interface(G1,'RoC',-1420,'CA',0.33,'T',1);
W_IM_HR = Interface(G1,'RoC',1420,'CA',0.33,'T',0.014); % nominal 1420
W_IM = Mirror(W_IM_HR,W_IM_AR,0.2); W_IM = Add_prop_mat(W_IM,E_input);

% Then add the end mirror
W_EM_HR = Interface(G1,'RoC',1683,'CA',0.33,'T',5E-6,'L',70E-6);

West_arm = Cavity1(W_IM,W_EM_HR,2999.8,E_input); % input field to be replaced later by a closer value
West_arm.Propagation_mat.Use_DI = true;

%------------------------------------------------
% Now define the central area

% Define PRM and SRM as interfaces
PRM = Interface(G1,'RoC',1410,'CA',0.33,'T',0.05,'L',0E-6); % Nominal 1430
PRM = Add_Tilt(PRM,100E-9); % Add a tilt in the vertical direction to the PRM
SRM = Interface(G1,'RoC',1432,'CA',0.33,'T',0.4);

% Define the length of the PRC
d_PRM_BS = 6.0510;     % Distance PRC-POP + POP thickness * 1.45 + distance POP - BS
d_BS_W_IM =  5.245 + 0.035*1.45 + 0.2 + 0.002;    % BS thickness + Distance BS - CP + CP thickness * 1.45 + distance CP _ IM
d_BS_N_IM = 0.065*1.45 + 5.367 + 0.035*1.45 + 0.2 + 0.014;       % Distance BS - CP + CP thickness * 1.45 + distance CP _ IM
d_BS_SRM = 6.0510;            % BS thickness + distance BS - SRM


% Calculate the input beam for the arm cavities
E_input_arm = Change_E_n(E_input,PRM.n2); % Start from outside PRM
E_input_arm = Transmit_Reflect_Interface(E_input_arm,PRM); % pass through PRM
E_input_arm = Propagate_E(E_input_arm,d_PRM_BS + 0.5*(d_BS_W_IM+d_BS_N_IM)); % propagate to the input mirror

North_arm.Laser_in = E_input_arm;
West_arm.Laser_in = E_input_arm;

% Fine the resonances conditions for the arms
North_arm = Cavity_Resonance_Phase(North_arm);
West_arm = Cavity_Resonance_Phase(West_arm);

% Define the dual recycling
AV_DR = Dual_recycling(PRM,SRM,West_arm,North_arm,d_PRM_BS,d_BS_W_IM,d_BS_N_IM,d_BS_SRM,E_input);

% Fine the resonances condition for the PRC
AV_DR = CITF_resonance_phase3(AV_DR);
AV_DR.reso_South = 1.5708 + pi/2;

%AV_DR = find_tuning_SR(AV_DR);

% Fine the tuning of SR, add a dfo and then maximise the power at the dark
% port

% fprintf( '%1.10f%+1.10fj\n', real(AV_DR.reso_East), imag(AV_DR.reso_East))
% fprintf( '%1.10f%+1.10fj\n', real(AV_DR.reso_North), imag(AV_DR.reso_North))

%
%AV_DR = Refined_tuning(AV_DR,'zoom',3,'Nb_iter',4,'Find_max','max');
%0 0.4 0.04
% AV_DR = Refined_tuning(AV_DR,'zoom',0.4,'Nb_iter',4,'Find_max','max','Nb_scan',21);
AV_DR = Refined_tuning(AV_DR,'zoom',0.04,'Nb_iter',4,'Find_max','quadratic_fit','Nb_scan',21);
%
% fprintf( '%1.10f%+1.10fj\n', real(AV_DR.reso_East), imag(AV_DR.reso_East))
% fprintf( '%1.10f%+1.10fj\n', real(AV_DR.reso_North), imag(AV_DR.reso_North))

% DC readout detuning
% Phase_detuning = 2*pi*(4E-11)/1064E-9; % 1.25E-12 for 3mW DF @ 18W
% AV_DR.North_arm.Resonance_phase = AV_DR.North_arm.Resonance_phase .* exp(1i*Phase_detuning);
% AV_DR.East_arm.Resonance_phase = AV_DR.East_arm.Resonance_phase .* exp(-1i*Phase_detuning);
% %
%
%  Phase_detuning_MICH = 2*pi*(0.8E-9)/1064E-9; % 0.8E-9
%  AV_DR.reso_North = AV_DR.reso_North .* exp(1i*Phase_detuning_MICH);
%  AV_DR.reso_East = AV_DR.reso_East .* exp(-1i*Phase_detuning_MICH);
%
% AV_DR.reso_South = 1.1310;
% AV_DR = Calculate_fields(AV_DR,'accuracy',0.01);

% Bring the arm out of resonance
%     AV_DR.North_arm.Resonance_phase = AV_DR.North_arm.Resonance_phase .* exp(1i*0);
%     AV_DR.East_arm.Resonance_phase = AV_DR.East_arm.Resonance_phase .* exp(1i*0);

AV_DR = Calculate_fields(AV_DR,'iter',200);


% % 
Display_results(AV_DR)
%figure(101); plot(AV_DR.Power_buildup)
%E_plot_SB(AV_DR.Field_POP)

%Pin = Calculate_power_SB(E_input);
%Pref = Calculate_power_SB(AV_DR.Field_ref);
%Pout = Calculate_power_SB(AV_DR.Field_DP);

