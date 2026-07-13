function [selected_element, pool_new] = mysample_wo_replace(pool,weights)
%% input: pool, a N*1 cell array
% output: pool_new, a new pool after sampling without replacement
    N = numel(pool);
    if N < 1
        selected_element = NaN;
        pool_new = [];
        return
    end
    if nargin<2
        weights = ones(N,1);
    end
    threshold = tril(ones(N))*weights/sum(weights);
    rng('shuffle'); %reset seed
    randnum = rand();
    selected = find(threshold>randnum,1);
    selected_element = pool{selected};
    pool(selected) = [];
    pool_new = pool;
end