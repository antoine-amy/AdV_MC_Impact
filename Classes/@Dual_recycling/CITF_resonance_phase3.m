function DRout = CITF_resonance_phase3(DRin)
% Pout = CITF_resonance_phase(DRin) find the resonances of a PRC cavity
% This procedure find the resonance condition in the North and East arms of
% the cavity by adjusting the phase difference after several round trips of
% light. Work well if the input beam is mode matched to the recycling
% cavity.
% Calculate the resonance condition FOR THE CARRIER to maximise the
% recycling gain

if  ~isa(DRin, 'Dual_recycling')
    error('CITF_resonance_phase(): the first argument (DRin) must be an instance of the class Dual_recycling')
end

DRout = DRin;
DRin =  Remove_SBs(DRin);

Arm_convergence_scheme = 'accelerated';

E_in = DRin.Laser_in;

% Simplify the variable for easy understanding
NA = DRin.North_arm;
EA = DRin.East_arm;

% first, transmit the laser beam through PRM

Field_in = Change_E_n(E_in,DRin.I_PRM.n2);
Field_in = Transmit_Reflect_Interface(Field_in,DRin.I_PRM);

%% Set the dark fringe
% DRout.reso_North = 0.9776 + 0.2104*1i;
% DRout.reso_East = 0.9692 - 0.2464*1i;

% DRout.reso_North = DRout.reso_North .* exp(-1i*0.7);
% DRout.reso_East = DRout.reso_East .* exp(1i*0.7);

DRout.reso_North = 1;
DRout.reso_East = 1;

Field_Circ = Propagate_E(Field_in,DRin.Propagation_mat_PRM_BS);
[Field_CircE, Field_CircN] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref_out);
Field_CircE = Change_E_n(Field_CircE,DRin.I_BS_Ref_out.n1);

Field_CircN = Propagate_E(Field_CircN,DRin.Propagation_mat_BS_NIM);
Field_CircE = Propagate_E(Field_CircE,DRin.Propagation_mat_BS_EIM);

% Field_CircN = Field_CircN * DRout.reso_North;
% Field_CircE = Field_CircE * DRout.reso_East;

% Arm reflection
NA.Laser_in = Field_CircN;
NA = Reflection_arm(NA,'method',Arm_convergence_scheme,'accuracy',1E-03);
Field_CircN = NA.Field_ref;

EA.Laser_in = Field_CircE;
EA = Reflection_arm(EA,'method',Arm_convergence_scheme,'accuracy',1E-03);
Field_CircE = EA.Field_ref;

Field_CircN = Propagate_E(Field_CircN,DRin.Propagation_mat_BS_NIM);
Field_CircE = Propagate_E(Field_CircE,DRin.Propagation_mat_BS_EIM);

[~, Field_CircN] = Transmit_Reflect_Interface(Field_CircN,DRin.I_BS_Ref_out);
[Field_CircE, ~] = Transmit_Reflect_Interface(Field_CircE,DRin.I_BS_Ref_out);
Field_CircE = Change_E_n(Field_CircE,DRin.I_BS_Ref_out.n1);

detuning = angle(Calculate_Overlap(Field_CircN,Field_CircE)); % must be 0 at the end to add up coherently

DRout.reso_North = DRout.reso_North * exp(-1i*detuning/4);
DRout.reso_East = DRout.reso_East * exp(1i*detuning/4);
%
Field_CircW = Field_CircN * (DRout.reso_North)^2 + Field_CircE * (DRout.reso_East)^2;
%Calculate_Power(Field_CircW)

%% Now go to the bright fringe:
% the round trip field must add coherently to the incoming field Field_in

Field_CircW = Propagate_E(Field_CircW,DRin.Propagation_mat_PRM_BS);
Field_CircW = Reflect_Mirror(Field_CircW,DRin.I_PRM);

detuning = angle(Calculate_Overlap(Field_CircW,Field_in)); 

DRout.reso_North = DRout.reso_North * exp(-1i*detuning/2);
DRout.reso_East = DRout.reso_East * exp(-1i*detuning/2);

%Calculate_Power(Field_CircW*exp(-1i*detuning) + Field_in)


% phase_vec = linspace(0,2*pi,101);
% for ii = 1:length(phase_vec)
%     pres(ii) = Calculate_Power(Field_in + Field_CircW*exp(1i*phase_vec(ii)));
% end
% plot(phase_vec,pres)


%% Second pass to check that it is ok
%
Field_Circ = Propagate_E(Field_in,DRin.Propagation_mat_PRM_BS);
[Field_CircE, Field_CircN] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref_out);
Field_CircE = Change_E_n(Field_CircE,DRin.I_BS_Ref_out.n1);

Field_CircN = Propagate_E(Field_CircN,DRin.Propagation_mat_BS_NIM);
Field_CircE = Propagate_E(Field_CircE,DRin.Propagation_mat_BS_EIM);

Field_CircN = Field_CircN * DRout.reso_North;
Field_CircE = Field_CircE * DRout.reso_East;

% Arm reflection
NA.Laser_in = Field_CircN;
NA = Reflection_arm(NA,'method',Arm_convergence_scheme,'accuracy',1E-03);
Field_CircN = NA.Field_ref;

EA.Laser_in = Field_CircE;
EA = Reflection_arm(EA,'method',Arm_convergence_scheme,'accuracy',1E-03);
Field_CircE = EA.Field_ref;

Field_CircN = Field_CircN * DRout.reso_North;
Field_CircE = Field_CircE * DRout.reso_East;

Field_CircN = Propagate_E(Field_CircN,DRin.Propagation_mat_BS_NIM);
Field_CircE = Propagate_E(Field_CircE,DRin.Propagation_mat_BS_EIM);

[~, Field_CircN] = Transmit_Reflect_Interface(Field_CircN,DRin.I_BS_Ref_out);
[Field_CircE, ~] = Transmit_Reflect_Interface(Field_CircE,DRin.I_BS_Ref_out);
Field_CircE = Change_E_n(Field_CircE,DRin.I_BS_Ref_out.n1);

detuning = angle(Calculate_Overlap(Field_CircN,Field_CircE)); % must be 0 at the end to add up coherently

DRout.reso_North = DRout.reso_North .* exp(-1i*detuning/4);
DRout.reso_East = DRout.reso_East .* exp(1i*detuning/4);

Field_CircW = Field_CircN + Field_CircE;
%Calculate_Power(Field_CircW)

Field_CircW = Propagate_E(Field_CircW,DRin.Propagation_mat_PRM_BS);
Field_CircW = Reflect_Mirror(Field_CircW,DRin.I_PRM);

detuning = angle(Calculate_Overlap(Field_CircW,Field_in)); 

DRout.reso_North = DRout.reso_North * exp(-1i*detuning/2);
DRout.reso_East = DRout.reso_East * exp(-1i*detuning/2);

%Calculate_Power(Field_CircW + Field_in)


% Calculate_Power(Field_CircN + Field_CircE)

% phase_vec = linspace(0,2*pi,101);
% 
% for ii = 1:length(phase_vec)
%     pres(ii) = Calculate_Power(Field_CircN + Field_CircE*exp(1i*phase_vec(ii)));
% end
% 
% plot(phase_vec,pres)


disp('Found the phase for the resonant phase for the PRC')

end