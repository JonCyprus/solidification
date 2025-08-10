function [] = cleanup(sock)
%CLEANUP Summary of this function goes here
%   Detailed explanation goes here
disp("Cleaning up!")

% Close the socket connection from REPL
disp("Closing socket...");
    
if isvalid(sock)
    fclose(sock);  % closes the connection
    clear sock;   
end



end

