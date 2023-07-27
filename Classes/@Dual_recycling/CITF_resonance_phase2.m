function DRout = CITF_resonance_phase2(DRin)
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

Arm_convergence_scheme = 'accelerated_no_SB';
num_iter = DRin.Cavity_phase_param;
E_in = DRin.Laser_in;

% Simplify the variable for easy understanding
NA = DRin.North_arm;
EA = DRin.East_arm;

NA = Calculate_fields(NA,'method','accelerated','accuracy',1E-03);
Field_Circ = NA.Field_ref;

% Go toward the PRM
Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_BS_NIM);
[~,Field_Circ] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref);
Field_Circ.Field = fliplr(Field_Circ.Field);
Field_Circ.Field_SBl = fliplr(Field_Circ.Field_SBl);
Field_Circ.Field_SBu = fliplr(Field_Circ.Field_SBu);

Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
Field_Circ = Reflect_mirror(Field_Circ,DRin.I_PRM);

Field_total = Normalise_E(Field_Circ,0);
Phase_adjust = 1;

% First for the North path

for q = 1:num_iter
    
    Field_total = Field_total + Field_Circ;
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
    [~,Field_Circ] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref);
    Field_Circ.Field = fliplr(Field_Circ.Field);
    Field_Circ.Field_SBl = fliplr(Field_Circ.Field_SBl);
    Field_Circ.Field_SBu = fliplr(Field_Circ.Field_SBu);
    %
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_BS_NIM); % Correct for the beamsplitter reflectivity
    
    % (1/abs(DRin.BS_r))*
    % Check what is reflected from the cavity
    NA.Laser_in = Field_Circ;
    NA = Reflection_arm(NA,'method',Arm_convergence_scheme);
    Field_Circ = NA.Field_ref;
    
    % Back to the beam splitter toward PRM
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_BS_NIM)*Phase_adjust;
    [~,Field_Circ] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref);
    Field_Circ.Field = fliplr(Field_Circ.Field);
    Field_Circ.Field_SBl = fliplr(Field_Circ.Field_SBl);
    Field_Circ.Field_SBu = fliplr(Field_Circ.Field_SBu);
    %
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
    
    Field_Circ = Reflect_mirror(Field_Circ,DRin.I_PRM);
    
    Phase_adjust = Phase_adjust * exp(-1i*angle(Calculate_Overlap(Field_Circ,Field_total)));
    %   figure(1); E_plot(Field_total); pause(0.1)
    %sqrt(exp(-1i* angle(Calculate_Overlap(Field_Circ,Field_before))))
end


% Then find the round trip to make the eigen mode on resonnance for the
% North arm

Field_before = Field_total;
Field_Circ = Field_total;

Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
[~,Field_Circ] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref);
Field_Circ.Field = fliplr(Field_Circ.Field);
Field_Circ.Field_SBl = fliplr(Field_Circ.Field_SBl);
Field_Circ.Field_SBu = fliplr(Field_Circ.Field_SBu);


Field_Circ = (1/abs(DRin.BS_r))*Propagate_E(Field_Circ,DRin.Propagation_mat_BS_NIM); % Correct for the beamsplitter reflectivity

% Check what is reflected from the cavity
NA.Laser_in = Field_Circ;
NA = Reflection_arm(NA,'method',Arm_convergence_scheme);
Field_Circ = NA.Field_ref;

% Back to the beam splitter toward PRM
Field_Circ = (1/abs(DRin.BS_r))*Propagate_E(Field_Circ,DRin.Propagation_mat_BS_NIM);
[~,Field_Circ] = Transmit_Reflect_Interface(Field_Circ,DRin.I_BS_Ref);
Field_Circ.Field = fliplr(Field_Circ.Field);
Field_Circ.Field_SBl = fliplr(Field_Circ.Field_SBl);
Field_Circ.Field_SBu = fliplr(Field_Circ.Field_SBu);


Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);

Field_Circ = Reflect_mirror(Field_Circ,DRin.I_PRM);

