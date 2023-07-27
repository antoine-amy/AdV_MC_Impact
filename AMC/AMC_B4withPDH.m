clear all; close all; clear classes
addpath(genpath('Classes'));
disp('---------------------------------------------------------------------------')
disp('                  OSCAR V3.2  - DR nominal    ')
disp('  ')

load('Results/AV_DR.mat');

SB_6M_freq = 6.270777E6;
SB_8M_freq = 8.361036E6;

G1 = Grid(128,0.004);
E_input = E_Field(G1,'w0',450E-6,'Z',-0.035);
E_input = Add_Sidebands(E_input,'Mod_freq',SB_6M_freq,'Mod_depth',0.11);
E_input = Add_Sidebands(E_input,'Mod_freq',SB_8M_freq,'Mod_depth',0.11);
E_input = Add_Sidebands(E_input,'Mod_freq',SB_6M_freq*9,'Mod_depth',0.11);

I(1) = Interface(G1,'CA',0.2,'T',0.02);
I(2) = Interface(G1,'CA',0.2,'T',0.02);
I(3) = Interface(G1,'RoC',2.34,'CA',0.02,'T',10E-6,'AoI',13);
I(4) = Interface(G1,'RoC',2.34,'CA',0.02,'T',10E-6,'AoI',13);

d = [0.07 0.147 0.294 0.147];

OMC = CavityN(I,d,E_input);

OMC = Cavity_Resonance_Phase(OMC);

OMC = Calculate_Fields(OMC);
Display_Results(OMC)

%%%% PDH Signal Calculation and Plot %%%%

Nb_point = 200;

Phase_scan = zeros(Nb_point,1);
Sig.p = zeros(Nb_point,1);
Sig.q = zeros(Nb_point,1);
Power.car = zeros(Nb_point,1);
Power.SBl = zeros(Nb_point,1);
Power.SBu = zeros(Nb_point,1);

for ii=1:Nb_point
    Phase_scan(ii) = ii*(2*pi)/Nb_point;
    OMC.Resonance_phase = exp(1i*Phase_scan(ii));

    OMC = Calculate_Fields(OMC);
    OMC.Field_reso_guess = OMC.Field_circ;
    [Sig.p(ii),Sig.q(ii)] = Demodulate_SB(OMC.Field_ref,'phase',pi/2);
    Power.car(ii) = Calculate_Power(OMC.Field_circ);
    [Power.SB1(ii),Power.SB2(ii)] = Calculate_Power(OMC.Field_circ,'SB');
end

% Plot all the results
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
