function [ results, Z ] = weak_square_loss(params, bags, tframes, Kf, Kof, GTf, T)

setenv('MOSEKLM_LICENSE_FILE', params.mosek_license);

% making kernels PSD
if ~isempty(Kof)
    [Kf, Kof] = make_PSD_wo(Kf, Kof);
else
    Kf = make_PSD(Kf);
    Kof = zeros(0,size(Kf, 1));
end

% building the bags - kernel, constraints
[Ka, Y, A_ind, B_ind, others_idx] = build_bags(params, bags, Kf, Kof, GTf, T, tframes);

% solving the minimization problem
% Z = weak_square_loss(params, Ka, Y, A_ind, B_ind);

opt_flag    = params.opt_flag;
alpha       = params.alpha;
kapa        = params.kapa;
lambda      = params.lambda;


% fixing parameters of the minimization program
[n, P]  = size(Y);              % number of tracks / number of classes
nConst  = length(A_ind);  % number of annotations
ep      = ones(P, 1);           % constant vector of ones

    
if strcmp(opt_flag, 'feasibility'); % feasibility USING CVX
    
    A       = build_A(Ka, lambda);
    Ip      = eye(P);
    AI      = kron(Ip, A);
    cvx_begin
    variable Z(n, P);
    variable xi1(nConst);
    
    minimize (kapa * norm(xi1))
    
    for j = 1:nConst
        A_ind{j}' * Z * B_ind{j} >= alpha - xi1(j);
    end
    
    Z * ep == 1;
    Z >= 0;
    cvx_end
    
elseif strcmp(opt_flag, 'MOSEK_NORM') % EQUIVALENT NORM WITH MOSEK (FASTEST)
    
    A = build_norm(Ka, lambda);
    [prob.a, prob.blc, prob.buc] = get_mosek_A(A_ind, B_ind, A, alpha, opt_flag);
    [prob.qosubi, prob.qosubj, prob.qoval] = get_mosek_Q(A, Y, nConst, kapa, opt_flag);
    [prob.blx] = get_mosek_lx(n, P, nConst, opt_flag);
    [~, res] = mosekopt('minimize', prob);
    vecz = res.sol.itr.xx;
    Z = reshape(vecz(1 : (n*P)), n, P);
    
else
    
    error('Invalid OPT_FLAG!');
    
end


% removing others and evaluating
if ~isempty(others_idx)
    idx = setdiff(1:size(Y,1), others_idx);
    results = evaluate(Z(idx, :), Y(idx, :));
    Z = Z(idx,:);
else
    results = evaluate(Z, Y);
end

end