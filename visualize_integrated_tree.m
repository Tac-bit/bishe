function visualize_integrated_tree(filtered_adj_mat, tree_nodes, depth_info, spliced_depth_info, simple_spliced_info, secondary_spliced_info, source_node, pruned_paths, node_times)
% 可视化综合树结构，包括节点序号和边权值信息
% 输入:
%   filtered_adj_mat: 过滤后的邻接矩阵
%   tree_nodes: 骨干树包含的所有节点
%   depth_info: 包含不同深度节点的结构体 (从analyze_pruned_tree获取)
%   spliced_depth_info: 拼接骨干树的深度节点信息结构体 (从analyze_pruned_tree获取)
%   simple_spliced_info: 简单拼接的信息结构体 (从analyze_pruned_tree获取)
%   secondary_spliced_info: 次级拼接的信息结构体 (从analyze_pruned_tree获取)
%   source_node: 源节点编号
%   pruned_paths: 修剪后的路径集合 (从prune_balanced_tree直接获取)
%   node_times: 每个节点的数据汇聚时间 (可选参数)

% 处理可选参数
if ~exist('node_times', 'var') || isempty(node_times)
    node_times = [];
    show_times = false;
else
    show_times = true;
end

% ===================== 1. 收集综合树信息 (与print_tree_summary相同的方法) =====================
% 确保tree_nodes是列向量
if size(tree_nodes, 1) == 1
    tree_nodes = tree_nodes';
end

% 收集所有节点和边信息
% 1. 从骨干树获取节点和边
backbone_nodes = [];
backbone_edges = [];

% 从pruned_paths中提取骨干树节点和边
if exist('pruned_paths', 'var') && ~isempty(pruned_paths)
    for i = 1:length(pruned_paths)
        path = pruned_paths{i};
        backbone_nodes = [backbone_nodes, path];
        
        % 提取路径中的边
        for j = 1:length(path)-1
            edge = sort([path(j), path(j+1)]);
            edge = reshape(edge, 1, 2);
            
            % 检查是否已经存在
            is_new_edge = true;
            if ~isempty(backbone_edges)
                for k = 1:size(backbone_edges, 1)
                    if all(backbone_edges(k,:) == edge)
                        is_new_edge = false;
                        break;
                    end
                end
            end
            
            if is_new_edge
                backbone_edges = [backbone_edges; edge];
            end
        end
    end
    backbone_nodes = unique(backbone_nodes)';
else
    backbone_nodes = tree_nodes;
end

% 2. 从拼接骨干树获取节点和边
spliced_nodes = [];
if isfield(spliced_depth_info, 'depth0_nodes')
    spliced_nodes = [spliced_nodes; spliced_depth_info.depth0_nodes(:)];
end
if isfield(spliced_depth_info, 'depth1_nodes')
    spliced_nodes = [spliced_nodes; spliced_depth_info.depth1_nodes(:)];
end
if isfield(spliced_depth_info, 'depth2_nodes')
    spliced_nodes = [spliced_nodes; spliced_depth_info.depth2_nodes(:)];
end
if isfield(spliced_depth_info, 'depth3_nodes')
    spliced_nodes = [spliced_nodes; spliced_depth_info.depth3_nodes(:)];
end
spliced_nodes = unique(spliced_nodes);

spliced_edges = [];
if isfield(spliced_depth_info, 'tree_edges') && ~isempty(spliced_depth_info.tree_edges)
    % 提取和整理边信息
    for i = 1:size(spliced_depth_info.tree_edges, 1)
        edge = spliced_depth_info.tree_edges(i, :);
        if length(edge) == 2
            edge = sort(edge);
            edge = reshape(edge, 1, 2);
            spliced_edges = [spliced_edges; edge];
        end
    end
end

% 3. 从拼接骨干树上的简单拼接获取节点和边
spliced_backbone_simple_nodes = [];
splice_edges = [];

if isfield(spliced_depth_info, 'simple_splice_info') && ~isempty(spliced_depth_info.simple_splice_info)
    splice_info = spliced_depth_info.simple_splice_info;
    
    % 获取拼接节点
    if isfield(splice_info, 'all_spliced_nodes')
        spliced_backbone_simple_nodes = splice_info.all_spliced_nodes;
    elseif isfield(splice_info, 'depth2_spliced_info') && isfield(splice_info.depth2_spliced_info, 'spliced_nodes')
        spliced_backbone_simple_nodes = splice_info.depth2_spliced_info.spliced_nodes;
    end
    
    % 处理边信息
    if isfield(splice_info, 'edges') && ~isempty(splice_info.edges)
        for i = 1:size(splice_info.edges, 1)
            edge = splice_info.edges(i, :);
            if length(edge) == 2
                edge = sort(edge);
                edge = reshape(edge, 1, 2);
                splice_edges = [splice_edges; edge];
            end
        end
    end
