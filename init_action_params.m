function params = init_action_params()

alpha   = 2;        % parameter for the geq in constraint
kapa    = 1;        % penalization for the slack
lambda  = 1e-6;     % regularization constant

params = struct('coordinate', 'actions', ...
                'alpha', alpha, ...
                'kapa', kapa, ...
                'lambda', lambda, ...
                'neg_bag', false, ...
                'cut_crowds', true, ...         % flag to decide whether or not to remove crowded scenes
                'cut_threshold', 30, ...        % max size of crowds in bags
                'opt_flag', 'MOSEK_NORM', ...  % kind of optimization performed
                'mosek_license', '/sequoia/data1/bojanows/local/mosek/6/licenses');

if nargin > 4
    params.kothpath = kothpath;
else
    fprintf('No others specified!\n');
end
            
end