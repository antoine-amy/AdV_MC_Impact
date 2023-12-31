%% Example of OSCAR script to define a 4 mirrors cavity
clear all; close all; clear classes
addpath(genpath('Classes'));
load('AV_DR-1410m-100nrad.mat');
disp('---------------------------------------------------------------------------')
disp('                  OSCAR V3.2  - DR nominal    ')
disp('  ')

%% Define the input field with the correct waist (133um not 340um since the MC simulation works in vacuum)
G1 = Grid(128,800E-6);
E_POP = E_Field(G1,'w0',133E-6); %Classic gaussian field

% Getting the POP field infos
E_POP.Field=AV_DR.Field_POP.Field;
E_POP.Nb_Pair_SB=2;
E_POP.SB=AV_DR.Field_POP.SB;
E_diaphragm = Propagate_E(E_POP,1.9914e-3);
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
% d = [2.2475E-2 3.1276E-2 2.2475E-2 3.1276E-2];

OMC = CavityN(I,d,E_diaphragm);
OMC = Cavity_Scan(OMC,'use_parallel',false,'Define_L_length',true);
Display_Scan(OMC,'scan','RT phase');

% Calculations
OMC = Cavity_Resonance_Phase(OMC); % Calculate the resonance
OMC = Calculate_Fields(OMC); % Calculate the steady state fields
Display_Results(OMC)


Nb_point = 200;
Phase_scan = zeros(Nb_point,1);
Sig.p = zeros(Nb_point,1); Sig.q = zeros(Nb_point,1);
Power.car = zeros(Nb_point,1); Power.SBl = zeros(Nb_point,1); Power.SBu = zeros(Nb_point,1);

for ii=1:Nb_point
    Pct = round(ii*100/Nb_point);
    fprintf(1,'%3i %%',Pct);
    
    Phase_scan(ii) = ii*(2*pi)/Nb_point;
    OMC.Resonance_phase = exp(1i*Phase_scan(ii));
    
    OMC = Calculate_Fields(OMC);
    OMC.Field_reso_guess = OMC.Field_circ;
    [Sig.p(ii),Sig.q(ii)] = Demodulate_SB(OMC.Field_ref,'phase',pi/2);
    Power.car(ii) = Calculate_Power(OMC.Field_circ);
    [Power.SB1(ii),Power.SB2(ii)] = Calculate_Power(OMC.Field_circ,'SB');
    
    if ii ~= Nb_point
        fprintf(1,'\b\b\b\b\b \b \b \b');
    else
        fprintf(1,'done \n');
    end
end

% Plot results
figure(3)
hold all
plot(Phase_scan,Sig.p,'LineWidth',2)
plot(Phase_scan,Sig.q,'LineWidth',2)
grid on; box on;
hold off
legend('Signal in phase','Signal in quadrature')
title('Demodulated PDH signal in reflection')
xlabel('Cavity round trip phase shift')
ylabel('Signal [a.u.]')

figure(4)
semilogy(Phase_scan,Power.car,'LineWidth',2)
grid on; box on;
hold all
semilogy(Phase_scan,Power.SB1,'LineWidth',2)
semilogy(Phase_scan,Power.SB2,'LineWidth',2)
hold off
legend('Carrier','Lower sideband','Upper sideband')
title('Power of the fields circulating inside the cavity')
xlabel('Cavity round trip phase shift')
ylabel('Power [W]')