end

% 4. 从次级拼接获取节点和边
secondary_nodes = [];
secondary_edges = [];

if isfield(secondary_spliced_info, 'nodes') && ~isempty(secondary_spliced_info.nodes)
    % 收集次级拼接节点信息
    if isfield(secondary_spliced_info, 'depth1_nodes')
        secondary_nodes = [secondary_nodes; secondary_spliced_info.depth1_nodes(:)];
    end
    
    if isfield(secondary_spliced_info, 'depth2_nodes')
        secondary_nodes = [secondary_nodes; secondary_spliced_info.depth2_nodes(:)];
    end
    
    % 收集深度3节点
    if isfield(secondary_spliced_info, 'trees')
        for i = 1:length(secondary_spliced_info.trees)
            tree_info = secondary_spliced_info.trees{i};
            if isfield(tree_info, 'global_depth_info') && isfield(tree_info.global_depth_info, 'depth3_nodes')
                secondary_nodes = [secondary_nodes; tree_info.global_depth_info.depth3_nodes(:)];
            end
        end
    end
    secondary_nodes = unique(secondary_nodes);
    
    % 处理次级拼接边信息
    if isfield(secondary_spliced_info, 'edges') && ~isempty(secondary_spliced_info.edges)
        for i = 1:size(secondary_spliced_info.edges, 1)
            edge = secondary_spliced_info.edges(i, :);
            if length(edge) == 2
                edge = sort(edge);
                edge = reshape(edge, 1, 2);
                secondary_edges = [secondary_edges; edge];
            end
        end
    end
end

% 5. 从简单拼接获取节点和边
simple_nodes = [];
simple_edges = [];

if isfield(simple_spliced_info, 'all_spliced_nodes') && ~isempty(simple_spliced_info.all_spliced_nodes)
    simple_nodes = simple_spliced_info.all_spliced_nodes;
    
    % 处理简单拼接边信息
    if isfield(simple_spliced_info, 'edges') && ~isempty(simple_spliced_info.edges)
        for i = 1:size(simple_spliced_info.edges, 1)
            edge = simple_spliced_info.edges(i, :);
            if length(edge) == 2
                edge = sort(edge);
                edge = reshape(edge, 1, 2);
                simple_edges = [simple_edges; edge];
            end
        end
    end
end

% 合并所有节点和边信息
all_nodes = unique([backbone_nodes; spliced_nodes; spliced_backbone_simple_nodes; secondary_nodes; simple_nodes]);
all_edges_raw = [backbone_edges; spliced_edges; splice_edges; secondary_edges; simple_edges];

% 去除重复边
all_edges = [];
for i = 1:size(all_edges_raw, 1)
    edge = all_edges_raw(i, :);
    
    % 检查是否已存在
    is_new_edge = true;
    if ~isempty(all_edges)
        for j = 1:size(all_edges, 1)
            if all(all_edges(j,:) == edge)
                is_new_edge = false;
                break;
            end
        end
    end
    
    if is_new_edge
        all_edges = [all_edges; edge];
    end
end

% 计算所有节点的深度
n = size(filtered_adj_mat, 1);
node_depths = -ones(n, 1);  % 初始化所有节点深度为-1
node_depths(source_node) = 0;  % 源节点深度为0

% 构建综合树的邻接矩阵
integrated_adj_mat = zeros(n);
for i = 1:size(all_edges, 1)
    node1 = all_edges(i, 1);
    node2 = all_edges(i, 2);
    integrated_adj_mat(node1, node2) = filtered_adj_mat(node1, node2);
    integrated_adj_mat(node2, node1) = filtered_adj_mat(node2, node1);
end

% 使用BFS计算深度
queue = source_node;
visited = false(n, 1);
visited(source_node) = true;

while ~isempty(queue)
    current = queue(1);
    queue(1) = [];
    
    % 获取当前节点的邻居
    neighbors = find(integrated_adj_mat(current, :) > 0);
    
    for neighbor = neighbors
        if ~visited(neighbor)
            visited(neighbor) = true;
            node_depths(neighbor) = node_depths(current) + 1;
            queue = [queue, neighbor];
        end
    end
end

