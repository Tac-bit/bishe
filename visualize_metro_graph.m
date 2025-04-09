function visualize_metro_graph(adj_mat, source_node, mean_weight, std_weight)
% 可视化Metro拓扑图的函数
% 输入:
%   adj_mat: 带权重的邻接矩阵
%   source_node: 源节点（特殊标记的节点）
%   mean_weight: 边权值的均值
%   std_weight: 边权值的标准差

% 创建图对象
G = graph(adj_mat);

% 创建新的图形窗口
figure('Name', 'Metro拓扑图', 'Position', [100, 100, 1000, 800]);

% 计算自定义布局
% 使用圆形布局作为初始布局
theta = linspace(0, 2*pi, numnodes(G)+1);
theta = theta(1:end-1);
x = cos(theta);
y = sin(theta);
layout = [x', y'];

% 预先设置节点位置（使用圆形布局作为初始布局）
G.Nodes.x = layout(:,1);
G.Nodes.y = layout(:,2);

% 绘制拓扑图
p = plot(G, 'Layout', 'force',...
    'UseGravity', true, ...
    'NodeColor', [0.6 0.6 0.6], ...  % 浅灰色节点
    'MarkerSize', 8, ...             % 增大节点尺寸
    'EdgeColor', [0.3 0.3 0.3], ...  % 深灰色边
    'LineWidth', 2.0, ...            % 加粗边线
    'EdgeAlpha', 0.7, ...            % 边透明度
    'Iterations', 100);              % 增加迭代次数

% 显示节点标签
labelnode(p, 1:numnodes(G), 1:numnodes(G));

% 高亮源节点（通常是18号节点）
highlight(p, [source_node], 'NodeColor', [0.9 0.2 0.2], 'MarkerSize', 12);  % 红色，大尺寸

% 在边上显示权重
labeledge(p, 1:numedges(G), G.Edges.Weight);
% 调整边标签文本属性以提高可读性
edge_labels = findobj(gca, 'Type', 'text');
set(edge_labels, 'FontWeight', 'bold', 'FontSize', 8, 'BackgroundColor', [1 1 1 0.7]);

% 添加标题（包含统计信息）
title_str = sprintf('Metro拓扑图（边权值均值: %.1f, 标准差: %.1f）', mean_weight, std_weight);
title(title_str, 'FontSize', 16, 'FontWeight', 'bold');

% 修改轴的显示
axis off;
box off;

% 调整图形窗口大小以适应内容
set(gcf, 'Color', 'white');
set(gca, 'Position', [0.1 0.1 0.8 0.8]);
end 