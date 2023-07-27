function DRout = CITF_resonance_phase(DRin)
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

Field_Circ = Field_in;

num_iter = DRin.Cavity_phase_param;
Field_total = Normalise_E(Field_Circ,0);
Phase_adjust = 1;

% First for the North path

for q = 1:num_iter
    Field_total = Field_total + Field_Circ;
    %Calculate_Power(Field_total)
    %   figure(1)
    %   E_plot(Field_Circ); pause(0.1);title(num2str(q))
    
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
    [~,Field_Circ] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref_out);
    
    Field_Circ.Field = Field_Circ.Field /sqrt(0.5); % Correct BS transmission
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_BS_NIM);
    
    % Check what is reflected from the cavity
    NA.Laser_in = Field_Circ;
    NA = Reflection_arm(NA,'method',Arm_convergence_scheme,'accuracy',1E-03);
    Field_Circ = NA.Field_ref;
    
    %     figure(1)
    %     E_plot(Field_Circ); pause(0.1)
    
    % Back to the beam splitter toward PRM
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_BS_NIM)*Phase_adjust;
    [~,Field_Circ] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref_out);
    Field_Circ.Field = Field_Circ.Field /sqrt(0.5); % Correct BS transmission
    %
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
    Field_Circ = Reflect_Mirror(Field_Circ,DRin.I_PRM);
    
    Phase_adjust = Phase_adjust * exp(-1i*angle(Calculate_Overlap(Field_Circ,Field_total)));
    %   figure(1); E_plot(Field_total); pause(0.1)
    %sqrt(exp(-1i* angle(Calculate_Overlap(Field_Circ,Field_before))))
end


% Then find the round trip to make the eigen mode on resonnance for the
% North arm

Field_before = Field_total;
Field_Circ = Field_total;

Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
[~,Field_Circ] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref_out);
Field_Circ.Field = Field_Circ.Field /sqrt(0.5); % Correct BS transmission
Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_BS_NIM);

% Check what is reflected from the cavity
NA.Laser_in = Field_Circ;
NA = Reflection_arm(NA,'method',Arm_convergence_scheme,'accuracy',1E-03);
Field_Circ = NA.Field_ref;

% Back to the beam splitter toward PRM
Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_BS_NIM);
[~,Field_Circ] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref_out);
Field_Circ.Field = Field_Circ.Field /sqrt(0.5); % Correct BS transmission

Field_Circ = Reflect_Mirror(Field_Circ,DRin.I_PRM);

DRout.reso_North = exp(-1i* angle(Calculate_Overlap(Field_Circ,Field_before)));
DRout.reso_North = sqrt(DRout.reso_North);
%Calculate_Overlap(Field_Circ,Field_before)

%---------------------------------------------------------------------------------------------------------------------------------------------------
% Then for the East side

Field_Circ = Field_in;

Field_total = Normalise_E(Field_Circ,0);
Phase_adjust = -1;

for q = 1:num_iter
    
    Field_total = Field_total + Field_Circ;
    %Calculate_Power(Field_total)
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
    
    [Field_Circ,~] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref_in); 
    Field_Circ = Change_E_n(Field_Circ,DRin.I_BS_Ref_in.n1);
    Field_Circ.Field = Field_Circ.Field .* exp(1i*Field_in.k_prop*DRin.BS_OPD_trans);
    Field_Circ.Field = Field_Circ.Field / sqrt(0.5); % Correct for the beamsplitter transmission
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_BS_EIM); 
    
    % Check what is reflected from the cavity
    EA.Laser_in = Field_Circ;
    EA = Reflection_arm(EA,'method',Arm_convergence_scheme,'accuracy',1E-03);
    Field_Circ = EA.Field_ref;
    Field_Circ = (-1)*Field_Circ;   % (-1)  to be on the dark fringe
    
    % Back to the beam splitter toward PRM
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_BS_EIM)*Phase_adjust;
    Field_Circ.Field = Field_Circ.Field .* exp(1i*Field_in.k_prop*fliplr(DRin.BS_OPD_trans));
    [Field_Circ,~] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref_in); 
    Field_Circ = Change_E_n(Field_Circ,DRin.I_BS_Ref_in.n1);
    Field_Circ.Field = Field_Circ.Field /sqrt(0.5);
    
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
    Field_Circ = Reflect_Mirror(Field_Circ,DRin.I_PRM);
    
    Phase_adjust = Phase_adjust * exp(-1i*angle(Calculate_Overlap(Field_Circ,Field_total)));
    
end

% Then find the round trip to make the eigen mode on resonnance

Field_before = Field_total;
Field_Circ = Field_total;

Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);

[Field_Circ,~] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref_in);
Field_Circ = Change_E_n(Field_Circ,DRin.I_BS_Ref_in.n1);
Field_Circ.Field = Field_Circ.Field .* exp(1i*Field_in.k_prop*DRin.BS_OPD_trans);
Field_Circ.Field = Field_Circ.Field /sqrt(0.5);
Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_BS_EIM); %

% Check what is reflected from the cavity
EA.Laser_in = Field_Circ;
EA = Reflection_arm(EA,'method',Arm_convergence_scheme,'accuracy',1E-03);
Field_Circ = EA.Field_ref;
Field_Circ = (-1)*Field_Circ;   % (-1)  to be on the dark fringe


% Back to the beam splitter toward PRM
Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_BS_EIM)*Phase_adjust;
Field_Circ.Field = Field_Circ.Field .* exp(1i*Field_in.k_prop*fliplr(DRin.BS_OPD_trans));
[Field_Circ,~] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref_in);
Field_Circ = Change_E_n(Field_Circ,DRin.I_BS_Ref_in.n1);
Field_Circ.Field = Field_Circ.Field /sqrt(0.5);

Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
Field_Circ = Reflect_Mirror(Field_Circ,DRin.I_PRM);


DRout.reso_East = exp(-1i* angle(Calculate_Overlap(Field_Circ,Field_before)));
DRout.reso_East = sqrt(DRout.reso_East);


%% Set the dark fringe
% DRout.reso_North = 0.9776 + 0.2104*1i;
% DRout.reso_East = 0.9692 - 0.2464*1i;

% DRout.reso_North = DRout.reso_North .* exp(-1i*0.7);
% DRout.reso_East = DRout.reso_East .* exp(1i*0.7);


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
% 
% 
% Calculate_Power(Field_CircN + Field_CircE)





% Second pass

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

%Calculate_Power(Field_CircN + Field_CircE)


detuning = angle(Calculate_Overlap(Field_CircN,Field_CircE)); % must be 0 at the end to add up coherently

DRout.reso_North = DRout.reso_North .* exp(-1i*detuning/4);
DRout.reso_East = DRout.reso_East .* exp(1i*detuning/4);

disp('Found the phase for the resonant phase for the PRC')

end