% 按深度分类节点
depth0_nodes = all_nodes(node_depths(all_nodes) == 0);
depth1_nodes = all_nodes(node_depths(all_nodes) == 1);
depth2_nodes = all_nodes(node_depths(all_nodes) == 2);
depth3_nodes = all_nodes(node_depths(all_nodes) == 3);
unknown_depth_nodes = all_nodes(node_depths(all_nodes) == -1);

% ===================== 2. 创建可视化 =====================
% 创建新图形窗口
figure('Name', '综合树结构可视化', 'Position', [100, 100, 1200, 800]);

% 计算最大深度
max_depth = 3;
if ~isempty(unknown_depth_nodes)
    max_depth = 4;
end

% 为了减少边的交叉，对每层节点进行重新排序
% 创建一个保存所有节点之间连接关系的邻接列表
adj_list = cell(n, 1);
for i = 1:n
    adj_list{i} = find(integrated_adj_mat(i, :) > 0);
end

% 初始化节点坐标
node_positions = zeros(n, 2);
width = 1000;  % 增加图形宽度，使节点分布更加分散
height_offset = 50;  % 整体向上移动的偏移量

% 先放置源节点（深度0）
if ~isempty(depth0_nodes)
    node_positions(source_node, 1) = width / 2;  % x坐标居中
    node_positions(source_node, 2) = max_depth * 140 + height_offset;  % y坐标最上层，整体提升
end

% 对深度1节点进行排序和放置
if ~isempty(depth1_nodes)
    % 按照与源节点的权重降序排列
    depths_weights = zeros(length(depth1_nodes), 2);
    for i = 1:length(depth1_nodes)
        node = depth1_nodes(i);
        depths_weights(i, 1) = node;
        depths_weights(i, 2) = integrated_adj_mat(source_node, node);
    end
    [~, idx] = sort(depths_weights(:, 2), 'descend');
    depth1_nodes = depth1_nodes(idx);
    
    % 放置深度1节点
    spacing = width / (length(depth1_nodes) + 1);
    for i = 1:length(depth1_nodes)
        node = depth1_nodes(i);
        node_positions(node, 1) = i * spacing;
        node_positions(node, 2) = (max_depth - 1) * 140 + height_offset;
    end
end

% 对深度2节点进行排序和放置，使分布更广
if ~isempty(depth2_nodes)
    % 初始化节点顺序
    optimized_order = [];
    
    % 遍历深度1节点及其相连的深度2节点
    for i = 1:length(depth1_nodes)
        parent = depth1_nodes(i);
        children = intersect(adj_list{parent}, depth2_nodes);
        
        % 按照权重降序排列子节点
        if ~isempty(children)
            children_weights = zeros(length(children), 2);
            for j = 1:length(children)
                children_weights(j, 1) = children(j);
                children_weights(j, 2) = integrated_adj_mat(parent, children(j));
            end
            [~, idx] = sort(children_weights(:, 2), 'descend');
            optimized_order = [optimized_order; children(idx)];
        end
    end
    
    % 添加未被选中的深度2节点
    remaining = setdiff(depth2_nodes, optimized_order);
    optimized_order = [optimized_order; remaining];
    
    % 去除重复节点，保留第一次出现
    depth2_nodes = [];
    for i = 1:length(optimized_order)
        if ~ismember(optimized_order(i), depth2_nodes)
            depth2_nodes = [depth2_nodes; optimized_order(i)];
        end
    end
    
    % 放置深度2节点，使用更宽的分布
    spacing = (width * 1.2) / (length(depth2_nodes) + 1);
    offset = (width - (spacing * (length(depth2_nodes) + 1))) / 2;
    for i = 1:length(depth2_nodes)
        node = depth2_nodes(i);
        node_positions(node, 1) = offset + i * spacing;
        node_positions(node, 2) = (max_depth - 2) * 140 + height_offset;
    end
end

