% Example of OSCAR script to define a 4 mirrors cavity
clear all; close all; clear classes
addpath(genpath('Classes'));
disp('---------------------------------------------------------------------------')
disp('                  OSCAR V3.2  - DR nominal    ')
disp('  ')

load('Results/AV_DR.mat');
SB_6M_freq = 6.270777E6;
SB_8M_freq = 8.361036E6;

% E_input = AV_DR.Field_circ;
% G1=AV_DR.Field_circ.Grid;
% G1.Step_sq=G1.Step^2;

G1 = Grid(128,3.5E-3); % Define the grid for the simulation: 128 X 128, 3.5 mm X 3.5 mm
E_input = E_Field(G1,'w0',133E-6,'Z',0); % Define the incoming beam before the input mirror surface (beam waist 0.450 mm, we start 35 mm before the waist)
E_input.Field= AV_DR.Field_circ.Field;
%fonctionne avec waist de 133E-6 (dans le vide, provient du changement des param de la cavité) pas 340

fprintf('New length of the grid: %g \n',G1.Length)
disp('After FFT code result:')
Fit_TEM00(E_input)

% E_input.Field=AV_DR.Field_circ.Field;
% E_input.SB=AV_DR.Field_circ.SB;
% E_input.Nb_Pair_SB=AV_DR.Field_circ.Nb_Pair_SB;
% E_input = Add_Sidebands(E_input,'Mod_freq',SB_6M_freq,'Mod_depth',0.11);

% Define the 4 mirrors ofE- the cavity
I(1) = Interface(G1,'CA',8E-3,'T',0.2847,'AoI',13);
I(2) = Interface(G1,'CA',8E-3,'T',0,'AoI',13);
I(3) = Interface(G1,'RoC',10.5E-2*1.45,'CA',8E-3,'T',0,'AoI',13);    % 'AoI'is for the angle of incidence in degree
I(4) = Interface(G1,'CA',8E-3,'T',0.2847,'AoI',13);

% Distance between the mirrors in m
d = [2.2475E-2*1.45 3.1276E-2*1.45 2.2475E-2*1.45 3.1276E-2*1.45];
% Define the cavity
OMC = CavityN(I,d,E_input);

OMC = Cavity_Scan(OMC,'use_parallel',false,'Define_L_length',true);
Display_Scan(OMC,'scan','RT phase');

% Calculate the resonance
OMC = Cavity_Resonance_Phase(OMC);

% Calculate the steady state fields
OMC = Calculate_Fields(OMC); % The more traditional method (slower but can be used with sidebands)
Display_Results(OMC)

