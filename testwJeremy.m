n = 200; % n has to be even or it is off by a grid point
L = 10;
N = n;
% Write a note as to why we are using even n for the one-body
x = linspace(-L/2, L/2 - L/N, n)';
dx = x(2) - x(1);
f = exp(-x.^2);
df_dx = -2 * x .* exp(-x .^ 2);
df2_dx2 = 2 * exp(- x .^2) .* (2 * x.^2 - 1);

k = [0:(n/2-1), -n/2:-1]'; 
%k = (0:(n-1))';
%factor = (1 - exp(-2 * pi * 1i * (k / n)));
% factor = (exp(-2 * pi * 1i * (k-1) / n) - exp(2 * pi * 1i * (k-1) / n)) / (2 * dx);
% factor = (factor);
factor = 1i * 2 * pi * k /(L);
% lap_factor = factor .^ 2;
% lap_factor = -(2 * pi * k / (n * dx)).^2;
lap_factor = factor .^ 2;

% df_fft = real(ifft(factor .* fft(f)));
% df2_fft = real(ifft(lap_factor .* fft(f)));

f_hat = fft(f).';
df_fft = real(ifft(factor .* fft(f)));
df2_fft = real(ifft(lap_factor .* f_hat));

%%%% Stuff for toeplitz
% Test for taking spectral derivative in 1-dimesion
h = L/N; % Grid spacing
% Spectral differentiation matrix:
column = [0 .5*(-1).^(1:N-1).*cot(pi * (1:N-1)/N)]';  % for domain [-π, π]
D = toeplitz(column, column([1 N:-1:2]));
D = (2 * pi / L) * D;  % scale for domain of length L
%%%%%

%Plotting
figure(3);
plot(x, df_fft, 'b', 'linewidth', 2); hold on;
plot(x, D * f, 'r--', 'linewidth', 2); hold off;

figure(4);
clf;
subplot(2,2,1); 
hold on;
p1 = plot(nan, nan, 'b', 'linewidth', 2, 'DisplayName', 'FFT Derivative'); 
p2 = plot(x, df_dx, 'r--', 'linewidth', 1.5, 'DisplayName', 'Analytic Derivative');
p3 = plot(x, gradient(f, dx), 'g', 'DisplayName', 'Finite Diff');
p4 = plot(x, D * f, 'b-o', 'DisplayName', 'Toeplitz');
legend([p1, p2, p3, p4], 'Location', 'best');
title('First Derivative'); 
hold off;

subplot(2,2,2);
hold on;
p1 = plot(nan, nan, 'b', 'linewidth', 2, 'DisplayName', 'FFT Derivative'); 
p2 = plot(x, df2_dx2, 'r--', 'linewidth', 1.5, 'DisplayName', 'Analytic Derivative');
p3 = plot(x, gradient(gradient(f, dx),dx), 'g', 'DisplayName', 'Finite Diff');
p4 = plot(x, D * D * f, 'b-o', 'DisplayName', 'Toeplitz');
legend([p1, p2, p3, p4], 'Location', 'best');
title('Second Derivative'); 
hold off;


subplot(2,2,3), plot (x, ifft(fft(f)), 'linewidth', 3); hold on;
plot(x, f, 'r');

