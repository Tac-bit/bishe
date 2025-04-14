function [spliced_info] = spliced_simple_splice(filtered_adj_mat_copy, spliced_tree_nodes, spliced_node_depths, n)
% 拼接骨干树上的简单拼接规则实现
% 输入:
%   filtered_adj_mat_copy: 特殊过滤后的邻接矩阵
%   spliced_tree_nodes: 拼接骨干树的节点集合
%   spliced_node_depths: 拼接骨干树节点深度数组
%   n: 节点总数
% 输出:
%   spliced_info: 拼接信息结构体
%       spliced_info.nodes: 拼接骨干树上的深度2节点
%       spliced_info.edges: 拼接边 [source_points, target_points]
%       spliced_info.weights: 边的权重
%       spliced_info.depth3_nodes: 拼接得到的深度3节点
%       spliced_info.all_spliced_nodes: 所有拼接得到的节点

% 查找拼接骨干树中深度为2的节点和它们的度
depth2_nodes = [];
for node = 1:n
    if ismember(node, spliced_tree_nodes) && spliced_node_depths(node) == 2
        % 计算在特殊过滤后邻接矩阵中的度
        degree = sum(filtered_adj_mat_copy(node, :) > 0);
        if degree > 0
            % 存储节点编号和度
            depth2_nodes = [depth2_nodes; node, degree];
        end
    end
end

% 对depth2_nodes按度排序（从小到大），如果度相同则按节点编号排序
if ~isempty(depth2_nodes)
    depth2_nodes = sortrows(depth2_nodes, [2 1]);
end

% 创建用于记录每个邻居节点已被连接的深度为2的节点
neighbor_connected = cell(n, 1);
for i = 1:n
    neighbor_connected{i} = [];
end

% 用于记录最终拼接边
source_points = [];
target_points = [];
edge_weights = [];
spliced_depth3_nodes = [];  % 存储拼接的深度3节点（即深度2节点的邻居）

% 遍历深度为2的节点（按度和节点编号排序后）
for i = 1:size(depth2_nodes, 1)
    node = depth2_nodes(i, 1);
    node_degree = depth2_nodes(i, 2);  % 当前节点的度
    % 获取邻居节点 - 使用特殊过滤后的邻接矩阵
    neighbors = find(filtered_adj_mat_copy(node, :) > 0);
    if ~isempty(neighbors)
        % 遍历邻居节点
        for j = 1:length(neighbors)
            neighbor = neighbors(j);
            % 检查该邻居是否已被其他深度为2的节点连接，且不属于拼接树节点
            if ~ismember(neighbor, spliced_tree_nodes)
                % 获取已连接该邻居的深度2节点
                connected_nodes = neighbor_connected{neighbor};
                if isempty(connected_nodes)
                    % 如果还没有节点连接该邻居，直接连接
                    neighbor_connected{neighbor} = [neighbor_connected{neighbor}, node];
                    % 添加拼接边
                    source_points = [source_points, node];
                    target_points = [target_points, neighbor];
                    edge_weights = [edge_weights, filtered_adj_mat_copy(node, neighbor)];
                    % 将邻居节点添加到拼接深度3节点集合
                    if ~ismember(neighbor, spliced_depth3_nodes)
                        spliced_depth3_nodes = [spliced_depth3_nodes, neighbor];
                        % 将拼接得到的节点标记为深度3
                        spliced_node_depths(neighbor) = 3;
                    end
                else
                    % 如果已有节点连接该邻居，比较度
                    % 找到已连接节点的度
                    connected_node_idx = find(depth2_nodes(:,1) == connected_nodes(1));
                    connected_node_degree = depth2_nodes(connected_node_idx, 2);
                    
                    % 如果当前节点的度更小，则替换连接
                    if node_degree < connected_node_degree
                        % 移除旧的连接
                        old_edge_idx = find(source_points == connected_nodes(1) & target_points == neighbor);
                        if ~isempty(old_edge_idx)
                            source_points(old_edge_idx) = [];
                            target_points(old_edge_idx) = [];
                            edge_weights(old_edge_idx) = [];
                        end
                        
                        % 添加新的连接
                        neighbor_connected{neighbor} = node;
                        source_points = [source_points, node];
                        target_points = [target_points, neighbor];
                        edge_weights = [edge_weights, filtered_adj_mat_copy(node, neighbor)];
                        
                        % 将邻居节点添加到拼接深度3节点集合
                        if ~ismember(neighbor, spliced_depth3_nodes)
                            spliced_depth3_nodes = [spliced_depth3_nodes, neighbor];
                            % 将拼接得到的节点标记为深度3
                            spliced_node_depths(neighbor) = 3;
                        end
                    end
                end
            end
        end
    end
end

% 将拼接边信息存储到结构体中
if ~isempty(depth2_nodes)
    spliced_info = struct('nodes', depth2_nodes(:, 1), ...
                         'edges', [source_points', target_points'], ...
                         'weights', edge_weights', ...
                         'depth3_nodes', sort(spliced_depth3_nodes(:)), ...  % 对拼接深度3节点进行升序排序
                         'all_spliced_nodes', sort(spliced_depth3_nodes(:)));  % 所有拼接得到的节点
else
    % 如果depth2_nodes为空，创建空的结构体
    spliced_info = struct('nodes', [], ...
                         'edges', [], ...
                         'weights', [], ...
                         'depth3_nodes', [], ...
                         'all_spliced_nodes', []);
end

% 创建深度2拼接信息子结构体
spliced_info.depth2_spliced_info = struct('spliced_nodes', spliced_depth3_nodes(:));
end 