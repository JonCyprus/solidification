function save_parameters(file_name, directory, parameters)
    % This function saves given parameters to a .mat file in the specified directory.

    % Inputs:
    % file_name - Name of the file to be saved.
    % directory - Directory where the file will be saved.
    % parameters - A structure containing the parameters to be saved.

    % % Check if the directory exists, if not, create it
    % if ~exist(directory, 'dir')
    %     mkdir(directory);
    % end

    % Full file path
    full_file_path = fullfile(directory, [file_name, '.mat']);

    % Save the parameters to the .mat file
    save(full_file_path, '-struct', 'parameters');

    % Display a message
    fprintf('File saved to %s\n', full_file_path);
end
