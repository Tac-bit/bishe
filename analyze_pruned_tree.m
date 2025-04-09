function [filtered_adj_mat_copy, tree_nodes, depth_stats, depth_info, spliced_depth_info, simple_spliced_info] = analyze_pruned_tree(pruned_tree_mat, pruned_paths, source_node, filtered_adj_mat)
% 特殊过滤规则
% 输入:
%   pruned_tree_mat: 修剪后的骨干树邻接矩阵
%   pruned_paths: 修剪后的路径集合
%   source_node: 源节点编号
%   filtered_adj_mat: Metro_filter过滤后的邻接矩阵
% 输出:
%   filtered_adj_mat_copy: 特殊过滤后的邻接矩阵（原始矩阵的副本）
%   tree_nodes: 骨干树包含的所有节点
%   depth_stats: 各深度层级的节点统计信息
%   depth_info: 包含不同深度节点的结构体
%   spliced_depth_info: 拼接骨干树的深度节点信息结构体
%   simple_spliced_info: 简单拼接的信息结构体

% 创建过滤矩阵的副本，确保不修改原始数据
filtered_adj_mat_copy = filtered_adj_mat;

% 获取骨干树中的所有节点
tree_nodes = unique(cell2mat(pruned_paths));

% 使用BFS计算节点深度
n = size(pruned_tree_mat, 1);
node_depths = -ones(n, 1);  % 初始化所有节点深度为-1
node_depths(source_node) = 0;  % 源节点深度为0

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
            node_depths(neighbor) = node_depths(current) + 1;
            queue = [queue, neighbor];
        end
    end
end

% 统计每个深度的节点
max_depth = max(node_depths(tree_nodes));
depth_stats = cell(max_depth + 1, 2);  % 第一列存储节点，第二列存储数量
for depth = 0:max_depth
    nodes_at_depth = tree_nodes(node_depths(tree_nodes) == depth);
    depth_stats{depth + 1, 1} = nodes_at_depth;
    depth_stats{depth + 1, 2} = length(nodes_at_depth);
end

% 特殊过滤规则 - 在副本上操作
% 1. 过滤所有修剪骨干树节点之间的边（不管是不是骨干树边）
for i = 1:n
    for j = i+1:n
        if filtered_adj_mat_copy(i,j) > 0
            % 如果边的两个端点都是骨干树节点，则过滤
            if ismember(i, tree_nodes) && ismember(j, tree_nodes)
                filtered_adj_mat_copy(i,j) = 0;
                filtered_adj_mat_copy(j,i) = 0;
            end
            % 检查是否有一端是深度为3的骨干树节点
            if (ismember(i, tree_nodes) && node_depths(i) == 3) || ...
               (ismember(j, tree_nodes) && node_depths(j) == 3)
                filtered_adj_mat_copy(i,j) = 0;
                filtered_adj_mat_copy(j,i) = 0;
            end
        end
    end
end

% 打印骨干树节点统计信息
fprintf('\n骨干树包含的所有节点：\n');
fprintf('%d ', tree_nodes);
fprintf('\n节点总数：%d\n', length(tree_nodes));

fprintf('\n各深度层级的节点统计：\n');
for depth = 0:size(depth_stats, 1)-1
    nodes_at_depth = depth_stats{depth + 1, 1};
    node_count = depth_stats{depth + 1, 2};
    fprintf('深度 %d: ', depth);
    if ~isempty(nodes_at_depth)
        fprintf('%d ', nodes_at_depth);
        fprintf('(共%d个节点)\n', node_count);
    else
        fprintf('无节点\n');
    end
end

% 创建深度信息结构体
depth_info = struct();
depth_info.depth0_nodes = depth_stats{1, 1};  % 深度0的节点
depth_info.depth1_nodes = depth_stats{2, 1};  % 深度1的节点
depth_info.depth2_nodes = depth_stats{3, 1};  % 深度2的节点
depth_info.depth3_nodes = depth_stats{4, 1};  % 深度3的节点

% 在特殊过滤拓扑上构建拼接骨干树
[spliced_tree_mat, spliced_tree_edges] = build_balanced_tree(filtered_adj_mat_copy, source_node);
[spliced_pruned_mat, spliced_paths] = prune_balanced_tree(spliced_tree_mat, spliced_tree_edges, source_node);

% 获取拼接骨干树中的所有节点
spliced_tree_nodes = unique(cell2mat(spliced_paths));

% 使用BFS计算拼接骨干树节点深度
spliced_node_depths = -ones(n, 1);  % 初始化所有节点深度为-1
spliced_node_depths(source_node) = 0;  % 源节点深度为0

% 初始化BFS队列
queue = source_node;
visited = false(n, 1);
visited(source_node) = true;

% BFS遍历拼接骨干树
while ~isempty(queue)
    current = queue(1);
    queue(1) = [];
    
    % 获取当前节点的邻居
    neighbors = find(spliced_pruned_mat(current, :) > 0);
    
    for neighbor = neighbors
        if ~visited(neighbor)
            visited(neighbor) = true;
            spliced_node_depths(neighbor) = spliced_node_depths(current) + 1;
            queue = [queue, neighbor];
        end
    end
