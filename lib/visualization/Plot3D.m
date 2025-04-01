function [] = Plot3D(fignum, step, n, KbT, N, x2, y2, p1)
%Plots the 3-D surface of the one-body distribution function. Saves figures
%to One_body Figures
        figure(fignum);
        surf(x2,y2,p1, 'EdgeAlpha', 0);
        title(['Total steps = ' num2str(step),'   n =', num2str(n),'   KbT = ', num2str(KbT),'   N=',num2str(N)]);
        az = 90;
        el = -90;
        view([az,el])
        colorbar
        axis tight

        filename1= fullfile('One_body Figures', ['onebody_', num2str(step), '.png']);
        % saveas(gcf, filename1)

end

