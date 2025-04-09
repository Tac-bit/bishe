function visualize_spliced_tree(filtered_adj_mat, tree_mat, tree_edges, threshold, source_node, spliced_info)
% 在过滤拓扑上高亮显示平衡二叉树和拼接边
% 输入:
%   filtered_adj_mat: 过滤后的邻接矩阵
%   tree_mat: 平衡二叉树的邻接矩阵
%   tree_edges: 平衡二叉树的边列表
%   threshold: 带宽阈值
%   source_node: 源节点编号
%   spliced_info: 拼接边信息结构体，包含depth3_nodes

% 创建原始过滤拓扑的副本，以免修改原始数据
original_filtered_mat = filtered_adj_mat;

% 创建图对象（使用原始过滤后的邻接矩阵）
G = graph(original_filtered_mat);

% 创建新图形窗口
figure('Name', '拼接树可视化效果', 'Position', [100, 100, 1000, 800]);

% 绘制原始过滤后的拓扑图
p = plot(G, 'Layout', 'force',...
    'UseGravity', true, ...
    'NodeColor', [0.6 0.6 0.6], ...  % 浅灰色节点
    'MarkerSize', 8, ...             % 增大节点尺寸
    'EdgeColor', [0.3 0.3 0.3], ...  % 深灰色边
    'LineWidth', 1.0, ...            % 细边线
    'EdgeAlpha', 0.3, ...            % 边透明度
    'Iterations', 100);              % 增加迭代次数

% 显示节点标签
labelnode(p, 1:numnodes(G), 1:numnodes(G));

% 高亮显示源节点
highlight(p, source_node, 'NodeColor', [0.9 0.2 0.2], 'MarkerSize', 12);  % 红色，大尺寸

% 获取骨干树中的所有节点
if iscell(tree_edges)
    % 如果是元胞数组（pruned_paths），直接合并所有元素
    tree_nodes = unique(cell2mat(tree_edges));
else
    % 如果是矩阵（tree_edges），提取起点和终点
    tree_nodes = unique([tree_edges(:,1); tree_edges(:,2)]);
end

% 计算骨干树节点的深度
n = size(original_filtered_mat, 1);
node_depths = -ones(n, 1);  % 初始化所有节点深度为-1
node_depths(source_node) = 0;  % 源节点深度为0

% BFS计算深度
queue = source_node;
visited = false(n, 1);
visited(source_node) = true;

while ~isempty(queue)
    current = queue(1);
    queue(1) = [];
    
    % 获取当前节点的邻居
    neighbors = find(tree_mat(current, :) > 0);
    
    for neighbor = neighbors
        if ~visited(neighbor)
            visited(neighbor) = true;
            node_depths(neighbor) = node_depths(current) + 1;
            queue = [queue, neighbor];
        end
    end
end

% 获取拼接的深度3节点（深度为2节点的邻居）
spliced_depth3_nodes = spliced_info.depth3_nodes;

% 设置不同深度节点的颜色
for node = 1:n
    if ismember(node, tree_nodes) && node ~= source_node
        degree = sum(original_filtered_mat(node, :) > 0);
        if degree > 0
            switch node_depths(node)
                case 1
                    highlight(p, node, 'NodeColor', [0.5 0 0.5]);  % 深度1为紫色
                case 2
                    highlight(p, node, 'NodeColor', [0 0.5 0]);    % 深度2为绿色
                case 3
                    highlight(p, node, 'NodeColor', 'blue');       % 深度3为蓝色
            end
        end
    elseif ismember(node, spliced_depth3_nodes)
        highlight(p, node, 'NodeColor', 'blue');  % 拼接的深度3节点也为蓝色
    end
end

% 高亮显示骨干树的边
[row, col] = find(tree_mat > 0);
for i = 1:length(row)
    highlight(p, [row(i) col(i)], 'EdgeColor', 'b', 'LineWidth', 2.0);
end

% 高亮显示拼接边
if ~isempty(spliced_info.edges)
    for i = 1:size(spliced_info.edges, 1)
        source = spliced_info.edges(i, 1);
        target = spliced_info.edges(i, 2);
        highlight(p, [source target], 'EdgeColor', 'red', 'LineWidth', 2.0);
    end
end

% 计算骨干树的边数量
tree_edges_count = nnz(tree_mat)/2;
% 计算拼接边数量
spliced_edges_count = size(spliced_info.edges, 1);

% 显示边权值（保留整数）
labeledge(p, 1:numedges(G), round(G.Edges.Weight));

% 调整边标签文本属性以提高可读性
edge_labels = findobj(gca, 'Type', 'text');
set(edge_labels, 'FontWeight', 'bold', 'FontSize', 8, 'BackgroundColor', [1 1 1 0.7]);

% 添加标题
title(sprintf('拼接树可视化效果 (带宽阈值=%d)\n骨干树边数=%d, 拼接边数=%d', ...
    round(threshold), tree_edges_count, spliced_edges_count), ...
    'FontSize', 16, 'FontWeight', 'bold');

% 修改轴的显示
axis off;
box off;

% 调整图形窗口大小以适应内容
set(gcf, 'Color', 'white');
set(gca, 'Position', [0.1 0.1 0.8 0.8]);
end 