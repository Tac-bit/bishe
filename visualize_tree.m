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

% 初始化边信息结构体
highlighted_edges = struct('depth0_to_1', [], 'depth1_to_2', [], 'depth2_to_3', [], 'simple_splice_edges', []);

% 创建图对象
G = graph(filtered_adj_mat_copy);

% 创建新图形窗口
figure('Name', '特殊过滤后的拓扑结构', 'Position', [100, 100, 1000, 800]);

% 绘制拓扑图
p = plot(G, 'Layout', 'force',...
    'UseGravity', true, ...
    'NodeColor', [0.6 0.6 0.6], ...  % 默认节点颜色为浅灰色
    'MarkerSize', 8, ...             % 增大节点尺寸
    'EdgeColor', [0.3 0.3 0.3], ...  % 深灰色边
    'LineWidth', 2.0, ...            % 加粗边线
    'EdgeAlpha', 0.7);               % 边透明度

% 如果提供了深度信息，则根据深度设置节点颜色
if nargin > 1 && isstruct(depth_info)
    % 深度0（源节点）- 红色
    if isfield(depth_info, 'depth0_nodes') && ~isempty(depth_info.depth0_nodes)
        highlight(p, depth_info.depth0_nodes, 'NodeColor', 'r');
    end
    % 深度1 - 紫色
    if isfield(depth_info, 'depth1_nodes') && ~isempty(depth_info.depth1_nodes)
        highlight(p, depth_info.depth1_nodes, 'NodeColor', 'm');
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

% 如果提供了拼接骨干树信息，则高亮边和节点
if nargin > 2 && isstruct(spliced_depth_info)
    % 深度0（源节点）- 红色
    if isfield(spliced_depth_info, 'depth0_nodes') && ~isempty(spliced_depth_info.depth0_nodes)
        highlight(p, spliced_depth_info.depth0_nodes, 'NodeColor', 'r');
    end
    % 深度1 - 紫色，并高亮与深度0的连接边
    if isfield(spliced_depth_info, 'depth1_nodes') && ~isempty(spliced_depth_info.depth1_nodes)
        highlight(p, spliced_depth_info.depth1_nodes, 'NodeColor', 'm');
        % 高亮深度0到深度1的边
        temp_edges = [];
        for node1 = spliced_depth_info.depth1_nodes(:)'  % 确保是行向量
            for node0 = spliced_depth_info.depth0_nodes(:)'  % 确保是行向量
                if filtered_adj_mat_copy(node0, node1) > 0
                    highlight(p, [node0, node1], 'EdgeColor', 'r', 'LineWidth', 2.0);
                    temp_edges = [temp_edges; node0, node1];
                end
            end
        end
        highlighted_edges.depth0_to_1 = temp_edges;
    end
    % 深度2 - 绿色，并高亮与深度1的连接边
    if isfield(spliced_depth_info, 'depth2_nodes') && ~isempty(spliced_depth_info.depth2_nodes)
        highlight(p, spliced_depth_info.depth2_nodes, 'NodeColor', 'g');
        % 高亮深度1到深度2的边
        temp_edges = [];
        for node2 = spliced_depth_info.depth2_nodes(:)'  % 确保是行向量
            for node1 = spliced_depth_info.depth1_nodes(:)'  % 确保是行向量
                if filtered_adj_mat_copy(node1, node2) > 0
                    highlight(p, [node1, node2], 'EdgeColor', 'r', 'LineWidth', 2.0);
                    temp_edges = [temp_edges; node1, node2];
                end
            end
        end
        highlighted_edges.depth1_to_2 = temp_edges;
    end
    % 深度3 - 蓝色，并高亮与深度2的连接边
    if isfield(spliced_depth_info, 'depth3_nodes') && ~isempty(spliced_depth_info.depth3_nodes)
        highlight(p, spliced_depth_info.depth3_nodes, 'NodeColor', 'b');
        % 高亮深度2到深度3的边
        temp_edges = [];
        for node3 = spliced_depth_info.depth3_nodes(:)'  % 确保是行向量
            for node2 = spliced_depth_info.depth2_nodes(:)'  % 确保是行向量
                if filtered_adj_mat_copy(node2, node3) > 0
                    highlight(p, [node2, node3], 'EdgeColor', 'r', 'LineWidth', 2.0);
                    temp_edges = [temp_edges; node2, node3];
                end
            end
        end
        highlighted_edges.depth2_to_3 = temp_edges;
    end
end

% 如果提供了简单拼接信息，则高亮显示简单拼接边
if nargin > 3 && isstruct(simple_spliced_info)
    % 高亮简单拼接的深度2节点（保持原有颜色，因为它们已经在depth_info中被标记为绿色）
    if isfield(simple_spliced_info, 'nodes') && ~isempty(simple_spliced_info.nodes)
        highlight(p, simple_spliced_info.nodes, 'NodeColor', 'g');
    end
    % 高亮简单拼接得到的深度3节点（蓝色）
    if isfield(simple_spliced_info, 'depth3_nodes') && ~isempty(simple_spliced_info.depth3_nodes)
        highlight(p, simple_spliced_info.depth3_nodes, 'NodeColor', 'b');  % 使用蓝色高亮深度3节点
    end
    % 高亮简单拼接边（红色）
    if isfield(simple_spliced_info, 'edges') && ~isempty(simple_spliced_info.edges)
        for i = 1:size(simple_spliced_info.edges, 1)
            highlight(p, [simple_spliced_info.edges(i,1), simple_spliced_info.edges(i,2)], 'EdgeColor', 'r', 'LineWidth', 2.0);
        end
        highlighted_edges.simple_splice_edges = simple_spliced_info.edges;
    end
end

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