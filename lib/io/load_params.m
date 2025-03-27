function params = load_params(filepath)
    % Load a JSON file and decode into a MATLAB struct
    fid = fopen(filepath, 'r');
    if fid == -1
        error('Could not open parameter file: %s', filepath);
    end
    raw = fread(fid, inf, 'uint8=>char')';
    fclose(fid);
    params = jsondecode(raw);
end