% 对深度3节点进行排序和放置，使分布更加广泛
if ~isempty(depth3_nodes)
    % 初始化节点顺序
    optimized_order = [];
    
    % 遍历深度2节点及其相连的深度3节点
    for i = 1:length(depth2_nodes)
        parent = depth2_nodes(i);
        children = intersect(adj_list{parent}, depth3_nodes);
        
        % 按照权重降序排列子节点
        if ~isempty(children)
            children_weights = zeros(length(children), 2);
            for j = 1:length(children)
                children_weights(j, 1) = children(j);
                children_weights(j, 2) = integrated_adj_mat(parent, children(j));
            end
            [~, idx] = sort(children_weights(:, 2), 'descend');
            optimized_order = [optimized_order; children(idx)];
        end
    end
    
    % 添加未被选中的深度3节点
    remaining = setdiff(depth3_nodes, optimized_order);
    optimized_order = [optimized_order; remaining];
    
    % 去除重复节点，保留第一次出现
    depth3_nodes = [];
    for i = 1:length(optimized_order)
        if ~ismember(optimized_order(i), depth3_nodes)
            depth3_nodes = [depth3_nodes; optimized_order(i)];
        end
    end
    
    % 放置深度3节点，最大范围分布
    spacing = (width * 1.4) / (length(depth3_nodes) + 1);
    offset = (width - (spacing * (length(depth3_nodes) + 1))) / 2;
    for i = 1:length(depth3_nodes)
        node = depth3_nodes(i);
        node_positions(node, 1) = offset + i * spacing;
        node_positions(node, 2) = (max_depth - 3) * 140 + height_offset;
    end
end

% 放置未知深度节点（如果有的话）
if ~isempty(unknown_depth_nodes)
    spacing = (width * 1.4) / (length(unknown_depth_nodes) + 1);
    offset = (width - (spacing * (length(unknown_depth_nodes) + 1))) / 2;
    for i = 1:length(unknown_depth_nodes)
        node = unknown_depth_nodes(i);
        node_positions(node, 1) = offset + i * spacing;
        node_positions(node, 2) = height_offset;  % 最底层
    end
end

% 绘制边
hold on;
for i = 1:size(all_edges, 1)
    node1 = all_edges(i, 1);
    node2 = all_edges(i, 2);
    
    % 绘制边
    x = [node_positions(node1, 1), node_positions(node2, 1)];
    y = [node_positions(node1, 2), node_positions(node2, 2)];
    
    % 计算权重
    weight = filtered_adj_mat(node1, node2);
    
    % 根据权重设置边宽
    line_width = 1 + weight / 50;  % 根据权重调整边宽
    
    % 绘制边
    line_h = plot(x, y, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', line_width);
    
    % 绘制权重标签
    mid_x = (x(1) + x(2)) / 2;
    mid_y = (y(1) + y(2)) / 2;
    text(mid_x, mid_y, sprintf('%.1f', weight), 'FontSize', 8, 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1 0.7]);
    
    % 如果有时间信息，计算并显示传输时间
    if show_times
        % 假设数据大小为1000
        data_size = 1000;
        transmission_time = data_size / weight;
        text(mid_x, mid_y - 15, sprintf('传输: %.1f', transmission_time), 'FontSize', 7, 'HorizontalAlignment', 'center', 'BackgroundColor', [1 0.9 0.9 0.7], 'Color', [0.8 0 0]);
    end
end

% 绘制节点
% 绘制非源节点
all_non_source_nodes = setdiff(all_nodes, source_node);
for i = 1:length(all_non_source_nodes)
    node = all_non_source_nodes(i);
    scatter(node_positions(node, 1), node_positions(node, 2), 100, [0.85 0.85 0.85], 'filled', 'MarkerEdgeColor', 'none');
    
    % 显示节点编号
    text(node_positions(node, 1), node_positions(node, 2), num2str(node), 'FontSize', 10, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    
    % 如果有时间信息，显示节点的汇聚时间
    if show_times && node <= length(node_times) && node_times(node) > 0
        text(node_positions(node, 1) + 15, node_positions(node, 2) + 10, sprintf('时间: %.1f', node_times(node)), 'FontSize', 7, 'HorizontalAlignment', 'left', 'BackgroundColor', [0.9 1 0.9 0.7], 'Color', [0 0.5 0]);
    end
end

% 绘制源节点（高亮）
scatter(node_positions(source_node, 1), node_positions(source_node, 2), 150, 'r', 'filled', 'MarkerEdgeColor', 'none');
text(node_positions(source_node, 1), node_positions(source_node, 2), num2str(source_node), 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', 'white');

% 如果有时间信息，显示源节点的总时间
if show_times && source_node <= length(node_times) && node_times(source_node) > 0
    text(node_positions(source_node, 1) + 20, node_positions(source_node, 2) + 10, sprintf('总时间: %.1f', node_times(source_node)), 'FontSize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 0.8 0.8], 'Color', [0.7 0 0]);
end

% 删除深度标签

% 设置图形属性
axis off;  % 关闭坐标轴
title('综合树结构可视化', 'FontSize', 14);
hold off;

% 设置图形大小，确保有足够空间显示所有节点
axis([-100 width+100 0 (max_depth)*140+height_offset+50]);

end 