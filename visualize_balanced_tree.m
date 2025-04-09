function visualize_balanced_tree(tree_mat, tree_edges, source_node)
% 可视化平衡二叉树
% 输入:
%   tree_mat: 平衡二叉树的邻接矩阵
%   tree_edges: 平衡二叉树的边列表
%   source_node: 源节点编号

% 创建图对象（只使用平衡二叉树的边）
G = graph(tree_edges(:,1), tree_edges(:,2), tree_mat(sub2ind(size(tree_mat), tree_edges(:,1), tree_edges(:,2))));

% 创建新图形窗口
figure('Name', '平衡二叉树', 'Position', [100, 100, 1000, 800]);

% 绘制平衡二叉树
p = plot(G, 'Layout', 'force',...
    'UseGravity', true, ...
    'NodeColor', [0.6 0.6 0.6], ...  % 浅灰色节点
    'MarkerSize', 8, ...             % 增大节点尺寸
    'EdgeColor', 'b', ...            % 蓝色边
    'LineWidth', 2.0, ...            % 粗边线
    'Iterations', 100);              % 增加迭代次数

% 显示节点标签
labelnode(p, 1:numnodes(G), 1:numnodes(G));

% 高亮显示源节点
highlight(p, source_node, 'NodeColor', [0.9 0.2 0.2], 'MarkerSize', 12);  % 红色，大尺寸

% 显示边权值（保留整数）
labeledge(p, 1:numedges(G), round(G.Edges.Weight));

% 调整边标签文本属性以提高可读性
edge_labels = findobj(gca, 'Type', 'text');
set(edge_labels, 'FontWeight', 'bold', 'FontSize', 8, 'BackgroundColor', [1 1 1 0.7]);

% 添加标题
title('平衡二叉树', 'FontSize', 16, 'FontWeight', 'bold');

% 修改轴的显示
axis off;
box off;

% 调整图形窗口大小以适应内容
set(gcf, 'Color', 'white');
set(gca, 'Position', [0.1 0.1 0.8 0.8]);
end 