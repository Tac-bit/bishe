% main.m - Metro拓扑网络参数设置与函数调用
% 清空工作区和关闭所有图形窗口
clear all;
close all;

% 设置随机种子，确保结果可复现
rng(36);  % 使用固定随机种子

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
[filtered_adj_mat_copy, tree_nodes, depth_stats, depth_info, spliced_depth_info, simple_spliced_info] = analyze_pruned_tree(pruned_tree_mat, pruned_paths, source_node, filtered_adj_mat);

% 可视化结果
visualize_tree(filtered_adj_mat_copy, depth_info, spliced_depth_info, simple_spliced_info);

% 综合可视化所有树结构
visualize_all_trees(filtered_adj_mat, depth_info, spliced_depth_info, simple_spliced_info, pruned_tree_mat);

