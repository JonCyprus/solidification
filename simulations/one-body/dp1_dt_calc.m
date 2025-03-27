function [k] = dp1_dt_calc(p1,delta, kbT, p2, fw1, fwx2, fwy2, dA, one_body, G)
% Calculates dp1_dt for calculating the time evolution
% This function is a re-use of the code in onebody distribution for use in
% RK4 method. This just calculates the change of the function with
% previously calculated values with some given time step (for use in RK4).

    grad_p1_x = nablax(p1,delta);
    grad_p1_y = nablay(p1,delta);
    lap_p1 = laplacian3(p1,delta);

    % 1st Term
    first = kbT .* lap_p1;

    % 2nd Term
    fp = fft2( p2 ); 
    int1 = real(ifft2 (fw1 .* fp));
    intx2 = real(ifft2 ( fwx2 .* fp ));
    inty2 = real(ifft2( fwy2 .* fp ));

    % Total Contribution:
    integral1 = int1 .* p1 * dA;
    integral2 = (- intx2 .* grad_p1_x - inty2 .* grad_p1_y)*dA; %Changed to minus
    second = (integral1 + integral2)./(one_body ^2);

    k = G * (first + second);

end

