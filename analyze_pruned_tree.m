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

% ===================== 1. 初始化 =====================
% 创建过滤矩阵的副本，确保不修改原始数据
filtered_adj_mat_copy = filtered_adj_mat;

% 获取骨干树中的所有节点
tree_nodes = unique(cell2mat(pruned_paths));

% 初始化拼接深度信息结构体
spliced_depth_info = struct();
spliced_depth_info.depth0_nodes = [];  % 深度0的节点（源节点）
spliced_depth_info.depth1_nodes = [];  % 深度1的节点
spliced_depth_info.depth2_nodes = [];  % 深度2的节点
spliced_depth_info.depth3_nodes = [];  % 深度3的节点
spliced_depth_info.tree_edges = [];    % 拼接边

% ===================== 2. 计算骨干树节点深度 =====================
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

% ===================== 3. 特殊过滤规则 =====================
% 在副本上操作
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

% ===================== 4. 拼接骨干树（深度为0的骨干树节点拼接） =====================
% 在特殊过滤拓扑上构建拼接骨干树
[spliced_tree_mat, spliced_tree_edges] = build_balanced_tree(filtered_adj_mat_copy, source_node);
[spliced_pruned_mat, spliced_paths] = prune_balanced_tree(spliced_tree_mat, spliced_tree_edges, source_node);

% 获取拼接骨干树中的所有节点
spliced_tree_nodes = unique(cell2mat(spliced_paths));

% 初始化拼接骨干树边
spliced_depth_info.tree_edges = [];

% 从spliced_pruned_mat中提取边
[source_nodes, target_nodes] = find(spliced_pruned_mat > 0);
for i = 1:length(source_nodes)
    edge = [source_nodes(i), target_nodes(i)];
    % 确保边的方向从小节点到大节点
    if edge(1) > edge(2)
        edge = [edge(2), edge(1)];
    end
    spliced_depth_info.tree_edges = [spliced_depth_info.tree_edges; edge];
end

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

% 更新拼接深度信息结构体
% 初始化所有深度节点为空数组
spliced_depth_info.depth0_nodes = [];
spliced_depth_info.depth1_nodes = [];
spliced_depth_info.depth2_nodes = [];
spliced_depth_info.depth3_nodes = [];

% 根据实际深度更新节点信息
for depth = 0:max_spliced_depth
    if depth + 1 <= size(spliced_depth_stats, 1)
        nodes_at_depth = spliced_depth_stats{depth + 1, 1};
        switch depth
            case 0
                spliced_depth_info.depth0_nodes = nodes_at_depth;
            case 1
                spliced_depth_info.depth1_nodes = nodes_at_depth;
            case 2
                spliced_depth_info.depth2_nodes = nodes_at_depth;
            case 3
                spliced_depth_info.depth3_nodes = nodes_at_depth;
        end
    end
end

% ===================== 5. 次级拼接（深度为1的骨干树节点拼接） =====================
% 获取所有骨干树内的深度1节点
depth1_nodes = find(node_depths == 1);
depth1_nodes = intersect(depth1_nodes, tree_nodes);  % 确保是骨干树内的节点

% 调用次级拼接函数
secondary_spliced_info = secondary_splice(filtered_adj_mat_copy, tree_nodes, node_depths, n, spliced_tree_nodes);

% 更新拼接骨干树信息
if ~isempty(secondary_spliced_info.nodes)
    % 将次级拼接得到的深度2节点添加到spliced_depth_info中
    spliced_depth_info.depth2_nodes = unique([spliced_depth_info.depth2_nodes(:); secondary_spliced_info.depth2_nodes(:)]);
    
    % 将次级拼接得到的深度3节点添加到spliced_depth_info中
    for i = 1:length(secondary_spliced_info.trees)
        tree_info = secondary_spliced_info.trees{i};
        spliced_depth_info.depth3_nodes = unique([spliced_depth_info.depth3_nodes(:); tree_info.global_depth_info.depth3_nodes(:)]);
    end
    
    % 更新拼接边信息
    if ~isempty(secondary_spliced_info.edges)
        spliced_depth_info.tree_edges = [spliced_depth_info.tree_edges; secondary_spliced_info.edges];
    end
end

% ===================== 6. 简单拼接（深度为2的骨干树节点拼接） =====================
% 执行简单拼接
simple_spliced_info = simple_splice(filtered_adj_mat_copy, tree_nodes, node_depths, n, spliced_tree_nodes);

% ===================== 7. 数据汇总 =====================
% 创建深度信息结构体
depth_info = struct();
depth_info.depth0_nodes = depth_stats{1, 1};  % 深度0的节点（源节点）
depth_info.depth1_nodes = depth_stats{2, 1};  % 深度1的节点
depth_info.depth2_nodes = depth_stats{3, 1};  % 深度2的节点
depth_info.depth3_nodes = depth_stats{4, 1};  % 深度3的节点

