function DRout = Calculate_fields2(DRin,varargin)
% Cout = Calculate_fields(DRin) calculate the circulating, reflected and
% transmitted fields for the CITF.

p = inputParser;
p.FunctionName = 'Calculate fields inside the cavity';

% Check if the first argument is an interface
p.addRequired('DRin', @(x)isa(x, 'Dual_recycling'));

% Check if the resolution of the grid if given
p.addParameter('accuracy',[],@(x)isnumeric(x) && x>0);

% Check if the resolution of the grid if given
p.addParameter('iter',[],@(x)isnumeric(x) && x>0);

% Check if we calculate only the SB response
p.addParameter('Only_SB',false,@(x)islogical(x));

% Check if we display stuff or not
p.addParameter('display',true,@(x)islogical(x));

p.parse(DRin,varargin{:})

if isempty(DRin.reso_North)
    error(['Calculate_fields(' inputname(1) '): The resonance position must be calculated first'])
end

DRout = DRin;

% Simplify the variable for easy understanding
NA = DRin.North_arm;
EA = DRin.East_arm;

if ~isempty(p.Results.accuracy)
    Accuracy = p.Results.accuracy;
else
    Accuracy = 0.005;
end

% Calculate the number of iteration to reach the steady state
RT_loss = DRin.I_PRM.r;
% Have to solve RT_loss^num_iter < 0.5*accuracy
num_iter = log(0.5*Accuracy)/(log(RT_loss));

if ~isempty(p.Results.iter) % overide the numbers of iteration
    num_iter = p.Results.iter;
end
num_iter = round(num_iter);

Display_set = p.Results.display;

%num_iter = 10;

% the laser beam is defined outside the PRC so first pass through the PRM
% substrate
Field_in =  Change_E_n(DRin.Laser_in,DRin.I_PRM.n2);
[Field_in, Field_ref]= Transmit_Reflect_Interface(Field_in,DRin.I_PRM);



% Set to 0 the required fields
PRC.Power_buildup = zeros(1,num_iter);
PRC.Power_buildup_SB = zeros(1,num_iter);

PRC.Field_Circ = Normalise_E(Field_in,0);
PRC.Field_DP = Normalise_E(Field_in,0);
PRC.Field_S = Normalise_E(Field_in,0);
PRC.Field_leak = Normalise_E(Field_in,0);
PRC.Field_NA_circ = Normalise_E(Field_in,0);
PRC.Field_EA_circ = Normalise_E(Field_in,0);
PRC.Field_Ref_East = Normalise_E(Field_in,0);

PRC.Field_transient_W = Field_in;

if Display_set
    disp('      ')
end

