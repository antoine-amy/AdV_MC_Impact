function [p_vert,q_vert,p_horiz,q_horiz] = Demodulate_quad_SB(Ein,varargin)
% [p q] = Demodulate_SB(E1), demodulate the carrier with the sidebdands
% [p q] are the signal in phase and in quadrature

p_vert = inputParser;
p_vert.FunctionName = 'Demodulate a signal';

% Check if the first argument is a E_Field
p_vert.addRequired('Ein', @(x)isa(x, 'E_Field'));

% Check the number of the sidebands we want to deal with
p_vert.addParameter('SB_num',1, @(x) isnumeric(x)  && (x>0) && (mod(x,1) == 0)); % check if the number of the SB pair is positive and integer

% Check if a demodulation phase is given (must be in radian)
p_vert.addParameter('phase',0,@(x)isnumeric(x));

p_vert.parse(Ein,varargin{:})

if ~Ein.Nb_Pair_SB
    error('Demodulate_SB(): no sidebands are present')
end

SB_number = p_vert.Results.SB_num;

% Check the number of SB fields to be correct
if SB_number > Ein.Nb_Pair_SB
    error('Demodulate_SB(): requested SB field not present')
end

% Calculate the size of the quadrant
[n_rows, n_columns] = size(Ein.Field);
rows_half = n_rows / 2;
columns_half = n_columns / 2;

% Divide the input field into four quadrants
Q1 = Ein.Field(1:rows_half, 1:columns_half);
Q2 = Ein.Field(1:rows_half, columns_half+1:end);
Q3 = Ein.Field(rows_half+1:end, 1:columns_half);
Q4 = Ein.Field(rows_half+1:end, columns_half+1:end);

% Calculate the Esignal for each quadrant
Esignal_Q1 = sum(sum(Q1.*conj(Ein.SB(SB_number).Field_upper(1:rows_half, 1:columns_half))+conj(Q1).*Ein.SB(SB_number).Field_lower(1:rows_half, 1:columns_half))) * (Ein.Grid.Step)^2;
Esignal_Q1 = Esignal_Q1 * exp(1i*p_vert.Results.phase);

Esignal_Q2 = sum(sum(Q2.*conj(Ein.SB(SB_number).Field_upper(1:rows_half, columns_half+1:end))+conj(Q2).*Ein.SB(SB_number).Field_lower(1:rows_half, columns_half+1:end))) * (Ein.Grid.Step)^2;
Esignal_Q2 = Esignal_Q2 * exp(1i*p_vert.Results.phase);

Esignal_Q3 = sum(sum(Q3.*conj(Ein.SB(SB_number).Field_upper(rows_half+1:end, 1:columns_half))+conj(Q3).*Ein.SB(SB_number).Field_lower(rows_half+1:end, 1:columns_half))) * (Ein.Grid.Step)^2;
Esignal_Q3 = Esignal_Q3 * exp(1i*p_vert.Results.phase);

Esignal_Q4 = sum(sum(Q4.*conj(Ein.SB(SB_number).Field_upper(rows_half+1:end, columns_half+1:end))+conj(Q4).*Ein.SB(SB_number).Field_lower(rows_half+1:end, columns_half+1:end))) * (Ein.Grid.Step)^2;
Esignal_Q4 = Esignal_Q4 * exp(1i*p_vert.Results.phase);

p_vert = real((Esignal_Q1+Esignal_Q2)-(Esignal_Q3+Esignal_Q4)); %top-bottom
q_vert = imag((Esignal_Q1+Esignal_Q2)-(Esignal_Q3+Esignal_Q4));

p_horiz = real((Esignal_Q2+Esignal_Q4)-(Esignal_Q1+Esignal_Q3)); %right-left
q_horiz = imag((Esignal_Q2+Esignal_Q4)-(Esignal_Q1+Esignal_Q3));

end