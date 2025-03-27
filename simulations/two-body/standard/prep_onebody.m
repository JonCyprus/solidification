% This script uses data from the converged workspace from BYG2.m; namely it
% uses the quantities of p, r, v, two_body to interpolate the data onto a 2-D grid for use 
% in onebodydistribution. Additionally it will smoothly transition values
% of the p function to the farfield value at some radius r. This will align
% with the cutoff distance from MD.

%%%%   CHANGE THIS CODE, THE L/2 ARE NOT DOCUMENTED

% Adjust p depending on desired cutoff and interpolate data on 2D grid
%p_new = twobody_changeref(r,p,two_body);
conv_p_2D = interp_data(L, n, R, scale_down, r, p, two_body); %Changed to L/4 to see if works to shrink the scale accurately

mod_morse2D = interp_data(L, n, R, scale_down, r, v, 0.);%Changed to L/4
morse2D = interp_data(L, n, R, scale_down, r, v, 0.);

%g_xy = interp_data(L/2, n, R, scale_down, r, g_r, 0.);


%exchange_hole_2D = interp_data(L/2, n, L/2, scale_down, r, exchange_hole, 0.);

% Saving the files as a .mat in folder with onebodydistribution.m
file_name = 'onebody_params';
directory = 'One Body'; %Relative path (Could instead be absolute)
onebody_params = struct('conv_p_2D', conv_p_2D, 'mod_morse2D', mod_morse2D, ...
                        'morse2D', morse2D); %'g_xy', g_xy);

save_parameters('onebody_params', 'One Body', onebody_params);