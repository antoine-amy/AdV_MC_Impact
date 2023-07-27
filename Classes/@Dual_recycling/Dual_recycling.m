classdef Dual_recycling
    %AV_DR: define a dual recycling interferometer with 2 FP arm cavities
       
    properties
        % The North arm is reached after reflexion on the beam splitter.
        % The East arm is along the transmission from the BS.
        
        I_PRM               % could be interface or mirror, HR inside the PR cavity
        I_SRM               % could be interface or mirror, HR inside the PR cavity
        
        I_BS_Ref_out        % Interface, map of the HR side of the BS (seen at 45 degree), seen by beam from PR to north arm
        I_BS_Ref_in         % Interface, map of the HR side of the BS (seen at 45 degree), reflection in the substrate (opposite to I_BS_Ref_out)
        BS_OPD_trans        % BS optical wavefront distortion given as OPN
        
        North_arm      % should be a cavity, AR side of the input mirror inside the PR cavity
        East_arm       % should be a cavity, AR side of the input mirror inside the PR cavity
        
        Laser_in            % Defined the laser beam, by default on PRM AR side, so outside the PRC
        
        d_PRM_BS            % Distance PRM - BS
        d_BS_NIM            % Distance BS - input mirror north arm
        d_BS_EIM            % Distance BS - input mirror east arm
        
        d_SRM_BS            %  Distance BS - SRM
        
        BS_r
        BS_t
        
        Field_circ = [];    % Field circulating in the PRC
        Field_ref = [];     % Field reflected by the PRC
        Field_DP = [];      % Field at the dark port
        Field_POP = [];      % Field toward the POP (B4)
        Field_Ref_East = [];      % Field reflected east arm (B5)
        
        Power_buildup = []; % Power buildup as the functions of inerations
        Power_buildup_SB = []; % Power buildup of the sidebands                                                                                -
        
        Field_NA_circ = []; % Field circulating in the north arm cavity
        Field_EA_circ = []; % Field circulating in the east arm cavity
             
        reso_North
        reso_East
        reso_South       % tuning for SRM [0 2pi]
        
        Propagation_mat_PRM_BS     % Pre-compute the complex matrix used for the propagation
        Propagation_mat_BS_NIM
        Propagation_mat_BS_EIM
        Propagation_mat_SRM_BS
        
        Cavity_phase_param = 10;         % Number of round trip to do to find the resonance condition (use in DR_resonance_phase() )
    end
    
    methods
        
        function P = Dual_recycling(varargin)
            
            switch nargin
                case{0,1,2,3,4,5,6,7,8}
                    disp('Dual_recycling(): at least 8 arguments must be given: 4 interface/mirrors/cavity, 4 lengths, one laser beam')
                    return
                case 9
                    if  ~(isa(varargin{1}, 'Interface') || isa(varargin{1}, 'Mirror'))
                        error('Dual_recycling(): the first argument (PRM) must be an instance of the class Interface or Mirror')
                    end
                    
                    if  ~(isa(varargin{2}, 'Interface') || isa(varargin{2}, 'Mirror'))
                        error('Dual_recycling(): the second argument (SRM) must be an instance of the class Interface or Mirror')
                    end
                    
                    if  ~isa(varargin{3}, 'Cavity1')
                        error('Dual_recycling(): the third argument (North arm input mirror) must be an instance of the class Mirror')
                    end
                    
                    if  ~isa(varargin{4}, 'Cavity1')
                        error('Dual_recycling(): the fourth argument (East arm input mirror) must be an instance of the class Mirror')
                    end
                    
                    if  ~isa(varargin{5}, 'double')
                        error('Dual_recycling(): the fifth argument must be a scalar, the distance PRM-BS')
                    end
                    
                    if  ~isa(varargin{6}, 'double')
                        error('Dual_recycling(): the sixth argument must be a scalar, the distance BS - North input mirror')
                    end
                    if  ~isa(varargin{7}, 'double')
                        error('Dual_recycling(): the seventh argument must be a scalar, the distance BS - East input mirror')
                    end
                    
                    if  ~isa(varargin{8}, 'double')
                        error('Dual_recycling(): the eight argument must be a scalar, the distance SRM-BS')
                    end
                    
                    if  ~isa(varargin{9}, 'E_Field')
                        disp('Dual_recycling(): the ninth argument must be an instance of the class E_field, the input laser beam')
                        return
                    end
                    
                    P.I_PRM = varargin{1};
                    P.I_SRM = varargin{2};
                    
                    P.North_arm = varargin{3};
                    P.East_arm = varargin{4};
                    
                    P.d_PRM_BS = varargin{5};
                    P.d_BS_NIM = varargin{6};
                    P.d_BS_EIM = varargin{7};
                    P.d_SRM_BS = varargin{8};
                    
                    P.Laser_in = varargin{9};
                                        
                    % Pre calculate the propagation matrix
                    
                    P.Propagation_mat_PRM_BS = Prop_operator(P.Laser_in,P.d_PRM_BS);                 
                    P.Propagation_mat_BS_NIM =  Prop_operator(P.Laser_in,P.d_BS_NIM);
                    P.Propagation_mat_BS_EIM =  Prop_operator(P.Laser_in,P.d_BS_EIM);
                    P.Propagation_mat_SRM_BS =  Prop_operator(P.Laser_in,P.d_SRM_BS);
                    
                    % Default map for the BS:
                    P.I_BS_Ref_out = Interface(P.Laser_in.Grid,'RoC',Inf,'T',0.5); 
                    P.I_BS_Ref_in = Interface(P.Laser_in.Grid,'RoC',Inf,'T',0.5);
                    P.BS_OPD_trans = zeros(P.Laser_in.Grid.Num_point);       
                    
                    % Calculate the amplitude reflectivity and
                    % transmissivity of the BS                    
                    %P.BS_r = sqrt(1-P.I_BS_Ref.T);
                    %P.BS_t = 1i*sqrt(P.I_BS_Ref.T);
                    
                    P.reso_South  = 0;
                    
                otherwise
                    disp('Dual_recycling(): invalid number of input arguments, PRC not created')
                    
            end
            
        end
        
    end
   
end