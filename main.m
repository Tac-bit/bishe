% main.m - Metro拓扑网络参数设置与函数调用
% 清空工作区和关闭所有图形窗口
clear all;
close all;

% 设置随机种子，确保结果可复现
rng(40);  % 使用固定随机种子

% 参数设置
threshold = 40; % 带宽阈值，低于此值的边将被过滤
source_node = 18; % 源节点（中心节点）

% 获取邻接矩阵和统计信息
[adj_mat, mean_weight, std_weight] = Metro1(source_node);

% 调用可视化函数显示原始拓扑图
visualize_metro_graph(adj_mat, source_node, mean_weight, std_weight);

% 过滤邻接矩阵
[filtered_adj_mat, filtered_mean_weight, filtered_std_weight] = Metro_filter(adj_mat, threshold, source_node);

% 显示过滤后的拓扑图
visualize_filtered_graph(filtered_adj_mat, threshold, source_node, filtered_mean_weight, filtered_std_weight);

% 显示高亮过滤边在原拓扑上的效果
highlight_filtered_edges(adj_mat, filtered_adj_mat, threshold, source_node, filtered_mean_weight, filtered_std_weight);

% 生成并显示平衡二叉树（基于过滤后的拓扑）
[tree_mat, tree_edges] = build_balanced_tree(filtered_adj_mat, source_node);
visualize_balanced_tree(tree_mat, tree_edges, source_node);

% 在过滤拓扑上高亮显示平衡二叉树
visualize_tree_on_filtered(filtered_adj_mat, tree_mat, tree_edges, threshold, source_node);

% 修剪平衡二叉树
[pruned_tree_mat, pruned_paths] = prune_balanced_tree(tree_mat, tree_edges, source_node);

% 显示修剪后的骨干树
visualize_pruned_tree(pruned_tree_mat, pruned_paths, source_node);

% 在过滤拓扑上高亮显示修剪后的骨干树
visualize_tree_on_filtered(filtered_adj_mat, pruned_tree_mat, pruned_paths, threshold, source_node);

% 分析修剪后的骨干树并进行特殊过滤
[filtered_adj_mat_copy, tree_nodes, depth_stats, depth_info, spliced_depth_info, simple_spliced_info, secondary_spliced_info] = analyze_pruned_tree(pruned_tree_mat, pruned_paths, source_node, filtered_adj_mat);

% 可视化结果
visualize_tree(filtered_adj_mat_copy, depth_info, spliced_depth_info, simple_spliced_info);

% 综合可视化所有树结构
% 使用正确的参数顺序调用
visualize_all_trees(filtered_adj_mat, depth_info, spliced_depth_info, simple_spliced_info, pruned_tree_mat, secondary_spliced_info);

% 打印各种树结构的节点和边信息汇总
print_tree_summary(filtered_adj_mat, tree_nodes, depth_info, spliced_depth_info, simple_spliced_info, secondary_spliced_info, source_node, pruned_paths);

% ===================== 可视化综合树结构 =====================
% 可视化综合树结构 (包含所有节点和边)
fprintf('\n正在生成综合树可视化...\n');
visualize_integrated_tree(filtered_adj_mat, tree_nodes, depth_info, spliced_depth_info, simple_spliced_info, secondary_spliced_info, source_node, pruned_paths);
fprintf('综合树可视化完成!\n');

% ===================== 计算树的性能和数据汇聚时间 =====================
fprintf('\n开始计算树的性能和数据汇聚时间...\n');

% 设置数据大小和汇聚时间参数
data_size = 1000;  % 数据大小单位可为MB或KB
gather_time = 5;   % 数据汇聚固定时间，单位可为ms或s

% 调用函数计算树的性能和数据汇聚时间
[node_times, total_time] = calculate_tree_performance(filtered_adj_mat, tree_nodes, depth_info, spliced_depth_info, simple_spliced_info, secondary_spliced_info, source_node, pruned_paths, data_size, gather_time);

fprintf('树的性能和数据汇聚时间计算完成!\n');
fprintf('源节点 %d 的数据汇聚总时间: %.2f\n', source_node, total_time);

% ===================== 可视化带时间信息的综合树结构 =====================
fprintf('\n正在生成带时间信息的综合树可视化...\n');
visualize_integrated_tree(filtered_adj_mat, tree_nodes, depth_info, spliced_depth_info, simple_spliced_info, secondary_spliced_info, source_node, pruned_paths, node_times);
fprintf('带时间信息的综合树可视化完成!\n');



