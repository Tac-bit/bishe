function [tree_mat, tree_edges] = build_balanced_tree(adj_mat, source_node)
% 构建平衡二叉树
% 输入:
%   adj_mat: 邻接矩阵
%   source_node: 源节点编号
% 输出:
%   tree_mat: 平衡二叉树的邻接矩阵
%   tree_edges: 平衡二叉树的边列表

% 获取节点数量
n = size(adj_mat, 1);

% 初始化平衡二叉树邻接矩阵
tree_mat = zeros(n);

% 初始化访问标记数组
visited = false(1, n);
visited(source_node) = true;

% 初始化队列用于BFS
queue = source_node;
tree_edges = [];

% 构建平衡二叉树
while ~isempty(queue)
    current = queue(1);
    queue(1) = [];
    
    % 获取当前节点的邻居
    neighbors = find(adj_mat(current, :) > 0);
    unvisited_neighbors = neighbors(~visited(neighbors));
    
    % 限制每个节点最多有两个子节点
    if length(unvisited_neighbors) > 2
        % 按权重排序邻居
        [~, idx] = sort(adj_mat(current, unvisited_neighbors), 'descend');
        unvisited_neighbors = unvisited_neighbors(idx(1:2));
    end
    
    % 添加边到平衡二叉树
    for neighbor = unvisited_neighbors
        tree_mat(current, neighbor) = adj_mat(current, neighbor);
        tree_mat(neighbor, current) = adj_mat(neighbor, current);
        tree_edges = [tree_edges; current, neighbor];
        visited(neighbor) = true;
        queue = [queue, neighbor];
    end
end
end 