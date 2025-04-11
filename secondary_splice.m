function secondary_spliced_info = secondary_splice(filtered_adj_mat_copy, tree_nodes, node_depths, n, spliced_tree_nodes)
% 次级拼接功能 - 处理深度1节点的拼接
% 输入:
%   filtered_adj_mat_copy: 特殊过滤后的邻接矩阵
%   tree_nodes: 骨干树节点集合
%   node_depths: 节点深度信息
%   n: 节点总数
%   spliced_tree_nodes: 拼接骨干树节点集合
% 输出:
%   secondary_spliced_info: 次级拼接的信息结构体
%       secondary_spliced_info.nodes: 参与次级拼接的深度1节点
%       secondary_spliced_info.edges: 次级拼接的边
%       secondary_spliced_info.weights: 次级拼接边的权重
%       secondary_spliced_info.depth2_nodes: 拼接得到的深度2节点
%       secondary_spliced_info.trees: 每个深度1节点构建的平衡二叉树信息

% 初始化输出结构体
secondary_spliced_info = struct();
secondary_spliced_info.nodes = [];
secondary_spliced_info.edges = [];
secondary_spliced_info.weights = [];
secondary_spliced_info.depth2_nodes = [];
secondary_spliced_info.trees = {};

% 获取所有深度1节点
depth1_nodes = find(node_depths == 1);

% 遍历每个深度1节点
for i = 1:length(depth1_nodes)
    source_node = depth1_nodes(i);
    
    % 检查节点是否连通（度不为0）
    if sum(filtered_adj_mat_copy(source_node, :) > 0) == 0
        continue;  % 跳过不连通的节点
    end
    
    % 检查节点是否已被拼接
    if ismember(source_node, spliced_tree_nodes)
        continue;  % 跳过已被拼接的节点
    end
    
    % 构建平衡二叉树
    [tree_mat, tree_edges] = build_balanced_tree(filtered_adj_mat_copy, source_node);
    
    % 修剪平衡二叉树，只保留前3个节点
    [pruned_tree_mat, pruned_paths] = prune_balanced_tree_secondary(tree_mat, tree_edges, source_node);
    
    % 获取修剪后树中的所有节点
    tree_nodes = unique(cell2mat(pruned_paths));
    
    % 使用BFS计算节点深度（相对于当前树的深度）
    tree_node_depths = -ones(n, 1);
    tree_node_depths(source_node) = 0;
    
    % 初始化BFS队列
    queue = source_node;
    visited = false(n, 1);
    visited(source_node) = true;
    
    % BFS遍历
    while ~isempty(queue)
        current = queue(1);
        queue(1) = [];
        
        % 获取当前节点的邻居
        neighbors = find(pruned_tree_mat(current, :) > 0);
        
        for neighbor = neighbors
            if ~visited(neighbor)
                visited(neighbor) = true;
                tree_node_depths(neighbor) = tree_node_depths(current) + 1;
                queue = [queue, neighbor];
            end
        end
    end
    
    % 统计每个深度的节点（相对于当前树的深度）
    max_depth = max(tree_node_depths(tree_nodes));
    depth_stats = cell(max_depth + 1, 2);
    for depth = 0:max_depth
        nodes_at_depth = tree_nodes(tree_node_depths(tree_nodes) == depth);
        depth_stats{depth + 1, 1} = nodes_at_depth;
        depth_stats{depth + 1, 2} = length(nodes_at_depth);
    end
    
    % 创建深度信息结构体（相对于当前树的深度）
    depth_info = struct();
    depth_info.depth0_nodes = depth_stats{1, 1};  % 深度0的节点（源节点）
    depth_info.depth1_nodes = depth_stats{2, 1};  % 深度1的节点
    depth_info.depth2_nodes = depth_stats{3, 1};  % 深度2的节点
    
    % 创建综合深度信息结构体（相对于整个树的深度）
    global_depth_info = struct();
    global_depth_info.depth1_nodes = depth_info.depth0_nodes;  % 当前树的深度0节点在综合树中为深度1
    global_depth_info.depth2_nodes = depth_info.depth1_nodes;  % 当前树的深度1节点在综合树中为深度2
    global_depth_info.depth3_nodes = depth_info.depth2_nodes;  % 当前树的深度2节点在综合树中为深度3
    
    % 存储当前树的信息
    tree_info = struct();
    tree_info.source_node = source_node;
    tree_info.tree_mat = pruned_tree_mat;
    tree_info.tree_edges = pruned_paths;
    tree_info.depth_info = depth_info;          % 相对于当前树的深度
    tree_info.global_depth_info = global_depth_info;  % 相对于综合树的深度
    
    % 添加到trees数组中
    secondary_spliced_info.trees{end+1} = tree_info;
    
    % 更新拼接信息
    secondary_spliced_info.nodes = [secondary_spliced_info.nodes; source_node];
    
    % 获取所有边
    for j = 1:length(pruned_paths)
        path = pruned_paths{j};
        for k = 1:length(path)-1
            edge = [path(k), path(k+1)];
            weight = filtered_adj_mat_copy(edge(1), edge(2));
            
            % 检查边是否已存在
            if ~ismember(edge, secondary_spliced_info.edges, 'rows')
                secondary_spliced_info.edges = [secondary_spliced_info.edges; edge];
                secondary_spliced_info.weights = [secondary_spliced_info.weights; weight];
            end
        end
    end
    
    % 更新深度2节点（使用综合深度）
    secondary_spliced_info.depth2_nodes = unique([secondary_spliced_info.depth2_nodes; global_depth_info.depth2_nodes(:)]);
end

% 确保所有节点数组都是列向量
secondary_spliced_info.nodes = secondary_spliced_info.nodes(:);
secondary_spliced_info.depth2_nodes = secondary_spliced_info.depth2_nodes(:);
end

function [pruned_tree_mat, pruned_paths] = prune_balanced_tree_secondary(tree_mat, tree_edges, source_node)
% 修剪平衡二叉树（次级拼接版本）
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
    
    % 只保留前3个节点
    if length(current_path) > 3
        current_path = current_path(1:3);
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