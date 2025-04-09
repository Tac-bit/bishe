function visualize_pruned_tree(pruned_tree_mat, pruned_paths, source_node)
% 可视化修剪后的骨干树
% 输入:
%   pruned_tree_mat: 修剪后的骨干树邻接矩阵
%   pruned_paths: 修剪后的路径集合
%   source_node: 源节点编号

% 创建图对象
G = graph(pruned_tree_mat);

% 创建图形窗口
figure('Name', '修剪后的骨干树', 'Position', [100, 100, 1000, 800]);

% 绘制拓扑图
h = plot(G, 'Layout', 'force',...
    'UseGravity', true, ...
    'NodeColor', [0.6 0.6 0.6], ...  % 浅灰色节点
    'MarkerSize', 8, ...             % 节点尺寸
    'EdgeColor', [0.3 0.3 0.3], ...  % 深灰色边
    'LineWidth', 2.0, ...            % 边线宽度
    'EdgeAlpha', 0.7, ...            % 边透明度
    'Iterations', 100);              % 迭代次数

% 高亮源节点
highlight(h, source_node, 'NodeColor', [0.9 0.2 0.2], 'MarkerSize', 12);  % 红色，大尺寸

% 显示边权重
if ~isempty(G.Edges)
    % 获取所有边的权重
    [s, t] = findedge(G);
    weights = full(pruned_tree_mat(sub2ind(size(pruned_tree_mat), s, t)));
    
    % 为每条边添加标签
    for i = 1:length(s)
        if weights(i) > 0
            labeledge(h, s(i), t(i), sprintf('%d', round(weights(i))));
        end
    end
end

% 调整边标签文本属性
edge_labels = findobj(gca, 'Type', 'text');
set(edge_labels, 'FontWeight', 'bold', 'FontSize', 8, 'BackgroundColor', [1 1 1 0.7]);

% 显示节点编号
labelnode(h, 1:numel(G.Nodes), arrayfun(@num2str, 1:numel(G.Nodes), 'UniformOutput', false));

% 添加标题
title('修剪后的骨干树', 'FontSize', 16, 'FontWeight', 'bold');

% 修改轴的显示
axis off;
box off;

% 调整图形窗口大小以适应内容
set(gcf, 'Color', 'white');
set(gca, 'Position', [0.1 0.1 0.8 0.8]);

end 