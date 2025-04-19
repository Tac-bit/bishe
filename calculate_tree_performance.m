function [node_times, total_time] = calculate_tree_performance(filtered_adj_mat, tree_nodes, depth_info, spliced_depth_info, simple_spliced_info, secondary_spliced_info, source_node, pruned_paths, data_size, gather_time)
% calculate_tree_performance - 封装函数，用于计算树的性能和数据汇聚时间
%
% 输入参数:
%   filtered_adj_mat - 过滤后的邻接矩阵
%   tree_nodes - 骨干树包含的所有节点
%   depth_info - 包含不同深度节点的结构体
%   spliced_depth_info - 拼接骨干树的深度节点信息结构体
%   simple_spliced_info - 简单拼接的信息结构体
%   secondary_spliced_info - 次级拼接的信息结构体
%   source_node - 源节点编号
%   pruned_paths - 修剪后的路径集合
%   data_size - 要传输的数据大小
%   gather_time - 数据汇聚所需的固定时间
%
% 输出参数:
%   node_times - 每个节点的数据汇聚时间
%   total_time - 整个树的数据汇聚总时间

% 收集综合树中的所有节点和边信息
n = size(filtered_adj_mat, 1);
node_depths = -ones(n, 1);  % 初始化所有节点深度为-1
node_depths(source_node) = 0;  % 源节点深度为0

% 构建综合树的邻接矩阵
integrated_adj_mat = zeros(n);
all_edges = [];  % 存储所有边的信息

% 从骨干树中提取边
if exist('pruned_paths', 'var') && ~isempty(pruned_paths)
    for i = 1:length(pruned_paths)
        path = pruned_paths{i};
        for j = 1:length(path)-1
            edge = sort([path(j), path(j+1)]);
            edge = reshape(edge, 1, 2);
            
            % 检查是否已经存在
            is_new_edge = true;
            if ~isempty(all_edges)
                for k = 1:size(all_edges, 1)
                    if all(all_edges(k,:) == edge)
                        is_new_edge = false;
                        break;
                    end
                end
            end
            
            if is_new_edge
                all_edges = [all_edges; edge];
                integrated_adj_mat(edge(1), edge(2)) = filtered_adj_mat(edge(1), edge(2));
                integrated_adj_mat(edge(2), edge(1)) = filtered_adj_mat(edge(2), edge(1));
            end
        end
    end
end

% 从拼接骨干树中提取边
if isfield(spliced_depth_info, 'tree_edges') && ~isempty(spliced_depth_info.tree_edges)
    for i = 1:size(spliced_depth_info.tree_edges, 1)
        edge = sort(spliced_depth_info.tree_edges(i, :));
        if length(edge) == 2
            edge = reshape(edge, 1, 2);
            
            % 检查是否已经存在
            is_new_edge = true;
            if ~isempty(all_edges)
                for k = 1:size(all_edges, 1)
                    if all(all_edges(k,:) == edge)
                        is_new_edge = false;
                        break;
                    end
                end
            end
            
            if is_new_edge
                all_edges = [all_edges; edge];
                integrated_adj_mat(edge(1), edge(2)) = filtered_adj_mat(edge(1), edge(2));
                integrated_adj_mat(edge(2), edge(1)) = filtered_adj_mat(edge(2), edge(1));
            end
        end
    end
end

% 从简单拼接信息中提取边
if isfield(simple_spliced_info, 'edges') && ~isempty(simple_spliced_info.edges)
    for i = 1:size(simple_spliced_info.edges, 1)
        edge = sort(simple_spliced_info.edges(i, :));
        if length(edge) == 2
            edge = reshape(edge, 1, 2);
            
            % 检查是否已经存在
            is_new_edge = true;
            if ~isempty(all_edges)
                for k = 1:size(all_edges, 1)
                    if all(all_edges(k,:) == edge)
                        is_new_edge = false;
                        break;
                    end
                end
            end
            
            if is_new_edge
                all_edges = [all_edges; edge];
                integrated_adj_mat(edge(1), edge(2)) = filtered_adj_mat(edge(1), edge(2));
                integrated_adj_mat(edge(2), edge(1)) = filtered_adj_mat(edge(2), edge(1));
            end
        end
    end
end

% 从次级拼接信息中提取边
if isfield(secondary_spliced_info, 'edges') && ~isempty(secondary_spliced_info.edges)
    for i = 1:size(secondary_spliced_info.edges, 1)
        edge = sort(secondary_spliced_info.edges(i, :));
        if length(edge) == 2
            edge = reshape(edge, 1, 2);
            
            % 检查是否已经存在
            is_new_edge = true;
            if ~isempty(all_edges)
                for k = 1:size(all_edges, 1)
                    if all(all_edges(k,:) == edge)
                        is_new_edge = false;
                        break;
                    end
                end
            end
            
            if is_new_edge
                all_edges = [all_edges; edge];
                integrated_adj_mat(edge(1), edge(2)) = filtered_adj_mat(edge(1), edge(2));
                integrated_adj_mat(edge(2), edge(1)) = filtered_adj_mat(edge(2), edge(1));
            end
        end
    end
end

% 使用BFS计算深度
queue = source_node;
visited = false(n, 1);
visited(source_node) = true;

while ~isempty(queue)
    current = queue(1);
    queue(1) = [];
    
    % 获取当前节点的邻居
    neighbors = find(integrated_adj_mat(current, :) > 0);
    
    for neighbor = neighbors
        if ~visited(neighbor)
            visited(neighbor) = true;
            node_depths(neighbor) = node_depths(current) + 1;
            queue = [queue, neighbor];
        end
    end
end

% 获取所有在综合树中的节点
all_nodes = find(node_depths >= 0);

% 调用性能评估函数
[node_times, total_time] = evaluate_tree_performance(filtered_adj_mat, all_nodes, all_edges, node_depths, source_node, data_size, gather_time);

end 