DRout.reso_North = exp(-1i* angle(Calculate_Overlap(Field_Circ,Field_before)));
DRout.reso_North = sqrt(DRout.reso_North);
%Calculate_Overlap(Field_Circ,Field_before)

%---------------------------------------------------------------------------------------------------------------------------------------------------
% Then for the East side

% Start from the beam reflected by the east arm
EA = Calculate_fields_AC(EA);
Field_Circ = EA.Field_ref;
Field_Circ = (-1)*Field_Circ;   % (-1)  to be on the dark fringe

% Back to the beam splitter toward PRM
Field_Circ = (DRin.BS_t/abs(DRin.BS_t))*Propagate_E(Field_Circ,DRin.Propagation_mat_BS_EIM);
Field_Circ.Field = Field_Circ.Field .* exp(1i*Field_Circ.k_prop*fliplr(DRin.BS_OPD_trans));
Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
Field_Circ = Reflect_mirror(Field_Circ,DRin.I_PRM);

Field_total = Normalise_E(Field_Circ,0);
Phase_adjust =1;

for q = 1:num_iter
    
    Field_total = Field_total + Field_Circ;
    
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
    Field_Circ.Field = Field_Circ.Field .* exp(1i*Field_Circ.k_prop*DRin.BS_OPD_trans);
    Field_Circ = (DRin.BS_t/abs(DRin.BS_t))*Propagate_E(Field_Circ,DRin.Propagation_mat_BS_EIM); % Correct for the beamsplitter transmission
    
    % Check what is reflected from the cavity
    EA.Laser_in = Field_Circ;
    EA = Reflection_arm(EA,'method',Arm_convergence_scheme);
    Field_Circ = EA.Field_ref;
    Field_Circ = (-1)*Field_Circ;   % (-1)  to be on the dark fringe
    
    % Back to the beam splitter toward PRM
    Field_Circ = (DRin.BS_t/abs(DRin.BS_t))*Propagate_E(Field_Circ,DRin.Propagation_mat_BS_EIM)*Phase_adjust;
    Field_Circ.Field = Field_Circ.Field .* exp(1i*Field_Circ.k_prop*fliplr(DRin.BS_OPD_trans));
    Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
    Field_Circ = Reflect_mirror(Field_Circ,DRin.I_PRM);
    
    Phase_adjust = Phase_adjust * exp(-1i*angle(Calculate_Overlap(Field_Circ,Field_total)));
    
end

% Then find the round trip to make the eigen mode on resonnance

Field_before = Field_total;
Field_Circ = Field_total;

Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
Field_Circ.Field = Field_Circ.Field .* exp(1i*Field_Circ.k_prop*DRin.BS_OPD_trans);
Field_Circ = (DRin.BS_t/abs(DRin.BS_t))*Propagate_E(Field_Circ,DRin.Propagation_mat_BS_EIM); % Correct for the beamsplitter reflectivity

% Check what is reflected from the cavity
EA.Laser_in = Field_Circ;
EA = Reflection_arm(EA,'method',Arm_convergence_scheme);
Field_Circ = EA.Field_ref;
Field_Circ = (-1)*Field_Circ;   % (-1)  to be on the dark fringe


% Back to the beam splitter toward PRM
Field_Circ = (DRin.BS_t/abs(DRin.BS_t))*Propagate_E(Field_Circ,DRin.Propagation_mat_BS_EIM);
Field_Circ.Field = Field_Circ.Field .* exp(1i*Field_Circ.k_prop*fliplr(DRin.BS_OPD_trans));
Field_Circ = Propagate_E(Field_Circ,DRin.Propagation_mat_PRM_BS);
Field_Circ = Reflect_mirror(Field_Circ,DRin.I_PRM);

DRout.reso_East = exp(-1i* angle(Calculate_Overlap(Field_Circ,Field_before)));
DRout.reso_East = sqrt(DRout.reso_East);

disp('Found the phase for the resonant phase for the PRC')

end