end

% 统计拼接骨干树每个深度的节点
max_spliced_depth = max(spliced_node_depths(spliced_tree_nodes));
spliced_depth_stats = cell(max_spliced_depth + 1, 2);
for depth = 0:max_spliced_depth
    nodes_at_depth = spliced_tree_nodes(spliced_node_depths(spliced_tree_nodes) == depth);
    spliced_depth_stats{depth + 1, 1} = nodes_at_depth;
    spliced_depth_stats{depth + 1, 2} = length(nodes_at_depth);
end

% 创建拼接骨干树深度信息结构体
spliced_depth_info = struct();
spliced_depth_info.depth0_nodes = spliced_depth_stats{1, 1};  % 深度0的节点
spliced_depth_info.depth1_nodes = spliced_depth_stats{2, 1};  % 深度1的节点
spliced_depth_info.depth2_nodes = spliced_depth_stats{3, 1};  % 深度2的节点
spliced_depth_info.depth3_nodes = spliced_depth_stats{4, 1};  % 深度3的节点
spliced_depth_info.tree_edges = spliced_tree_edges;  % 存储拼接骨干树的边信息

% 对拼接树中深度为2的节点进行拼接处理
spliced_depth2_nodes = [];
for node = 1:n
    if ismember(node, spliced_tree_nodes) && spliced_node_depths(node) == 2
        % 计算在特殊过滤后邻接矩阵中的度
        degree = sum(filtered_adj_mat_copy(node, :) > 0);
        if degree > 0
            % 存储节点编号和度
            spliced_depth2_nodes = [spliced_depth2_nodes; node, degree];
        end
    end
end

% 对spliced_depth2_nodes按度排序（从小到大），如果度相同则按节点编号排序
if ~isempty(spliced_depth2_nodes)
    spliced_depth2_nodes = sortrows(spliced_depth2_nodes, [2 1]);
end

% 创建用于记录每个邻居节点已被连接的深度为2的节点
spliced_neighbor_connected = cell(n, 1);
for i = 1:n
    spliced_neighbor_connected{i} = [];
end

% 用于记录最终拼接边
spliced_depth2_source_points = [];
spliced_depth2_target_points = [];
spliced_depth2_edge_weights = [];
spliced_depth2_spliced_nodes = [];  % 存储拼接的节点

% 遍历深度为2的节点（按度和节点编号排序后）
for i = 1:size(spliced_depth2_nodes, 1)
    node = spliced_depth2_nodes(i, 1);
    % 获取邻居节点 - 使用特殊过滤后的邻接矩阵
    neighbors = find(filtered_adj_mat_copy(node, :) > 0);
    if ~isempty(neighbors)
        % 遍历邻居节点
        for j = 1:length(neighbors)
            neighbor = neighbors(j);
            % 检查该邻居是否已被其他深度为2的节点连接，且不属于拼接树节点
            if ~ismember(node, spliced_neighbor_connected{neighbor}) && ~ismember(neighbor, spliced_tree_nodes)
                % 记录连接
                spliced_neighbor_connected{neighbor} = [spliced_neighbor_connected{neighbor}, node];
                % 添加拼接边
                spliced_depth2_source_points = [spliced_depth2_source_points, node];
                spliced_depth2_target_points = [spliced_depth2_target_points, neighbor];
                spliced_depth2_edge_weights = [spliced_depth2_edge_weights, filtered_adj_mat_copy(node, neighbor)];
                % 将邻居节点添加到拼接节点集合
                if ~ismember(neighbor, spliced_depth2_spliced_nodes)
                    spliced_depth2_spliced_nodes = [spliced_depth2_spliced_nodes, neighbor];
                end
            end
        end
    end
end

% 将深度2节点的拼接信息存储到结构体中
spliced_depth2_info = struct('nodes', spliced_depth2_nodes(:, 1), ...
                           'edges', [spliced_depth2_source_points', spliced_depth2_target_points'], ...
                           'weights', spliced_depth2_edge_weights', ...
                           'spliced_nodes', sort(spliced_depth2_spliced_nodes(:)));  % 确保是列向量

% 打印拼接树中深度2节点拼接得到的节点信息
fprintf('\n拼接树-深度2节点拼接：');
if ~isempty(spliced_depth2_spliced_nodes)
    fprintf('%d ', sort(spliced_depth2_spliced_nodes));  % 打印时也使用排序后的节点
    fprintf('（共%d个节点）\n', length(spliced_depth2_spliced_nodes));
else
    fprintf('无（共0个节点）\n');
end

% 将拼接树深度2节点的拼接信息添加到spliced_depth_info中
spliced_depth_info.depth2_spliced_info = spliced_depth2_info;
% 确保所有节点数组都是列向量后再合并
depth3_nodes = spliced_depth_info.depth3_nodes(:);
spliced_nodes = spliced_depth2_info.spliced_nodes(:);
spliced_depth_info.all_spliced_nodes = unique([depth3_nodes; spliced_nodes]);

