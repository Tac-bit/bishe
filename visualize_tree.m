function [highlighted_edges] = visualize_tree(filtered_adj_mat_copy, depth_info, spliced_depth_info, simple_spliced_info)
% 可视化特殊过滤后的拓扑
% 输入:
%   filtered_adj_mat_copy: 特殊过滤后的邻接矩阵
%   depth_info: （可选）包含不同深度节点的结构体
%       depth_info.depth0_nodes: 深度为0的节点（源节点）
%       depth_info.depth1_nodes: 深度为1的节点
%       depth_info.depth2_nodes: 深度为2的节点
%       depth_info.depth3_nodes: 深度为3的节点
%   spliced_depth_info: （可选）拼接骨干树的深度节点信息结构体
%       包含与depth_info相同的字段
%   simple_spliced_info: （可选）简单拼接的信息结构体
%       simple_spliced_info.nodes: 深度为2的节点
%       simple_spliced_info.edges: 拼接边 [source_points, target_points]
%       simple_spliced_info.weights: 边的权重
%       simple_spliced_info.depth3_nodes: 拼接得到的深度3节点
% 输出:
%   highlighted_edges: 拼接骨干树的边信息结构体
%       highlighted_edges.depth0_to_1: 深度0到深度1的边 [node0, node1]
%       highlighted_edges.depth1_to_2: 深度1到深度2的边 [node1, node2]
%       highlighted_edges.depth2_to_3: 深度2到深度3的边 [node2, node3]
%       highlighted_edges.simple_splice_edges: 简单拼接边 [source_points, target_points]

% ===================== 1. 初始化 =====================
% 初始化边信息结构体
highlighted_edges = struct('depth0_to_1', [], 'depth1_to_2', [], 'depth2_to_3', [], 'simple_splice_edges', []);

% ===================== 2. 创建基础图 =====================
% 创建图对象
G = graph(filtered_adj_mat_copy);

% 创建新图形窗口
figure('Name', '特殊过滤后的拓扑结构', 'Position', [100, 100, 1000, 800]);

% 绘制基础拓扑图
p = plot(G, 'Layout', 'force',...
    'UseGravity', true, ...
    'NodeColor', [0.6 0.6 0.6], ...  % 默认节点颜色为浅灰色
    'MarkerSize', 8, ...             % 增大节点尺寸
    'EdgeColor', [0.3 0.3 0.3], ...  % 深灰色边
    'LineWidth', 2.0, ...            % 加粗边线
    'EdgeAlpha', 0.7);               % 边透明度

% ===================== 3. 高亮骨干树节点 =====================
% 使用从analyze_pruned_tree.m获取的depth_info信息
if nargin > 1 && isstruct(depth_info)
    % 深度0（源节点）- 红色
    if isfield(depth_info, 'depth0_nodes') && ~isempty(depth_info.depth0_nodes)
        highlight(p, depth_info.depth0_nodes, 'NodeColor', 'r', 'MarkerSize', 12);
    end
    % 深度1 - 紫色
    if isfield(depth_info, 'depth1_nodes') && ~isempty(depth_info.depth1_nodes)
        highlight(p, depth_info.depth1_nodes, 'NodeColor', [0.5 0 0.5]);
    end
    % 深度2 - 绿色
    if isfield(depth_info, 'depth2_nodes') && ~isempty(depth_info.depth2_nodes)
        highlight(p, depth_info.depth2_nodes, 'NodeColor', 'g');
    end
    % 深度3 - 蓝色
    if isfield(depth_info, 'depth3_nodes') && ~isempty(depth_info.depth3_nodes)
        highlight(p, depth_info.depth3_nodes, 'NodeColor', 'b');
    end
end

