function Check_matching(varargin)
% Check_matching(P1) Do 2 round trip of the input field in the CITF cavity and
% check the size and wavefront curvature of the beam on the mirrors to see
% if the matching is correct.
% Check_matching(P1,n) Do n round trip in the cavity



switch nargin
    case 0
        disp('Check_matching(): not enough arguments, at least an object Cavity1/PRC/CITF must be given')
        return
        
    case 1
        if isa(varargin{1}, 'CITF')
            Pin = varargin{1};
            Num_iter = 2;
        else
            disp('Check_matching(): The first argument must be an instance of the class CITF')
            return
        end
        
    case 2
        if ~isa(varargin{1}, 'CITF')
            disp('Check_matching(): The first argument must be an instance of the class CITF')           
            return
        end
        
        if ~real(varargin{2})
            disp('Check_matching(): if 2 arguments, the second one must be a number of iteration')
            return
        end
        Pin = varargin{1};
        Num_iter = round(varargin{2});
        
    otherwise
        disp('Calculate_power(): Invalid number of input arguments, no power calculation is made')
        return
end

% first, transmit the laser beam through PRM

Field_in = Change_E_n(Pin.Laser_in,Pin.I_PRM.n2);
Field_in = Transmit_Reflect_Interface(Field_in,Pin.I_PRM);

Field_Circ = Field_in;

for ii=1:Num_iter
    fprintf(' \n Round trip number: %i  \n',ii)
    [Beam_rad Beam_RofC] = Fit_TEM00(Field_Circ);
    fprintf('After the PRM mirror,  beam radius [m]: %7.4f \t wavefront RofC [m]: %5.2e \n',Beam_rad,Beam_RofC)
    
    % Take care of the North arm
    Field_CircN = Propagate_E(Field_Circ,Pin.Propagation_mat_PRM_NIM);
    [Beam_rad Beam_RofC] = Fit_TEM00(Field_CircN);
    fprintf('Before the North arm mirror,   beam radius [m]: %7.4f \t wavefront RofC [m]: %5.2e \n',Beam_rad,Beam_RofC)
    
    [~,Field_CircN] = Transmit_Reflect_Mirror(Field_CircN,Pin.I_North_mirror,'AR');
    [Beam_rad Beam_RofC] = Fit_TEM00(Field_CircN);
    fprintf('After the North arm mirror,   beam radius [m]: %7.4f \t wavefront RofC [m]: %5.2e \n',Beam_rad,Beam_RofC)
    
    % Take care of the East arm
    Field_CircE = Propagate_E(Field_Circ,Pin.Propagation_mat_PRM_EIM);
    [Beam_rad Beam_RofC] = Fit_TEM00(Field_CircE);
    fprintf('Before the East arm mirror,   beam radius [m]: %7.4f \t wavefront RofC [m]: %5.2e \n',Beam_rad,Beam_RofC)
    
    [~,Field_CircE] = Transmit_Reflect_Mirror(Field_CircE,Pin.I_East_mirror,'AR');
    [Beam_rad Beam_RofC] = Fit_TEM00(Field_CircE);
    fprintf('After the East arm mirror,   beam radius [m]: %7.4f \t wavefront RofC [m]: %5.2e \n',Beam_rad,Beam_RofC)
    
    % Propagates the 2 beams back to PRM
    Field_CircE = Propagate_E(Field_CircE,Pin.Propagation_mat_PRM_EIM);
    Field_CircN = Propagate_E(Field_CircN,Pin.Propagation_mat_PRM_NIM);
    
    % Put the beam on the bright fringe
    Angle_diff = angle(Calculate_Overlap(Field_CircN,Field_CircE));
    Field_CircE = Field_CircE * exp(1i *(Angle_diff));
    
    Field_Circ = Field_CircN + Field_CircE;
    
    [Beam_rad Beam_RofC] = Fit_TEM00(Field_Circ);
    fprintf('Before the input mirror, beam radius [m]: %7.4f \t wavefront RofC [m]: %5.2e \n',Beam_rad,Beam_RofC)
    
    Field_Circ = Reflect_mirror(Field_Circ,Pin.I_PRM);
    
    %figure(ii);E_plot(Field_Circ)
end

end










