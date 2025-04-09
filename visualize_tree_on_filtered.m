function visualize_tree_on_filtered(filtered_adj_mat, tree_mat, tree_edges, threshold, source_node)
% 在过滤拓扑上高亮显示平衡二叉树
% 输入:
%   filtered_adj_mat: 过滤后的邻接矩阵
%   tree_mat: 平衡二叉树的邻接矩阵
%   tree_edges: 平衡二叉树的边列表
%   threshold: 带宽阈值
%   source_node: 源节点编号

% 创建图对象（使用过滤后的邻接矩阵）
G = graph(filtered_adj_mat);

% 创建新图形窗口
figure('Name', '平衡二叉树在过滤拓扑上的效果', 'Position', [100, 100, 1000, 800]);

% 绘制过滤后的拓扑图
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

% 高亮显示平衡二叉树的边
[row, col] = find(tree_mat > 0);
for i = 1:length(row)
    highlight(p, [row(i) col(i)], 'EdgeColor', 'b', 'LineWidth', 2.0);
end

% 计算平衡二叉树的边数量
tree_edges_count = nnz(tree_mat)/2;

% 显示边权值（保留整数）
labeledge(p, 1:numedges(G), round(G.Edges.Weight));

% 调整边标签文本属性以提高可读性
edge_labels = findobj(gca, 'Type', 'text');
set(edge_labels, 'FontWeight', 'bold', 'FontSize', 8, 'BackgroundColor', [1 1 1 0.7]);

% 添加标题
title(sprintf('平衡二叉树在过滤拓扑上的效果 (带宽阈值=%d)\n平衡二叉树边数=%d', ...
    round(threshold), tree_edges_count), ...
    'FontSize', 16, 'FontWeight', 'bold');

% 修改轴的显示
axis off;
box off;

% 调整图形窗口大小以适应内容
set(gcf, 'Color', 'white');
set(gca, 'Position', [0.1 0.1 0.8 0.8]);
end 