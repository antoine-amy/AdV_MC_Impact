%% Advanced LIGO dual recycling CITF
diary myDiaryFile
clear all; close all; clear classes
addpath(genpath('Classes'));
disp('---------------------------------------------------------------------------')
disp('                  OSCAR V3.2  - DR nominal    ')
disp('  ')
G1 = Grid(128,0.4);
data=[];
SB_6M_freq = 6.270777E6;
SB_8M_freq = 8.361036E6;
E_input = E_Field(G1,'w',0.0491,'R',-986);
E_input = Add_Sidebands(E_input,'Mod_freq',SB_6M_freq,'Mod_depth',0.11);
E_input = Add_Sidebands(E_input,'Mod_freq',SB_8M_freq,'Mod_depth',0.11);
E_input = Add_Sidebands(E_input,'Mod_freq',SB_6M_freq*9,'Mod_depth',0.11);
for i = 1:1:3
    freq=E_input.SB(i).Frequency_Offset/1E6;   
    X = ['SB_num=',num2str(i),' frequency=',num2str(freq), 'MHz'];
    disp(X);
end

%% Define the arm cavities first:
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

%% Now define the central area
% for v = 1425:1:1425 % Loop on the RoC of PRM
%     X = ['PRM_RoC=',num2str(v),'m'];
%     disp(X);

    % Define PRM and SRM as interfaces
    PRM = Interface(G1,'RoC',1430,'CA',0.33,'T',0.05,'L',0E-6); % Nominal 1430, L=0 chelou different dans O5
    PRM = Add_Tilt(PRM,100E-9); % Add a tilt in the vertical direction to the PRM
    SRM = Interface(G1,'RoC',1432,'CA',0.33,'T',0.4);

    % Define the length of the PRC
    d_PRM_BS = 6.0510;     % Distance PRC-POP + POP thickness * 1.45 + distance POP - BS
    d_BS_W_IM =  5.245 + 0.035*1.45 + 0.2 + 0.002;    % BS thickness + Distance BS - CP + CP thickness * 1.45 + distance CP _ IM
    d_BS_N_IM = 0.065*1.45 + 5.367 + 0.035*1.45 + 0.2 + 0.014;       % Distance BS - CP + CP thickness * 1.45 + distance CP _ IM
    d_BS_SRM = 6.0510; % BS thickness+distance BS-SRM

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
    % Fine the tuning of SR, add a dfo and then maximise the power at the dark port
    AV_DR = Refined_tuning(AV_DR,'zoom',0.04,'Nb_iter',4,'Find_max','quadratic_fit','Nb_scan',21);
    AV_DR = Calculate_fields(AV_DR,'iter',200);

    %% Save in a file the HOM powers
%     [~, Power_per_mode_carrier] = Expand_HOM(AV_DR.Field_POP,10,'for','carrier');
%     [~, Power_per_mode_SB1_lower] = Expand_HOM(AV_DR.Field_POP,10,'for','SB_lower','SB_num',1);
%     [~, Power_per_mode_SB1_upper] = Expand_HOM(AV_DR.Field_POP,10,'for','SB_upper','SB_num',1);
%     Power_per_mode_SB1=Power_per_mode_SB1_lower+Power_per_mode_SB1_upper;
%     [~, Power_per_mode_SB2_lower] = Expand_HOM(AV_DR.Field_POP,10,'for','SB_lower','SB_num',2);
%     [~, Power_per_mode_SB2_upper] = Expand_HOM(AV_DR.Field_POP,10,'for','SB_upper','SB_num',2);
%     Power_per_mode_SB2=Power_per_mode_SB1_lower+Power_per_mode_SB1_upper;
%     [~, Power_per_mode_SB3_lower] = Expand_HOM(AV_DR.Field_POP,10,'for','SB_lower','SB_num',3);
%     [~, Power_per_mode_SB3_upper] = Expand_HOM(AV_DR.Field_POP,10,'for','SB_upper','SB_num',3);
%     Power_per_mode_SB3=Power_per_mode_SB1_lower+Power_per_mode_SB1_upper;
%     HOM_pow=Power_per_mode_carrier+Power_per_mode_SB1+Power_per_mode_SB2+Power_per_mode_SB3;
%     HOM_pow_list=[v,HOM_pow];
%     data=[data;HOM_pow_list];
% end

disp("Power of Carrier HOM with 1410m PRM_RoC (W):");
Expand_HOM(AV_DR.Field_POP,10,'display','vector','for','carrier');

disp("");
disp("Power of SB1 HOM with 1410m PRM_RoC (W):");
disp("Lower:");
Expand_HOM(AV_DR.Field_POP,10,'display','vector','for','SB_lower','SB_num',1);
disp("Upper:");
Expand_HOM(AV_DR.Field_POP,10,'display','vector','for','SB_upper','SB_num',1);

disp("");
disp("Power of SB2 HOM with 1410m PRM_RoC (W):");
disp("Lower:");
Expand_HOM(AV_DR.Field_POP,10,'display','vector','for','SB_lower','SB_num',2);
disp("Upper");
Expand_HOM(AV_DR.Field_POP,10,'display','vector','for','SB_upper','SB_num',2);

disp("");
disp("Power of SB3 HOM with 1410m PRM_RoC (W):");
disp("Lower");
Expand_HOM(AV_DR.Field_POP,10,'display','vector','for','SB_lower','SB_num',3);
disp("Upper");
Expand_HOM(AV_DR.Field_POP,10,'display','vector','for','SB_upper','SB_num',3);

% Save table of data
% T=table(data);
% writetable(T,'HOM_pow.txt');
% type HOM_pow.txt;
diary off