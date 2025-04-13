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

% --------------------- 4.1 拼接骨干树上的简单拼接 ---------------------
% 进行拼接骨干树上的简单拼接 - 类似深度2节点的简单拼接
fprintf('\n--------------------- 拼接骨干树上的简单拼接 ---------------------\n');
spliced_backbone_simple_splice = spliced_simple_splice(filtered_adj_mat_copy, spliced_tree_nodes, spliced_node_depths, n);

% 将拼接骨干树上的简单拼接信息添加到spliced_depth_info
spliced_depth_info.simple_splice_info = spliced_backbone_simple_splice;

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

% ===================== 5.5 检测并处理节点竞争 =====================
% 存储竞争节点信息的结构体
competition_info = struct();
competition_info.nodes = [];           % 存储发生竞争的节点
competition_info.backbone_edges = [];  % 骨干树竞争边
competition_info.secondary_edges = []; % 次级拼接竞争边

% 提取所有拼接骨干树中的深度3节点
backbone_depth3_nodes = [];
if isfield(spliced_depth_info, 'depth3_nodes') && ~isempty(spliced_depth_info.depth3_nodes)
    backbone_depth3_nodes = spliced_depth_info.depth3_nodes(:);
end

% 提取所有次级拼接中的深度3节点
secondary_depth3_nodes = [];
if ~isempty(secondary_spliced_info.trees)
    for i = 1:length(secondary_spliced_info.trees)
        tree_info = secondary_spliced_info.trees{i};
        if isfield(tree_info.global_depth_info, 'depth3_nodes') && ~isempty(tree_info.global_depth_info.depth3_nodes)
            secondary_depth3_nodes = unique([secondary_depth3_nodes(:); tree_info.global_depth_info.depth3_nodes(:)]);
        end
    end
end

% 检测竞争节点 - 同时被骨干树和次级拼接的深度3节点
competition_nodes = intersect(backbone_depth3_nodes, secondary_depth3_nodes);
competition_info.nodes = competition_nodes;

