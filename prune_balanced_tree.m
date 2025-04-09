function [pruned_tree_mat, pruned_paths] = prune_balanced_tree(tree_mat, tree_edges, source_node)
% 修剪平衡二叉树
% 输入:
%   tree_mat: 平衡二叉树的邻接矩阵
%   tree_edges: 平衡二叉树的边列表
%   source_node: 源节点编号
% 输出:
%   pruned_tree_mat: 修剪后的平衡二叉树邻接矩阵
%   pruned_paths: 修剪后的路径集合

% 获取节点数量
n = size(tree_mat, 1);

% 初始化修剪后的邻接矩阵
pruned_tree_mat = zeros(n);

% 找到所有度为1的节点（叶子节点）
degrees = sum(tree_mat > 0, 2);
leaf_nodes = find(degrees == 1 & (1:n)' ~= source_node);

% 存储所有修剪后的路径
pruned_paths = {};

% 对每个叶子节点进行路径修剪
for leaf = leaf_nodes'
    % 初始化当前路径
    current_path = [];
    current_node = leaf;
    
    % 回溯到源节点
    while current_node ~= source_node
        current_path = [current_node, current_path];
        % 使用tree_edges找到父节点
        parent_edges = tree_edges(tree_edges(:,2) == current_node, 1);
        if isempty(parent_edges)
            parent_edges = tree_edges(tree_edges(:,1) == current_node, 2);
        end
        current_node = parent_edges(1);
    end
    current_path = [source_node, current_path];
    
    % 只保留前4个节点
    if length(current_path) > 4
        current_path = current_path(1:4);
    end
    
    % 存储路径
    pruned_paths{end+1} = current_path;
    
    % 在修剪后的邻接矩阵中添加边
    for i = 1:length(current_path)-1
        pruned_tree_mat(current_path(i), current_path(i+1)) = tree_mat(current_path(i), current_path(i+1));
        pruned_tree_mat(current_path(i+1), current_path(i)) = tree_mat(current_path(i+1), current_path(i));
    end
end
end 