% 打印拼接骨干树节点统计信息
fprintf('\n拼接骨干树包含的所有节点：\n');
fprintf('%d ', spliced_tree_nodes);
fprintf('\n节点总数：%d\n', length(spliced_tree_nodes));

fprintf('\n拼接骨干树各深度层级的节点统计：\n');
for depth = 0:size(spliced_depth_stats, 1)-1
    nodes_at_depth = spliced_depth_stats{depth + 1, 1};
    node_count = spliced_depth_stats{depth + 1, 2};
    fprintf('拼接-深度 %d: ', depth);
    if ~isempty(nodes_at_depth)
        fprintf('%d ', nodes_at_depth);
        fprintf('(共%d个节点)\n', node_count);
    else
        fprintf('无节点\n');
    end
end

% 执行简单拼接
simple_spliced_info = simple_splice(filtered_adj_mat_copy, tree_nodes, node_depths, n, spliced_tree_nodes);

% 对深度为2的节点进行拼接处理
depth2_nodes = [];
for node = 1:n
    if ismember(node, tree_nodes) && node_depths(node) == 2
        % 计算在特殊过滤后邻接矩阵中的度
        degree = sum(filtered_adj_mat_copy(node, :) > 0);
        if degree > 0
            % 存储节点编号和度
            depth2_nodes = [depth2_nodes; node, degree];
        end
    end
end

% 对depth2_nodes按度排序（从小到大），如果度相同则按节点编号排序
if ~isempty(depth2_nodes)
    depth2_nodes = sortrows(depth2_nodes, [2 1]);
end

% 创建用于记录每个邻居节点已被连接的深度为2的节点
neighbor_connected = cell(n, 1);
for i = 1:n
    neighbor_connected{i} = [];
end

% 用于记录最终拼接边
depth2_source_points = [];
depth2_target_points = [];
depth2_edge_weights = [];
depth2_spliced_nodes = [];  % 存储拼接的节点

% 遍历深度为2的节点（按度和节点编号排序后）
for i = 1:size(depth2_nodes, 1)
    node = depth2_nodes(i, 1);
    % 获取邻居节点 - 使用特殊过滤后的邻接矩阵
    neighbors = find(filtered_adj_mat_copy(node, :) > 0);
    if ~isempty(neighbors)
        % 遍历邻居节点
        for j = 1:length(neighbors)
            neighbor = neighbors(j);
            % 检查该邻居是否已被其他深度为2的节点连接，且不属于骨干树节点
            if ~ismember(node, neighbor_connected{neighbor}) && ~ismember(neighbor, tree_nodes)
                % 记录连接
                neighbor_connected{neighbor} = [neighbor_connected{neighbor}, node];
                % 添加拼接边
                depth2_source_points = [depth2_source_points, node];
                depth2_target_points = [depth2_target_points, neighbor];
                depth2_edge_weights = [depth2_edge_weights, filtered_adj_mat_copy(node, neighbor)];
                % 将邻居节点添加到拼接节点集合，并标记为深度3节点
                if ~ismember(neighbor, depth2_spliced_nodes)
                    depth2_spliced_nodes = [depth2_spliced_nodes, neighbor];
                    % 将拼接得到的节点标记为深度3
                    node_depths(neighbor) = 3;
                end
            end
        end
    end
end

% 将深度2节点的拼接信息存储到结构体中
depth2_spliced_info = struct('nodes', depth2_nodes(:, 1), ...
                           'edges', [depth2_source_points', depth2_target_points'], ...
                           'weights', depth2_edge_weights', ...
                           'spliced_nodes', sort(depth2_spliced_nodes(:)), ...  % 确保是列向量
                           'depth3_nodes', sort(depth2_spliced_nodes(:)));  % 添加深度3节点信息

% 打印深度2节点拼接得到的节点信息
fprintf('\n深度2节点拼接：');
if ~isempty(depth2_spliced_nodes)
    fprintf('%d ', sort(depth2_spliced_nodes));  % 打印时也使用排序后的节点
    fprintf('（共%d个节点）\n', length(depth2_spliced_nodes));
else
    fprintf('无（共0个节点）\n');
end

% 合并简单拼接和深度2节点拼接的信息
simple_spliced_info.depth2_spliced_info = depth2_spliced_info;
% 确保所有节点数组都是列向量后再合并
depth3_nodes = simple_spliced_info.depth3_nodes(:);
spliced_nodes = depth2_spliced_info.spliced_nodes(:);
simple_spliced_info.all_spliced_nodes = unique([depth3_nodes; spliced_nodes]);

% 更新depth_info中的深度3节点集合，添加所有拼接得到的节点
all_depth3_nodes = unique([depth_info.depth3_nodes(:); simple_spliced_info.all_spliced_nodes(:)]);
depth_info.depth3_nodes = sort(all_depth3_nodes);

% 更新spliced_depth_info中的深度3节点集合
all_spliced_depth3_nodes = unique([spliced_depth_info.depth3_nodes(:); spliced_depth_info.all_spliced_nodes(:)]);
spliced_depth_info.depth3_nodes = sort(all_spliced_depth3_nodes);

end 