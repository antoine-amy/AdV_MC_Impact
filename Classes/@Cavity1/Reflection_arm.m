function Cout = Reflection_arm(Cin,varargin)
% Cout = Reflection_Arm(Cin), calculate the reflection from one arm cavity,
% different method being possible:
% Cout = Reflection_Arm(Cin,'method','full'): use the iterative (slow) method
% to find the steady state field in the cavity. exact calculation for
% carrier and sideband fields. Very slow.
%
% Cout = Reflection_Arm(Cin,'method','accelerated'): use the accelerated
% convergence scheme for the carrier and the sidebands.
% Work best when the digital integration is on. Could be slow
%
% Cout = Reflection_Arm(Cin,'method','accelerated_no_SB'): use the accelerated
% convergence scheme for the carrier, the sideband are simply reflected off
% the input mirror. Best if the SB are not resonant in the arms.
%
% Cout = Reflection_Arm(Cin,'method','simplified'): the carrier and the
% sidebands are simply reflected by the input mirror. the carrier will have
% a phase shift of pi upon reflection (to simulate overcoupled cavity).
% only useful for CITF calculations.

p = inputParser;
p.FunctionName = 'calculate the reflection from a cavity';

% check if the first argument is an interface
p.addRequired('Cin', @(x)isa(x, 'Cavity1'));

% check if the method is given
p.addParameter('method','accelerated',@(x)strcmpi(x,'full') ...
    ||strcmpi(x,'accelerated')||strcmpi(x,'accelerated_no_SB') || strcmpi(x,'simplified'));

% Check if the accuracy if given
p.addParameter('accuracy',[],@(x)isnumeric(x) && x>0);


p.parse(Cin,varargin{:})
Accuracy_given = p.Results.accuracy;


if strcmpi(p.Results.method,'full')
    if isempty(Accuracy_given)
        Cout = Calculate_Fields(Cin,'accuracy',1E-6);
    else
        Cout = Calculate_Fields(Cin,'accuracy',Accuracy_given);
    end
    
elseif strcmpi(p.Results.method,'accelerated')
    % the calculations for the carrier and the SBs
    if isempty(Accuracy_given)
        Cout =  Calculate_Fields_AC(Cin);
    else
        Cout = Calculate_Fields_AC(Cin,'accuracy',Accuracy_given);
    end
    
elseif strcmpi(p.Results.method,'accelerated_no_SB')
    % the calculations for the carrier, simple reflection for the SB
    
    if isempty(Accuracy_given)
        Cout =  Calculate_Fields_AC(Remove_SBs(Cin));
        Cout.Field_reso_guess = Cout.Field_circ;
    else
        Cout = Calculate_Fields_AC(Remove_SBs(Cin),'accuracy',Accuracy_given);
        Cout.Field_reso_guess = Cout.Field_circ;
    end
    
    % supposed the SB are reflected directly the input mirror
    [~,tmp_ref] = Transmit_Reflect_Optic(Cin.Laser_in,Cin.I_input,'AR');
    for ii = 1:Cin.Laser_in.Nb_Pair_SB
        Cout.Field_ref.SB(ii).Frequency_Offset = Cin.Laser_in.SB(ii).Frequency_Offset;
        Cout.Field_ref.SB(ii).Input_Mod_index = Cin.Laser_in.SB(ii).Input_Mod_index;
        Cout.Field_ref.SB(ii).Field_lower = tmp_ref.SB(SB_number).Field_lower*1/Cin.I_input.r;
        Cout.Field_ref.SB(ii).Field_upper = tmp_ref.SB(SB_number).Field_upper*1/Cin.I_input.r;
    end
    
    % We do not calculate the power in the SB in the arm cavity, so set the
    %  circulating and transmitted SB field to zero
    for ii = 1:Cin.Laser_in.Nb_Pair_SB
        Cout.Field_circ.SB(ii).Frequency_Offset = Cin.Laser_in.SB(ii).Frequency_Offset;
        Cout.Field_circ.SB(ii).Input_Mod_index = Cin.Laser_in.SB(ii).Input_Mod_index;
        Cout.Field_circ.SB(ii).Field_lower = zeros(Cout.Field_circ.Grid.Num_point);
        Cout.Field_circ.SB(ii).Field_upper = zeros(Cout.Field_circ.Grid.Num_point);
        
        Cout.Field_trans.SB(ii).Frequency_Offset = Cin.Laser_in.SB(ii).Frequency_Offset;
        Cout.Field_trans.SB(ii).Input_Mod_index = Cin.Laser_in.SB(ii).Input_Mod_index;
        Cout.Field_trans.SB(ii).Field_lower = zeros(Cout.Field_circ.Grid.Num_point);
        Cout.Field_trans.SB(ii).Field_upper = zeros(Cout.Field_circ.Grid.Num_point);
    end
    
    
else % simplified method
    R_arm = 0.98; % reflectivity of the arm for the carrier
    
    Cout = Cin;
    [~,tmp_ref] = Transmit_Reflect_Optic(Cin.Laser_in,Cin.I_input,'AR');
    Cout.Field_ref = tmp_ref;
    Cout.Field_circ = tmp_ref; % put something dummy there
    
    % Add a pi phase shift for the carrier
    Cout.Field_ref.Field = Cout.Field_ref.Field *(-1) * sqrt(R_arm);
    
    % Correct for the transmission of the mirror
    Cout.Field_ref.Field_SBl = Cout.Field_ref.Field_SBl*1/Cin.I_input.r;
    Cout.Field_ref.Field_SBu = Cout.Field_ref.Field_SBu*1/Cin.I_input.r;
    
    for ii = 1:Cout.Field_ref.Nb_Pair_SB
        Cout.Field_ref.SB(ii).Field_lower = Cout.Field_ref.SB(ii).Field_lower*1/Cin.I_input.r;
        Cout.Field_ref.SB(ii).Field_upper = Cout.Field_ref.SB(ii).Field_upper*1/Cin.I_input.r;
    end
    
    
    
end




end