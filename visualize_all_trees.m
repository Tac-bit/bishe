function visualize_all_trees(filtered_adj_mat, depth_info, spliced_depth_info, simple_spliced_info, pruned_tree_mat)
% 在过滤拓扑上可视化所有树结构
% 输入:
%   filtered_adj_mat: Metro_filter过滤后的邻接矩阵
%   depth_info: 骨干树深度节点信息结构体
%       depth_info.depth0_nodes: 深度为0的节点（源节点）
%       depth_info.depth1_nodes: 深度为1的节点
%       depth_info.depth2_nodes: 深度为2的节点
%       depth_info.depth3_nodes: 深度为3的节点
%   spliced_depth_info: 拼接骨干树深度节点信息结构体
%       包含与depth_info相同的字段，以及tree_edges
%   simple_spliced_info: 简单拼接信息结构体
%       simple_spliced_info.nodes: 深度为2的节点
%       simple_spliced_info.edges: 拼接边
%       simple_spliced_info.depth3_nodes: 拼接得到的深度3节点
%   pruned_tree_mat: 修剪后的骨干树邻接矩阵

% 创建图对象
G = graph(filtered_adj_mat);

% 创建新图形窗口
figure('Name', '综合树结构可视化', 'Position', [100, 100, 1000, 800]);

% 绘制基础拓扑图
p = plot(G, 'Layout', 'force', 'UseGravity', true, 'Iterations', 1000);
p.NodeColor = [0.7 0.7 0.7];  % 默认节点颜色为浅灰色
p.EdgeColor = [0.7 0.7 0.7];  % 默认边颜色为浅灰色
p.LineWidth = 2.0;  % 设置边宽
p.MarkerSize = 8;   % 设置节点大小
p.NodeFontSize = 12;  % 设置节点标签字体大小
p.LineStyle = '-';  % 设置所有边为实线

% 高亮骨干树的边（淡蓝色）
for i = 1:size(pruned_tree_mat, 1)
    for j = i+1:size(pruned_tree_mat, 1)
        if pruned_tree_mat(i,j) > 0
            edge_idx = findedge(G, i, j);
            if edge_idx > 0
                highlight(p, i, j, 'EdgeColor', [0.6 0.8 1.0], 'LineWidth', 3, 'LineStyle', '-');
            end
        end
    end
end

% 设置节点颜色（按深度）
if isstruct(depth_info)
    % 深度0（源节点）- 红色，更大的尺寸
    if isfield(depth_info, 'depth0_nodes') && ~isempty(depth_info.depth0_nodes)
        highlight(p, depth_info.depth0_nodes, 'NodeColor', 'r', 'MarkerSize', 12);  % 增大源节点尺寸
    end
    % 深度1 - 紫色
    if isfield(depth_info, 'depth1_nodes') && ~isempty(depth_info.depth1_nodes)
        highlight(p, depth_info.depth1_nodes, 'NodeColor', [0.5 0 0.5]);
        % 高亮深度0到深度1的边
        for node1 = depth_info.depth1_nodes(:)'
            for node0 = depth_info.depth0_nodes(:)'
                if pruned_tree_mat(node0, node1) > 0
                    highlight(p, [node0, node1], 'EdgeColor', [0.6 0.8 1.0], 'LineWidth', 3, 'LineStyle', '-');
                end
            end
        end
    end
    % 深度2 - 绿色
    if isfield(depth_info, 'depth2_nodes') && ~isempty(depth_info.depth2_nodes)
        highlight(p, depth_info.depth2_nodes, 'NodeColor', 'g');
        % 高亮深度1到深度2的边
        for node2 = depth_info.depth2_nodes(:)'
            for node1 = depth_info.depth1_nodes(:)'
                if pruned_tree_mat(node1, node2) > 0
                    highlight(p, [node1, node2], 'EdgeColor', [0.6 0.8 1.0], 'LineWidth', 3, 'LineStyle', '-');
                end
            end
        end
    end
    % 深度3 - 蓝色
    if isfield(depth_info, 'depth3_nodes') && ~isempty(depth_info.depth3_nodes)
        highlight(p, depth_info.depth3_nodes, 'NodeColor', 'b');
        % 高亮深度2到深度3的边
        for node3 = depth_info.depth3_nodes(:)'
            for node2 = depth_info.depth2_nodes(:)'
                if pruned_tree_mat(node2, node3) > 0
                    highlight(p, [node2, node3], 'EdgeColor', [0.6 0.8 1.0], 'LineWidth', 3, 'LineStyle', '-');
                end
            end
        end
    end
end