for q = 1:num_iter
    
    PRC.Field_Circ = PRC.Field_Circ + PRC.Field_transient_W;
    PRC.Power_buildup(q) = Calculate_power(PRC.Field_Circ);
    
    %     figure(1)
    %     E_plot(PRC.Field_transient_W);pause(0.1)
    %     title(num2str(q))
    
    if ~isempty(DRin.Laser_in.Field_SBl)
        PRC.Power_buildup_SB(q) = Calculate_power_SB(PRC.Field_Circ);
    end
    
    % Propagate the field toward the BS
    PRC.Field_transient_W = Propagate_E(PRC.Field_transient_W,DRin.Propagation_mat_PRM_BS);
    PRC.Field_S = Propagate_E(PRC.Field_S,DRin.Propagation_mat_SRM_BS);
    
    % Transmit and reflected the fields by the BS coming from PRM and SRM
    [PRC.Field_transient_WE, PRC.Field_transient_WN] = Transmit_Reflect_Interface(PRC.Field_transient_W,DRin.I_BS_Ref_out);
    [PRC.Field_transient_SN, PRC.Field_transient_SE] = Transmit_Reflect_Interface(PRC.Field_transient_W,DRin.I_BS_Ref_in);
    
    
    % Field coming toward the west (PRM) is reflected by the BS and interfere with the
    % field coming from the dark port
    PRC.Field_transient_N = PRC.Field_transient_WN + PRC.Field_transient_SN;
    
    % Field coming toward the west (PRM) is transmitted by the BS and interfere with the
    % field coming from the dark port and reflected by BS
    %PRC.Field_transient_WE.Field = PRC.Field_transient_WE.Field .* exp(1i*Field_in.k_prop*DRin.BS_OPD_trans);
    PRC.Field_transient_E = PRC.Field_transient_WE + PRC.Field_transient_SE;
    
    % propagate to the arm cavity input mirror and add the phase shift for the resonnace
    PRC.Field_transient_N = Propagate_E(PRC.Field_transient_N,DRin.Propagation_mat_BS_NIM);
    PRC.Field_transient_E = Propagate_E(PRC.Field_transient_E,DRin.Propagation_mat_BS_EIM);
    
    PRC.Field_transient_N = PRC.Field_transient_N * DRin.reso_North;
    PRC.Field_transient_E = PRC.Field_transient_E * DRin.reso_East;
    
    % Reflection from the arm cavity
    %Fit_TEM00(PRC.Field_transient_N)
    
    NA.Laser_in = PRC.Field_transient_N; % _no_SB
    if p.Results.Only_SB
        NA = Reflection_arm(NA,'method','simplified');
    else
        NA = Reflection_arm(NA,'method','accelerated_no_SB'); % full or accelerated
        %NA = Reflection_arm(NA,'method','accelerated');
    end
    
    PRC.Field_NA_circ = PRC.Field_NA_circ + NA.Field_circ;
    PRC.Field_transient_N = NA.Field_ref;
    
    EA.Laser_in = PRC.Field_transient_E;
    
    if p.Results.Only_SB
        EA = Reflection_arm(EA,'method','simplified');
        
    else
        EA = Reflection_arm(EA,'method','accelerated_no_SB'); % full or accelerated
        %EA = Reflection_arm(EA,'method','accelerated');
    end
    PRC.Field_Ref_East =  PRC.Field_Ref_East + EA.Field_ref;
    
    PRC.Field_EA_circ = PRC.Field_EA_circ + EA.Field_circ;
    PRC.Field_transient_E = EA.Field_ref;
    
    % To bring on the dark fringe
    PRC.Field_transient_E = (-1)*PRC.Field_transient_E;
    
    % Simulate baffles
    %      PRC.Field_transient_N = Transmit_Aperture(PRC.Field_transient_N,0.33);
    %      PRC.Field_transient_E = Transmit_Aperture(PRC.Field_transient_E,0.33);
    %      PRC.Field_transient_N = Cut_angular_frequencies(PRC.Field_transient_N);
    %      PRC.Field_transient_E = Cut_angular_frequencies(PRC.Field_transient_E);
    
    % add the phase shift for the resonnace
    PRC.Field_transient_N = PRC.Field_transient_N * DRin.reso_North;
    PRC.Field_transient_E = PRC.Field_transient_E * DRin.reso_East;
    
    % Then propagate back toward the BS
    PRC.Field_transient_N = Propagate_E(PRC.Field_transient_N,DRin.Propagation_mat_BS_NIM);
    PRC.Field_transient_E = Propagate_E(PRC.Field_transient_E,DRin.Propagation_mat_BS_EIM);
    
    % Get the fields from North arm and east arm and reflect from BS
    [PRC.Field_transient_NS, PRC.Field_transient_NW] = Transmit_Reflect_Interface(PRC.Field_transient_N,DRin.I_BS_Ref_out);
    [PRC.Field_transient_EW, PRC.Field_transient_ES] = Transmit_Reflect_Interface(PRC.Field_transient_E,DRin.I_BS_Ref_in);
    
    %PRC.Field_transient_EW.Field = PRC.Field_transient_EW.Field .* exp(1i*Field_in.k_prop*fliplr(DRin.BS_OPD_trans));
    
    PRC.Field_transient_W = PRC.Field_transient_NW + PRC.Field_transient_EW;
    
    % East arm reflected by BS and then add what is coming from the east
    % then go to PRM
    
    PRC.Field_S = PRC.Field_transient_NS + PRC.Field_transient_ES;
    
    % Then propagate toward PRM and SRM and reflect
    PRC.Field_transient_W = Propagate_E(PRC.Field_transient_W,DRin.Propagation_mat_PRM_BS);
    
    PRC.Field_leak = PRC.Field_leak + PRC.Field_transient_W;
    PRC.Field_transient_W = Reflect_mirror(PRC.Field_transient_W,DRin.I_PRM);
    
    PRC.Field_S = Propagate_E(PRC.Field_S,DRin.Propagation_mat_SRM_BS);
    PRC.Field_S = PRC.Field_S * exp(1i*DRin.reso_South);   
    PRC.Field_DP = PRC.Field_DP + PRC.Field_S;
    PRC.Field_S = Reflect_mirror(PRC.Field_S,DRin.I_SRM);
    PRC.Field_S = PRC.Field_S * exp(1i*DRin.reso_South);
    
    %figure(1); E_plot(PRC.Field_DP); pause(0.1)
    
    %PRC.Field_S = PRC.Field_S * exp(1i*0.3);
    if Display_set
        fprintf('\b\b\b\b\b\b')
        fprintf('%4.0i %%',round(q*100/num_iter))
    end
end

if Display_set
    disp('Finished!')
end

DRout.Field_circ = PRC.Field_Circ;
DRout.Field_DP = PRC.Field_DP;
DRout.Power_buildup = PRC.Power_buildup;
DRout.Power_buildup_SB = PRC.Power_buildup_SB;

DRout.Field_POP = PRC.Field_leak;
DRout.Field_Ref_East = PRC.Field_Ref_East;

DRout.Field_NA_circ = PRC.Field_NA_circ;
DRout.Field_EA_circ = PRC.Field_EA_circ;


% Calculate the reflected field and then the total reflected beam
PRC.Field_leak = Transmit_Reflect_Interface(PRC.Field_leak,DRin.I_PRM);
DRout.Field_ref = Field_ref + PRC.Field_leak;

% figure(108)
% plot(a)
end