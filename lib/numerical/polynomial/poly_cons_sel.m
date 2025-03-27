function [output] = poly_cons_sel(action, varargin)
% Ask Jeremy if it would be cleaner to have constructors and selectors
% in a folder or within a master  function like this

switch action
    case 'create_cond'
        output = create_cond(varargin{:});
    case 'combine_conditions'
        output = combine_conditions(varargin{:});
    case 'cond_count'
        output = cond_count(varargin{:});
    case 'get_x'
        output = get_x(varargin{:});
    case'get_y'
        output = get_y(varargin{:});
    case'get_deriv'
        output = get_deriv(varargin{:});
end


% Helper functions for programs that use poly_solver
    % This constructor and selectors will assume that data is a vector of boundary
    % conditions formatted as an vector of x y z. e.g [[1 2 3], [4 5 6]]
    %conditions are concatenated on construction of arrays. (NOT CELL
    % ARRAY)

% Constructor subfunction for singular conditions
    function[condition] = create_cond(x1, y1, n_deriv)
        condition = [x1 y1 n_deriv];
    end

% Constructor subfunction for combining conditions (due to structure we can
% use for appending conditions as well)
    function[all_conditions] = combine_conditions(varargin)
        all_conditions = [varargin{:}];
    end
% Counter subfunction
    function[count] = cond_count(array)
        count = (length(array)/3) - 1;
    end

% Selector subfunction for x
    function[x_val] = get_x(array, i)
        condition_num = (i - 1) * 3;
        x_val = array(condition_num + 1);
    end

% Selector subfunction for y
    function[y_val] = get_y(array, i)
        condition_num = (i - 1) * 3;
        y_val = array(condition_num + 2);
    end

% Selector subfunction for deriv number
    function[deriv_val] = get_deriv(array, i)
        condition_num = (i - 1) * 3;
        deriv_val = array(condition_num + 3);
    end

end

