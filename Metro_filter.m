function [filtered_adj_mat, mean_weight, std_weight] = Metro_filter(adj_mat, threshold, source_node)
% 过滤带宽小于门限的边并可视化
% 输入:
%   adj_mat: 原始邻接矩阵
%   threshold: 带宽门限值（建议范围：10-100）
%   source_node: 源节点编号（默认为18）
% 输出:
%   filtered_adj_mat: 过滤后的邻接矩阵
%   mean_weight: 过滤后的边权值平均值
%   std_weight: 过滤后的边权值标准差

% 设置默认参数
if nargin < 3
    source_node = 18;
end

% 创建新的邻接矩阵
filtered_adj_mat = adj_mat;

% 将小于门限的边权重设为0
filtered_adj_mat(filtered_adj_mat < threshold ) = 0;

% 计算过滤后的边权值统计信息
[row, col, weights] = find(filtered_adj_mat);
if ~isempty(weights)
    mean_weight = mean(weights);
    std_weight = std(weights);
else
    mean_weight = 0;
    std_weight = 0;
end

% 返回过滤后的邻接矩阵
end 