% 如果存在竞争节点，处理竞争
if ~isempty(competition_nodes)
    fprintf('\n===================== 节点竞争检测 =====================\n');
    fprintf('检测到以下节点同时被拼接骨干树和次级拼接所拼接（深度为3）:\n');
    fprintf('%d ', competition_nodes);
    fprintf('\n共%d个竞争节点\n', length(competition_nodes));
    
    % 找出所有与竞争节点相连的拼接骨干树边
    backbone_edges_to_remove = [];
    for i = 1:size(spliced_depth_info.tree_edges, 1)
        edge = spliced_depth_info.tree_edges(i, :);
        if any(ismember(edge, competition_nodes))
            backbone_edges_to_remove = [backbone_edges_to_remove; i];
            competition_info.backbone_edges = [competition_info.backbone_edges; edge];
        end
    end
    
    % 从拼接骨干树中移除这些边
    if ~isempty(backbone_edges_to_remove)
        spliced_depth_info.tree_edges(backbone_edges_to_remove, :) = [];
    end
    
    % 更新拼接骨干树的深度3节点集合，移除竞争节点
    spliced_depth_info.depth3_nodes = setdiff(spliced_depth_info.depth3_nodes, competition_nodes);
    
    % 从拼接骨干树的节点集合中移除竞争节点
    spliced_tree_nodes = setdiff(spliced_tree_nodes, competition_nodes);
    
    % 更新拼接骨干树的节点统计信息
    for depth = 0:max_spliced_depth
        if depth + 1 <= size(spliced_depth_stats, 1)
            % 移除竞争节点
            nodes_at_depth = spliced_depth_stats{depth + 1, 1};
            if depth == 3  % 深度3的节点需要特殊处理
                nodes_at_depth = setdiff(nodes_at_depth, competition_nodes);
                spliced_depth_stats{depth + 1, 1} = nodes_at_depth;
                spliced_depth_stats{depth + 1, 2} = length(nodes_at_depth);
            end
        end
    end
    
    % 存储所有与竞争节点相连的次级拼接边（这些边将保留）
    for i = 1:size(secondary_spliced_info.edges, 1)
        edge = secondary_spliced_info.edges(i, :);
        if any(ismember(edge, competition_nodes))
            competition_info.secondary_edges = [competition_info.secondary_edges; edge];
        end
    end
    
    % 确保竞争节点所有相关数据结构都得到更新
    % 1. 更新次级拼接树中的节点信息
    for i = 1:length(secondary_spliced_info.trees)
        tree_info = secondary_spliced_info.trees{i};
        % 查找并更新每个次级拼接树中的深度3节点
        if isfield(tree_info.global_depth_info, 'depth3_nodes')
            % 检查该树是否包含竞争节点
            common_nodes = intersect(tree_info.global_depth_info.depth3_nodes, competition_nodes);
            if ~isempty(common_nodes)
                % 确保竞争节点保留在该树中
                tree_info.global_depth_info.depth3_nodes = unique([tree_info.global_depth_info.depth3_nodes; common_nodes]);
                secondary_spliced_info.trees{i} = tree_info;
                
                % 确保竞争节点的所有相关边都正确更新
                % 在次级拼接树中找到与竞争节点相连的所有节点和边
                local_tree_mat = tree_info.tree_mat;
                for node = common_nodes'
                    connected_nodes = find(local_tree_mat(node, :) > 0 | local_tree_mat(:, node)' > 0);
                    for conn_node = connected_nodes
                        if conn_node ~= node
                            edge = sort([node, conn_node]); % 排序确保边的一致性
                            % 确保这条边被标记为次级拼接边
                            if ~ismember(edge, competition_info.secondary_edges, 'rows')
                                competition_info.secondary_edges = [competition_info.secondary_edges; edge];
                            end
                        end
                    end
                end
            end
        end
    end
    
    % 2. 整合竞争节点的深度信息
    % 确保竞争节点在最终的深度结构中正确归类为深度3节点，并且属于次级拼接树
    secondary_depth3_nodes = [];
    for i = 1:length(secondary_spliced_info.trees)
        tree_info = secondary_spliced_info.trees{i};
        if isfield(tree_info.global_depth_info, 'depth3_nodes')
            secondary_depth3_nodes = unique([secondary_depth3_nodes; tree_info.global_depth_info.depth3_nodes(:)]);
        end
    end           
    fprintf('\n处理节点竞争：将竞争节点的拼接权让渡给次级拼接\n');
    fprintf('保留了%d条次级拼接的边\n', size(competition_info.secondary_edges, 1));
    % 添加竞争信息到spliced_depth_info结构体
    spliced_depth_info.competition_info = competition_info;
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

% 如果有竞争节点，确保它们被包含在depth_info和spliced_depth_info中的正确位置
if isfield(spliced_depth_info, 'competition_info') && ~isempty(spliced_depth_info.competition_info.nodes)
    competition_nodes = spliced_depth_info.competition_info.nodes;
    
    % 确保竞争节点在depth_info的深度3节点中
    all_depth3_nodes = unique([all_depth3_nodes; competition_nodes(:)]);
    
    % 确保竞争节点被正确分类（从骨干树移除，保留在次级拼接中）
    spliced_depth_info.depth3_nodes = setdiff(spliced_depth_info.depth3_nodes, competition_nodes);
    
    % 更新次级拼接信息，确保竞争节点保留在次级拼接中并且所有引用都一致
    if ~isempty(secondary_spliced_info.trees)
        secondary_depth3_nodes = [];
        for i = 1:length(secondary_spliced_info.trees)
            tree_info = secondary_spliced_info.trees{i};
            % 检查该树是否包含竞争节点
            common_nodes = intersect(tree_info.global_depth_info.depth3_nodes, competition_nodes);
            if ~isempty(common_nodes)
                % 确保竞争节点保留在该树中
                tree_info.global_depth_info.depth3_nodes = unique([tree_info.global_depth_info.depth3_nodes; common_nodes]);
                secondary_spliced_info.trees{i} = tree_info;
                
                % 更新次级拼接树的全局深度信息
                if ~isfield(secondary_spliced_info, 'depth3_nodes')
                    secondary_spliced_info.depth3_nodes = [];
                end
                secondary_spliced_info.depth3_nodes = unique([secondary_spliced_info.depth3_nodes; common_nodes]);
            end
            secondary_depth3_nodes = unique([secondary_depth3_nodes; tree_info.global_depth_info.depth3_nodes(:)]);
        end
    end
    
    % 更新simple_spliced_info中的深度3节点
    % 确保竞争节点不在简单拼接中，如果它们已归属于次级拼接
    if isfield(simple_spliced_info, 'depth3_nodes')
        simple_spliced_info.depth3_nodes = setdiff(simple_spliced_info.depth3_nodes, competition_nodes);
    end
    if isfield(simple_spliced_info, 'all_spliced_nodes')
        simple_spliced_info.all_spliced_nodes = setdiff(simple_spliced_info.all_spliced_nodes, competition_nodes);
    end
end

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

% 5. 数值量化部分 - 汇总率统计
fprintf('\n===================== 汇聚率统计 =====================\n');

% 计算已汇总的所有节点（骨干树、拼接部分的所有节点求并集）
summarized_nodes = tree_nodes(:); % 确保是列向量

% 添加拼接骨干树节点
summarized_nodes = unique([summarized_nodes; spliced_tree_nodes(:)]);

% 添加次级拼接的节点
if ~isempty(secondary_spliced_info.nodes)
    for i = 1:length(secondary_spliced_info.trees)
        tree_info = secondary_spliced_info.trees{i};
        if isfield(tree_info.global_depth_info, 'depth1_nodes')
            summarized_nodes = unique([summarized_nodes; tree_info.global_depth_info.depth1_nodes(:)]);
        end
        if isfield(tree_info.global_depth_info, 'depth2_nodes')
            summarized_nodes = unique([summarized_nodes; tree_info.global_depth_info.depth2_nodes(:)]);
        end
        if isfield(tree_info.global_depth_info, 'depth3_nodes')
            summarized_nodes = unique([summarized_nodes; tree_info.global_depth_info.depth3_nodes(:)]);
        end
    end
end

% 添加简单拼接得到的节点
if isfield(simple_spliced_info, 'all_spliced_nodes') && ~isempty(simple_spliced_info.all_spliced_nodes)
    summarized_nodes = unique([summarized_nodes; simple_spliced_info.all_spliced_nodes(:)]);
end

% 添加拼接骨干树上的简单拼接得到的节点
if isfield(spliced_depth_info, 'simple_splice_info') 
    % 检查深度2拼接节点
    if isfield(spliced_depth_info.simple_splice_info, 'depth2_spliced_info') && isfield(spliced_depth_info.simple_splice_info.depth2_spliced_info, 'spliced_nodes')
        summarized_nodes = unique([summarized_nodes; spliced_depth_info.simple_splice_info.depth2_spliced_info.spliced_nodes(:)]);
    end
    
    % 检查拼接源节点
    if isfield(spliced_depth_info.simple_splice_info, 'nodes')
        summarized_nodes = unique([summarized_nodes; spliced_depth_info.simple_splice_info.nodes(:)]);
    end
    
    % 检查all_spliced_nodes字段
    if isfield(spliced_depth_info.simple_splice_info, 'all_spliced_nodes')
        summarized_nodes = unique([summarized_nodes; spliced_depth_info.simple_splice_info.all_spliced_nodes(:)]);
    end
end

% 确保添加spliced_depth_info中的all_spliced_nodes节点
if isfield(spliced_depth_info, 'all_spliced_nodes') && ~isempty(spliced_depth_info.all_spliced_nodes)
    summarized_nodes = unique([summarized_nodes; spliced_depth_info.all_spliced_nodes(:)]);
end

% 尝试添加额外的spliced_depth_info子结构中的节点
if isfield(spliced_depth_info, 'depth2_spliced_info') && isfield(spliced_depth_info.depth2_spliced_info, 'spliced_nodes')
    summarized_nodes = unique([summarized_nodes; spliced_depth_info.depth2_spliced_info.spliced_nodes(:)]);
end

% 排序获得的节点集合
summarized_nodes = sort(summarized_nodes);

% 计算潜在可汇聚的节点（初始过滤后的拓扑上与源节点连通的节点）
potential_nodes = [];
filtered_adj_mat_graph = graph(filtered_adj_mat ~= 0);

% 使用连通分量查找与源节点连通的所有节点
comp = conncomp(filtered_adj_mat_graph);
source_comp = comp(source_node);
potential_nodes = find(comp == source_comp)';

% 排序获得的节点集合
potential_nodes = sort(potential_nodes(:)); % 确保是列向量

% 计算汇聚率
convergence_rate = length(summarized_nodes) / length(potential_nodes) * 100;

% 打印统计信息
fprintf('潜在汇聚节点集合：\n');
fprintf('%d ', potential_nodes);
fprintf('\n潜在汇聚节点数量：%d\n', length(potential_nodes));

fprintf('\n已汇总节点集合：\n');
fprintf('%d ', summarized_nodes);
fprintf('\n已汇总节点数量：%d\n', length(summarized_nodes));

% 打印各部分贡献的节点数量
fprintf('\n各部分贡献的节点数量：\n');
fprintf('骨干树节点数量：%d\n', length(tree_nodes));
fprintf('拼接骨干树节点数量：%d\n', length(spliced_tree_nodes));

% 次级拼接节点数量
secondary_nodes_count = 0;
if ~isempty(secondary_spliced_info.nodes)
    for i = 1:length(secondary_spliced_info.trees)
        tree_info = secondary_spliced_info.trees{i};
        if isfield(tree_info.global_depth_info, 'depth1_nodes')
            secondary_nodes_count = secondary_nodes_count + length(tree_info.global_depth_info.depth1_nodes);
        end
        if isfield(tree_info.global_depth_info, 'depth2_nodes')
            secondary_nodes_count = secondary_nodes_count + length(tree_info.global_depth_info.depth2_nodes);
        end
        if isfield(tree_info.global_depth_info, 'depth3_nodes')
            secondary_nodes_count = secondary_nodes_count + length(tree_info.global_depth_info.depth3_nodes);
        end
    end
end
fprintf('次级拼接节点数量：%d\n', secondary_nodes_count);

% 简单拼接节点数量
simple_splice_count = 0;
if isfield(simple_spliced_info, 'all_spliced_nodes') && ~isempty(simple_spliced_info.all_spliced_nodes)
    simple_splice_count = length(simple_spliced_info.all_spliced_nodes);
end
fprintf('简单拼接节点数量：%d\n', simple_splice_count);

% 拼接骨干树上的简单拼接节点数量
spliced_simple_count = 0;
if isfield(spliced_depth_info, 'simple_splice_info') 
    % 检查深度2拼接节点
    if isfield(spliced_depth_info.simple_splice_info, 'depth2_spliced_info') && isfield(spliced_depth_info.simple_splice_info.depth2_spliced_info, 'spliced_nodes')
        spliced_simple_count = spliced_simple_count + length(spliced_depth_info.simple_splice_info.depth2_spliced_info.spliced_nodes);
    end
    
    % 检查拼接源节点
    if isfield(spliced_depth_info.simple_splice_info, 'nodes')
        spliced_simple_count = spliced_simple_count + length(spliced_depth_info.simple_splice_info.nodes);
    end
    
    % 检查all_spliced_nodes字段
    if isfield(spliced_depth_info.simple_splice_info, 'all_spliced_nodes')
        spliced_simple_count = spliced_simple_count + length(spliced_depth_info.simple_splice_info.all_spliced_nodes);
    end
end
fprintf('拼接骨干树上的简单拼接节点数量：%d\n', spliced_simple_count);

% 打印拼接深度信息中的节点统计
if isfield(spliced_depth_info, 'all_spliced_nodes') 
    fprintf('拼接深度信息中的all_spliced_nodes节点数量：%d\n', length(spliced_depth_info.all_spliced_nodes));
end

fprintf('\n汇聚率：%.2f%% (%d/%d)\n', convergence_rate, length(summarized_nodes), length(potential_nodes));

fprintf('\n===================== 信息打印完成 =====================\n');
end 