% 更新拼接深度信息结构体
% 注意：不要覆盖之前设置的拼接骨干树节点信息
% spliced_depth_info.depth0_nodes 和 spliced_depth_info.depth1_nodes 已经在前面设置

% 更新节点信息
depth0_nodes = depth_info.depth0_nodes(:);  % 转换为列向量
depth1_nodes = depth_info.depth1_nodes(:);  % 转换为列向量
depth2_nodes = depth_info.depth2_nodes(:);  % 转换为列向量
depth3_nodes = depth_info.depth3_nodes(:);  % 转换为列向量

% 确保所有数组都是列向量后再合并
tree_nodes = unique([depth0_nodes; depth1_nodes; depth2_nodes; depth3_nodes]);

% 将简单拼接的信息添加到spliced_depth_info中
spliced_depth_info.depth2_spliced_info = simple_spliced_info.depth2_spliced_info;

% 确保所有节点数组都是列向量后再合并
depth3_nodes = spliced_depth_info.depth3_nodes(:);
spliced_nodes = simple_spliced_info.depth2_spliced_info.spliced_nodes(:);
spliced_depth_info.all_spliced_nodes = unique([depth3_nodes; spliced_nodes]);

% 更新depth_info中的深度3节点集合，添加所有拼接得到的节点
all_depth3_nodes = unique([depth_info.depth3_nodes(:); simple_spliced_info.all_spliced_nodes(:)]);
depth_info.depth3_nodes = sort(all_depth3_nodes);

% 更新spliced_depth_info中的深度3节点集合
                            all_spliced_depth3_nodes = unique([spliced_depth_info.depth3_nodes(:); spliced_depth_info.all_spliced_nodes(:)]);
spliced_depth_info.depth3_nodes = sort(all_spliced_depth3_nodes);

% ===================== 8. 控制台打印 =====================
% 1. 骨干树信息
fprintf('\n===================== 骨干树信息 =====================\n');
fprintf('骨干树包含的所有节点：\n');
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

% 2. 拼接骨干树信息
fprintf('\n===================== 拼接骨干树信息 =====================\n');
fprintf('拼接骨干树包含的所有节点：\n');
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

% 3. 次级拼接信息
fprintf('\n===================== 次级拼接信息 =====================\n');
if ~isempty(secondary_spliced_info.nodes)
    fprintf('参与次级拼接的深度1节点：\n');
    fprintf('%d ', sort(secondary_spliced_info.nodes));
    fprintf('（共%d个节点）\n', length(secondary_spliced_info.nodes));
    
    % 打印每个深度1节点构建的平衡二叉树信息
    for i = 1:length(secondary_spliced_info.trees)
        tree_info = secondary_spliced_info.trees{i};
        fprintf('\n深度1节点 %d 构建的平衡二叉树:\n', tree_info.source_node);
        fprintf('深度1节点: %s\n', mat2str(tree_info.global_depth_info.depth1_nodes));
        fprintf('深度2节点: %s\n', mat2str(tree_info.global_depth_info.depth2_nodes));
        fprintf('深度3节点: %s\n', mat2str(tree_info.global_depth_info.depth3_nodes));
    end
else
    fprintf('没有可进行次级拼接的深度1节点\n');
end

% 4. 简单拼接信息
fprintf('\n===================== 简单拼接信息 =====================\n');

% 打印能进行拼接的深度2节点
fprintf('深度2节点集合（可进行拼接的节点）：\n');
if ~isempty(simple_spliced_info.nodes)
    fprintf('%d ', sort(simple_spliced_info.nodes));
    fprintf('（共%d个节点）\n', length(simple_spliced_info.nodes));
else
    fprintf('无（共0个节点）\n');
end

% 打印目标拼接点（深度3节点）
fprintf('\n深度3节点集合（目标拼接节点）：\n');
if ~isempty(simple_spliced_info.depth2_spliced_info.spliced_nodes)
    fprintf('%d ', sort(simple_spliced_info.depth2_spliced_info.spliced_nodes));
    fprintf('（共%d个节点）\n', length(simple_spliced_info.depth2_spliced_info.spliced_nodes));
else
    fprintf('无（共0个节点）\n');
end

% 打印具体的拼接路径
fprintf('\n拼接路径（深度2节点 -> 深度3节点）：\n');
if ~isempty(simple_spliced_info.edges)
    for i = 1:size(simple_spliced_info.edges, 1)
        fprintf('深度2节点 %d -> 深度3节点 %d (权重: %.2f)\n', ...
            simple_spliced_info.edges(i,1), ...
            simple_spliced_info.edges(i,2), ...
            simple_spliced_info.weights(i));
    end
else
    fprintf('无拼接路径\n');
end

fprintf('\n===================== 信息打印完成 =====================\n');
end 