% 设置拼接树节点颜色（按深度）
if isstruct(spliced_depth_info)
    % 深度0（源节点）- 红色
    if isfield(spliced_depth_info, 'depth0_nodes') && ~isempty(spliced_depth_info.depth0_nodes)
        highlight(p, spliced_depth_info.depth0_nodes, 'NodeColor', 'r', 'MarkerSize', 12);
    end
    % 深度1 - 紫色，并高亮与深度0的连接边
    if isfield(spliced_depth_info, 'depth1_nodes') && ~isempty(spliced_depth_info.depth1_nodes)
        highlight(p, spliced_depth_info.depth1_nodes, 'NodeColor', [0.5 0 0.5]);
        % 高亮深度0到深度1的边
        for node1 = spliced_depth_info.depth1_nodes(:)'
            for node0 = spliced_depth_info.depth0_nodes(:)'
                if filtered_adj_mat(node0, node1) > 0
                    % 检查是否是拼接边
                    if isfield(spliced_depth_info, 'tree_edges') && ~isempty(spliced_depth_info.tree_edges)
                        if any(ismember(spliced_depth_info.tree_edges, [node0, node1], 'rows'))
                            highlight(p, [node0, node1], 'EdgeColor', 'r', 'LineWidth', 3);
                        end
                    end
                end
            end
        end
    end
    % 深度2 - 绿色，并高亮与深度1的连接边
    if isfield(spliced_depth_info, 'depth2_nodes') && ~isempty(spliced_depth_info.depth2_nodes)
        highlight(p, spliced_depth_info.depth2_nodes, 'NodeColor', 'g');
        % 高亮深度1到深度2的边
        for node2 = spliced_depth_info.depth2_nodes(:)'
            for node1 = spliced_depth_info.depth1_nodes(:)'
                if filtered_adj_mat(node1, node2) > 0
                    % 检查是否是拼接边
                    if isfield(spliced_depth_info, 'tree_edges') && ~isempty(spliced_depth_info.tree_edges)
                        if any(ismember(spliced_depth_info.tree_edges, [node1, node2], 'rows'))
                            highlight(p, [node1, node2], 'EdgeColor', 'r', 'LineWidth', 3);
                        end
                    end
                end
            end
        end
    end
    % 深度3 - 蓝色，并高亮与深度2的连接边
    if isfield(spliced_depth_info, 'depth3_nodes') && ~isempty(spliced_depth_info.depth3_nodes)
        highlight(p, spliced_depth_info.depth3_nodes, 'NodeColor', 'b');
        % 高亮深度2到深度3的边
        for node3 = spliced_depth_info.depth3_nodes(:)'
            for node2 = spliced_depth_info.depth2_nodes(:)'
                if filtered_adj_mat(node2, node3) > 0
                    % 检查是否是拼接边
                    if isfield(spliced_depth_info, 'tree_edges') && ~isempty(spliced_depth_info.tree_edges)
                        if any(ismember(spliced_depth_info.tree_edges, [node2, node3], 'rows'))
                            highlight(p, [node2, node3], 'EdgeColor', 'r', 'LineWidth', 3);
                        end
                    end
                end
            end
        end
    end
end

% 高亮拼接树中深度2节点的拼接边
if isfield(spliced_depth_info, 'depth2_spliced_info') && ~isempty(spliced_depth_info.depth2_spliced_info.edges)
    for i = 1:size(spliced_depth_info.depth2_spliced_info.edges, 1)
        edge = spliced_depth_info.depth2_spliced_info.edges(i, :);
        edge_idx = findedge(G, edge(1), edge(2));
        if edge_idx > 0
            highlight(p, edge(1), edge(2), 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle', '-');
        end
    end
end

% 高亮简单拼接的边和节点
if isstruct(simple_spliced_info)
    % 高亮简单拼接得到的深度3节点（蓝色）
    if isfield(simple_spliced_info, 'depth3_nodes') && ~isempty(simple_spliced_info.depth3_nodes)
        highlight(p, simple_spliced_info.depth3_nodes, 'NodeColor', 'b');
    end
    % 高亮简单拼接边（红色实线）
    if isfield(simple_spliced_info, 'edges') && ~isempty(simple_spliced_info.edges)
        for i = 1:size(simple_spliced_info.edges, 1)
            edge = simple_spliced_info.edges(i, :);
            edge_idx = findedge(G, edge(1), edge(2));
            if edge_idx > 0
                highlight(p, edge(1), edge(2), 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle', '-');
            end
        end
    end
end

% 高亮拼接树的边
if isfield(spliced_depth_info, 'tree_edges') && ~isempty(spliced_depth_info.tree_edges)
    for i = 1:size(spliced_depth_info.tree_edges, 1)
        edge = spliced_depth_info.tree_edges(i, :);
        edge_idx = findedge(G, edge(1), edge(2));
        if edge_idx > 0
            highlight(p, edge(1), edge(2), 'EdgeColor', 'r', 'LineWidth', 3, 'LineStyle', '-');
        end
    end
end

% 显示节点标签
labelnode(p, 1:numnodes(G), 1:numnodes(G));

% 显示所有边的权值
labeledge(p, 1:size(G.Edges,1), G.Edges.Weight);
p.EdgeLabelColor = 'k';  % 设置边权值颜色为黑色
p.EdgeFontSize = 8;      % 设置边权值字体大小

% 添加图例
hold on;
% 创建图例项
plot(NaN, NaN, '-', 'Color', [0.6 0.8 1.0], 'LineWidth', 2, 'DisplayName', '骨干树边');
plot(NaN, NaN, '-', 'Color', 'r', 'LineWidth', 2, 'DisplayName', '拼接边');
plot(NaN, NaN, 'o', 'Color', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 12, 'DisplayName', '源节点(大)');
plot(NaN, NaN, 'o', 'Color', [0.5 0 0.5], 'MarkerFaceColor', [0.5 0 0.5], 'MarkerSize', 8, 'DisplayName', '深度1节点');
plot(NaN, NaN, 'o', 'Color', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', 8, 'DisplayName', '深度2节点');
plot(NaN, NaN, 'o', 'Color', 'b', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', '深度3节点');

% 显示图例
lgd = legend('Location', 'eastoutside');
set(lgd, 'FontSize', 10);
hold off;

% 添加标题
title('综合树结构可视化', 'FontSize', 16, 'FontWeight', 'bold');

% 修改轴的显示
axis off;
box off;

% 调整图形窗口大小以适应内容
set(gcf, 'Color', 'white');
set(gca, 'Position', [0.1 0.1 0.8 0.8]);

end