% ===================== 4. 高亮拼接骨干树节点 =====================
% 使用从analyze_pruned_tree.m获取的spliced_depth_info信息
if nargin > 2 && isstruct(spliced_depth_info)
    % 首先高亮所有节点
    % 深度0（源节点）- 红色
    if isfield(spliced_depth_info, 'depth0_nodes') && ~isempty(spliced_depth_info.depth0_nodes)
        highlight(p, spliced_depth_info.depth0_nodes, 'NodeColor', 'r', 'MarkerSize', 12);
    end
    % 深度1 - 紫色
    if isfield(spliced_depth_info, 'depth1_nodes') && ~isempty(spliced_depth_info.depth1_nodes)
        highlight(p, spliced_depth_info.depth1_nodes, 'NodeColor', [0.5 0 0.5], 'MarkerSize', 10);
    end
    % 深度2 - 绿色
    if isfield(spliced_depth_info, 'depth2_nodes') && ~isempty(spliced_depth_info.depth2_nodes)
        highlight(p, spliced_depth_info.depth2_nodes, 'NodeColor', 'g', 'MarkerSize', 10);
    end
    % 深度3 - 蓝色
    if isfield(spliced_depth_info, 'depth3_nodes') && ~isempty(spliced_depth_info.depth3_nodes)
        highlight(p, spliced_depth_info.depth3_nodes, 'NodeColor', 'b', 'MarkerSize', 10);
    end
    
    % 然后高亮拼接骨干树边（红色）
    if isfield(spliced_depth_info, 'tree_edges') && ~isempty(spliced_depth_info.tree_edges)
        % 确保tree_edges是N×2的矩阵
        if size(spliced_depth_info.tree_edges, 2) == 2
            for i = 1:size(spliced_depth_info.tree_edges, 1)
                edge = spliced_depth_info.tree_edges(i, :);
                % 检查边是否存在于图中
                if edge(1) <= numnodes(G) && edge(2) <= numnodes(G)
                    highlight(p, edge, 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle', '-');
                    
                    % 记录边信息
                    if edge(1) < edge(2)  % 确保边的方向从小节点到大节点
                        if ismember(edge(1), spliced_depth_info.depth0_nodes) && ismember(edge(2), spliced_depth_info.depth1_nodes)
                            highlighted_edges.depth0_to_1 = [highlighted_edges.depth0_to_1; edge];
                        elseif ismember(edge(1), spliced_depth_info.depth1_nodes) && ismember(edge(2), spliced_depth_info.depth2_nodes)
                            highlighted_edges.depth1_to_2 = [highlighted_edges.depth1_to_2; edge];
                        elseif ismember(edge(1), spliced_depth_info.depth2_nodes) && ismember(edge(2), spliced_depth_info.depth3_nodes)
                            highlighted_edges.depth2_to_3 = [highlighted_edges.depth2_to_3; edge];
                        end
                    end
                end
            end
        else
            warning('spliced_depth_info.tree_edges格式不正确，应为N×2矩阵');
        end
    end
end

% ===================== 5. 高亮次级拼接 =====================
% 使用从analyze_pruned_tree.m获取的secondary_spliced_info信息
if nargin > 2 && isstruct(spliced_depth_info) && isfield(spliced_depth_info, 'depth2_spliced_info')
    secondary_info = spliced_depth_info.depth2_spliced_info;
    
    % 首先高亮新增的节点
    % 高亮次级拼接的深度1节点（紫色）
    if isfield(secondary_info, 'nodes') && ~isempty(secondary_info.nodes)
        new_nodes = setdiff(secondary_info.nodes, spliced_depth_info.depth1_nodes);
        if ~isempty(new_nodes)
            highlight(p, new_nodes, 'NodeColor', [0.5 0 0.5]);
        end
    end
    % 高亮次级拼接的深度2节点（绿色）
    if isfield(secondary_info, 'depth2_nodes') && ~isempty(secondary_info.depth2_nodes)
        new_nodes = setdiff(secondary_info.depth2_nodes, spliced_depth_info.depth2_nodes);
        if ~isempty(new_nodes)
            highlight(p, new_nodes, 'NodeColor', 'g');
        end
    end
    % 高亮次级拼接的深度3节点（蓝色）
    if isfield(secondary_info, 'depth3_nodes') && ~isempty(secondary_info.depth3_nodes)
        new_nodes = setdiff(secondary_info.depth3_nodes, spliced_depth_info.depth3_nodes);
        if ~isempty(new_nodes)
            highlight(p, new_nodes, 'NodeColor', 'b');
        end
    end
    
    % 然后高亮次级拼接边（红色）
    if isfield(secondary_info, 'edges') && ~isempty(secondary_info.edges)
        % 确保edges是N×2的矩阵
        if size(secondary_info.edges, 2) == 2
            for i = 1:size(secondary_info.edges, 1)
                edge = secondary_info.edges(i, :);
                % 检查边是否存在于图中且不在拼接骨干树中
                if edge(1) <= numnodes(G) && edge(2) <= numnodes(G)
                    % 检查边是否已经在拼接骨干树中
                    is_duplicate = false;
                    if ~isempty(spliced_depth_info.tree_edges)
                        for j = 1:size(spliced_depth_info.tree_edges, 1)
                            if (edge(1) == spliced_depth_info.tree_edges(j,1) && edge(2) == spliced_depth_info.tree_edges(j,2)) || ...
                               (edge(1) == spliced_depth_info.tree_edges(j,2) && edge(2) == spliced_depth_info.tree_edges(j,1))
                                is_duplicate = true;
                                break;
                            end
                        end
                    end
                    if ~is_duplicate
                        highlight(p, edge, 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle', '-');
                    end
                end
            end
        else
            warning('secondary_info.edges格式不正确，应为N×2矩阵');
        end
    end
end

% ===================== 5.5 高亮竞争节点及其处理 =====================
% 如果存在竞争信息，特殊高亮竞争节点和次级拼接边
if nargin > 2 && isstruct(spliced_depth_info) && isfield(spliced_depth_info, 'competition_info')
    competition_info = spliced_depth_info.competition_info;
    
    % 处理竞争节点（保留原来深度的颜色）
    if isfield(competition_info, 'nodes') && ~isempty(competition_info.nodes)
        % 方法1：不使用边框标记，仅在节点上方添加五角星
        % 不再使用highlight添加边框
        % highlight(p, competition_info.nodes, 'Marker', 'o', 'LineWidth', 2);
        
        % 在竞争节点上添加特殊标签
        for i = 1:length(competition_info.nodes)
            node = competition_info.nodes(i);
            % 获取节点位置 - 使用适合cell数组的比较方法
            node_str = num2str(node);
            node_idx = [];
            for j = 1:length(p.NodeLabel)
                if strcmp(p.NodeLabel{j}, node_str)
                    node_idx = j;
                    break;
                end
            end
            
            if ~isempty(node_idx)
                x = p.XData(node_idx);
                y = p.YData(node_idx);
                % 添加五角星标记而不是星号
                text(x, y+0.2, '★', 'FontSize', 14, 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
            end
        end
    end
    
    % 高亮已移除的骨干树边（灰色实线，表示已被移除）
    if isfield(competition_info, 'backbone_edges') && ~isempty(competition_info.backbone_edges)
        for i = 1:size(competition_info.backbone_edges, 1)
            edge = competition_info.backbone_edges(i, :);
            if edge(1) <= numnodes(G) && edge(2) <= numnodes(G)
                % 检查边是否存在于图中
                if findedge(G, edge(1), edge(2)) > 0
                    highlight(p, edge, 'EdgeColor', [0.7 0.7 0.7], 'LineWidth', 2, 'LineStyle', '-');
                end
            end
        end
    end
    
    % 高亮保留的次级拼接边（红色粗实线）
    if isfield(competition_info, 'secondary_edges') && ~isempty(competition_info.secondary_edges)
        for i = 1:size(competition_info.secondary_edges, 1)
            edge = competition_info.secondary_edges(i, :);
            if edge(1) <= numnodes(G) && edge(2) <= numnodes(G)
                % 检查边是否存在于图中
                if findedge(G, edge(1), edge(2)) > 0
                    highlight(p, edge, 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle', '-');
                end
            end
        end
    end
end

% ===================== 6. 高亮简单拼接 =====================
% 使用从analyze_pruned_tree.m获取的simple_spliced_info信息
if nargin > 3 && isstruct(simple_spliced_info)
    % 高亮简单拼接的深度2节点（绿色）
    if isfield(simple_spliced_info, 'nodes') && ~isempty(simple_spliced_info.nodes)
        highlight(p, simple_spliced_info.nodes, 'NodeColor', 'g');
    end
    % 高亮简单拼接的深度3节点（蓝色）
    if isfield(simple_spliced_info, 'depth3_nodes') && ~isempty(simple_spliced_info.depth3_nodes)
        highlight(p, simple_spliced_info.depth3_nodes, 'NodeColor', 'b');
    end
    
    % 高亮简单拼接边（红色）
    if isfield(simple_spliced_info, 'edges') && ~isempty(simple_spliced_info.edges)
        for i = 1:size(simple_spliced_info.edges, 1)
            edge = simple_spliced_info.edges(i, :);
            highlight(p, edge, 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle', '-');
        end
        highlighted_edges.simple_splice_edges = simple_spliced_info.edges;
    end
end

% ===================== 6.6 高亮拼接骨干树上的简单拼接 =====================
% 处理拼接骨干树上的简单拼接信息
if nargin > 2 && isstruct(spliced_depth_info) && isfield(spliced_depth_info, 'simple_splice_info')
    spliced_simple_info = spliced_depth_info.simple_splice_info;
    
    % 高亮拼接骨干树上简单拼接的深度2节点（绿色更深）
    if isfield(spliced_simple_info, 'nodes') && ~isempty(spliced_simple_info.nodes)
        % 这些节点已经在上面高亮为绿色，这里可以再次高亮，使颜色更深
        highlight(p, spliced_simple_info.nodes, 'NodeColor', [0 0.7 0]);
    end
    
    % 高亮拼接骨干树上简单拼接的深度3节点（蓝色）
    if isfield(spliced_simple_info, 'depth3_nodes') && ~isempty(spliced_simple_info.depth3_nodes)
        highlight(p, spliced_simple_info.depth3_nodes, 'NodeColor', 'b');
    end
    
    % 高亮拼接骨干树上简单拼接边（橙红色，以区别于其他拼接边）
    if isfield(spliced_simple_info, 'edges') && ~isempty(spliced_simple_info.edges)
        for i = 1:size(spliced_simple_info.edges, 1)
            edge = spliced_simple_info.edges(i, :);
            highlight(p, edge, 'EdgeColor', [1 0.5 0], 'LineWidth', 3, 'LineStyle', '-');
        end
        % 记录这些边
        highlighted_edges.spliced_simple_edges = spliced_simple_info.edges;
    end
end

% ===================== 7. 添加标签和美化 =====================
% 显示节点标签
labelnode(p, 1:numnodes(G), 1:numnodes(G));

% 显示边权值（保留整数）
labeledge(p, 1:numedges(G), round(G.Edges.Weight));

% 调整边标签文本属性以提高可读性
edge_labels = findobj(gca, 'Type', 'text');
set(edge_labels, 'FontWeight', 'bold', 'FontSize', 8, 'BackgroundColor', [1 1 1 0.7]);

% 添加标题
title('特殊过滤后的拓扑结构（拼接骨干树）', 'FontSize', 16, 'FontWeight', 'bold');

% 修改轴的显示
axis off;
box off;

% 调整图形窗口大小以适应内容
set(gcf, 'Color', 'white');
set(gca, 'Position', [0.1 0.1 0.8 0.8]);
end 