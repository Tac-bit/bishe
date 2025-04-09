function [spliced_info] = simple_splice(filtered_adj_mat_copy, tree_nodes, node_depths, n, spliced_tree_nodes)
% 简单拼接规则实现
% 输入:
%   filtered_adj_mat_copy: 特殊过滤后的邻接矩阵
%   tree_nodes: 骨干树节点集合
%   node_depths: 节点深度数组
%   n: 节点总数
%   spliced_tree_nodes: 拼接树的节点集合（用于判断邻居节点是否属于拼接树）
% 输出:
%   spliced_info: 拼接信息结构体

% 查找深度为2的节点和它们的度
depth2_nodes = [];
for node = 1:n
    if ismember(node, tree_nodes) && node_depths(node) == 2
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
    % 获取邻居节点 - 使用特殊过滤后的邻接矩阵
    neighbors = find(filtered_adj_mat_copy(node, :) > 0);
    if ~isempty(neighbors)
        % 遍历邻居节点
        for j = 1:length(neighbors)
            neighbor = neighbors(j);
            % 检查该邻居是否已被其他深度为2的节点连接，且不属于拼接树节点
            if ~ismember(node, neighbor_connected{neighbor}) && ~ismember(neighbor, spliced_tree_nodes)
                % 记录连接
                neighbor_connected{neighbor} = [neighbor_connected{neighbor}, node];
                % 添加拼接边
                source_points = [source_points, node];
                target_points = [target_points, neighbor];
                edge_weights = [edge_weights, filtered_adj_mat_copy(node, neighbor)];
                % 将邻居节点添加到拼接深度3节点集合
                if ~ismember(neighbor, spliced_depth3_nodes)
                    spliced_depth3_nodes = [spliced_depth3_nodes, neighbor];
                end
            end
        end
    end
end

% 将拼接边信息存储到结构体中
spliced_info = struct('nodes', depth2_nodes(:, 1), ...
                     'edges', [source_points', target_points'], ...
                     'weights', edge_weights', ...
                     'depth3_nodes', sort(spliced_depth3_nodes)');  % 对拼接深度3节点进行升序排序

% 打印拼接得到的深度为3的节点信息
fprintf('\n拼接—深度3：');
if ~isempty(spliced_depth3_nodes)
    fprintf('%d ', sort(spliced_depth3_nodes));  % 打印时也使用排序后的节点
    fprintf('（共%d个节点）\n', length(spliced_depth3_nodes));
else
    fprintf('无（共0个节点）\n');
end
end 