%% Example of OSCAR script to define a 4 mirrors cavity
clear all; close all; clear classes
addpath(genpath('Classes'));
load('AV_DR-1410m-100nrad.mat');
disp('---------------------------------------------------------------------------')
disp('                  OSCAR V3.2  - DR nominal    ')
disp('  ')

%% Define the input field with the correct waist (133um not 340um since the MC simulation works in vacuum)
% G1 = Grid(128,800E-6);
G1 = Grid(256,800E-6);
E_POP = E_Field(G1,'w0',133E-6); %Classic gaussian field

I1 = Interface(AV_DR.Field_POP.Grid,'CA',0.8,'T',1,'RoC',32.558);
E_POP_plan = Transmit_Reflect_Interface(AV_DR.Field_POP,I1);

Fit_TEM00(E_POP_plan);
E_Plot(E_POP_plan)

% Propagate another time over 100m
E_POP_plan = Propagate_E(E_POP_plan,1);

% Getting the POP field infos
E_POP.Field=E_POP_plan.Field;
E_POP.Nb_Pair_SB=2;
E_POP.SB=E_POP_plan.SB;
E_diaphragm = Propagate_E(E_POP,1.9914e-3);
disp('E_POP characteristics:')
Fit_TEM00(AV_DR.Field_POP);
disp(' ')
disp('E_diaphragm characteristics:')
Fit_TEM00(E_diaphragm);
disp(' ')

%% Now defining the lenses used to reduce the waist of the beam (for some reason not working...)

% % First surface RofC = 2.188 m, 25 cm of aperture, transmission = 1
% MMT_L1a1 = Interface(G1,'RoC',-2.188,'CA',0.25,'T',1,'n1',1,'n2',1.5066);
% MMT_L1a2 = Interface(G1,'RoC',7.3345,'CA',0.25,'T',1,'n1',1.5066,'n2',1);
% MMT_L1b1 = Interface(G1,'RoC',2.979,'CA',0.25,'T',1,'n1',1,'n2',1.5066);
% MMT_L1b2 = Interface(G1,'RoC',4.500,'CA',0.25,'T',1,'n1',1.5066,'n2',1);
% MMT_L21 = Interface(G1,'RoC',999999999999,'CA',0.25,'T',1,'n1',1,'n2',1.44963);
% MMT_L22 = Interface(G1,'RoC',-72.7e-3,'CA',0.25,'T',1,'n1',1.44963,'n2',1);
% 
% % Now using the mirror class
% Thick_L1a = Mirror(MMT_L1a1,MMT_L1a2,30e-3);
% Thick_L1b = Mirror(MMT_L1b1,MMT_L1b2,19e-3);
% Thick_L2 = Mirror(MMT_L21,MMT_L22,6e-3);
% 
% E_L1a_in = Propagate_E(E_POP,2.587);
% E_L1a_out = Transmit_Reflect_Mirror(E_L1a_in,Thick_L1a,'HR');
% E_L1b_in = Propagate_E(E_L1a_out,4.319e-3);
% E_L1b_out = Transmit_Reflect_Mirror(E_L1b_in,Thick_L1b,'HR');
% E_L2_in = Propagate_E(E_L1b_out,3.94335);
% E_L2_out = Transmit_Reflect_Mirror(E_L2_in,Thick_L2,'HR');
% E_diaphragm = Propagate_E(E_L2_out,280e-3);
% 
% disp('E_diaphragm characteristics:')
% Fit_TEM00(E_diaphragm);
% disp(' ')

%% Define the 4 mirrors of the Mode Cleaner cavity
I(1) = Interface(G1,'CA',8E-3,'T',0.2847,'AoI',13);
I(2) = Interface(G1,'CA',8E-3,'T',0,'AoI',13);
I(3) = Interface(G1,'RoC',10.5E-2*1.45,'CA',8E-3,'T',0,'AoI',13); % 'AoI'is for the angle of incidence in degree
I(4) = Interface(G1,'CA',8E-3,'T',0.2847,'AoI',13);

% Define the cavity
d = [2.2475E-2*1.45 3.1276E-2*1.45 2.2475E-2*1.45 3.1276E-2*1.45]; % Distance between the mirrors in m

figure(1420);
Expand_HOM(E_diaphragm,10,'display','vector','for','carrier');

OMC = CavityN(I,d,E_diaphragm);
OMC = Cavity_Scan(OMC,'use_parallel',false,'Define_L_length',true);
Display_Scan(OMC,'scan','RT phase');

% Calculations
OMC = Cavity_Resonance_Phase(OMC); % Calculate the resonance
OMC = Calculate_Fields(OMC); % Calculate the steady state fields
Display_Results(OMC)

E_output=OMC.Field_trans(1,4); % Check if this is the indeed the last output field comming out of the cavity

%% Save in a file the HOM powers
[~, Power_per_mode_carrier] = Expand_HOM(E_output,10,'for','carrier');
[~, Power_per_mode_SB1_lower] = Expand_HOM(E_output,10,'for','SB_lower','SB_num',1);
[~, Power_per_mode_SB1_upper] = Expand_HOM(E_output,10,'for','SB_upper','SB_num',1);
Power_per_mode_SB1=Power_per_mode_SB1_lower+Power_per_mode_SB1_upper;
[~, Power_per_mode_SB2_lower] = Expand_HOM(E_output,10,'for','SB_lower','SB_num',2);
[~, Power_per_mode_SB2_upper] = Expand_HOM(E_output,10,'for','SB_upper','SB_num',2);
Power_per_mode_SB2=Power_per_mode_SB1_lower+Power_per_mode_SB1_upper;
data=[Power_per_mode_carrier; Power_per_mode_SB1; Power_per_mode_SB2];

figure(1450);
Expand_HOM(E_output,10,'display','vector','for','carrier');

% Save table of data
T=table(data);
writetable(T,'HOM_pow.txt');
