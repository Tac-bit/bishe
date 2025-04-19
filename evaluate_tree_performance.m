function [node_times, total_time] = evaluate_tree_performance(filtered_adj_mat, all_nodes, all_edges, node_depths, source_node, data_size, gather_time)
% evaluate_tree_performance - 计算树的性能和数据汇聚时间
%
% 输入参数:
%   filtered_adj_mat - 过滤后的邻接矩阵
%   all_nodes - 树中的所有节点
%   all_edges - 树中的所有边 [n,2]格式
%   node_depths - 所有节点的深度
%   source_node - 源节点
%   data_size - 数据大小
%   gather_time - 固定汇聚时间
%
% 输出参数:
%   node_times - 每个节点的数据汇聚时间
%   total_time - 整个树的数据汇聚总时间

fprintf('正在评估树的性能和计算数据汇聚时间...\n');

% 获取节点数量
n = size(filtered_adj_mat, 1);

% 初始化节点时间数组
node_times = zeros(n, 1);
processed = false(n, 1);

% 构建邻接列表以确定每个节点的度
adj_list = cell(n, 1);
node_degrees = zeros(n, 1);
for i = 1:size(all_edges, 1)
    node1 = all_edges(i, 1);
    node2 = all_edges(i, 2);
    
    adj_list{node1} = [adj_list{node1}, node2];
    adj_list{node2} = [adj_list{node2}, node1];
    
    node_degrees(node1) = node_degrees(node1) + 1;
    node_degrees(node2) = node_degrees(node2) + 1;
end

% 找出所有叶子节点（度为1的非源节点）
leaf_nodes = [];
for i = all_nodes'
    if i ~= source_node && node_degrees(i) == 1
        leaf_nodes = [leaf_nodes; i];
        node_times(i) = 0;  % 叶子节点的初始时间为0
        processed(i) = true;
    end
end

fprintf('找到 %d 个叶子节点\n', length(leaf_nodes));

% 构建父子关系
children = cell(n, 1);
parents = zeros(n, 1);

for i = 1:size(all_edges, 1)
    node1 = all_edges(i, 1);
    node2 = all_edges(i, 2);
    
    % 根据深度确定父子关系
    if node_depths(node1) < node_depths(node2)
        parents(node2) = node1;
        children{node1} = [children{node1}, node2];
    else
        parents(node1) = node2;
        children{node2} = [children{node2}, node1];
    end
end

% 从叶子节点开始，计算每个节点的数据汇聚时间
fprintf('\n计算每个节点的数据汇聚时间:\n');
% 使用完整的表头文字，同时确保表格数据对齐
fprintf('%-5s|%-6s|%-10s|%-10s|%-10s|%-10s\n', '节点', '深度', '子节点数', '传输时间', '汇聚时间', '总时间');
fprintf('%-5s+%-6s+%-10s+%-10s+%-10s+%-10s\n', '-----', '------', '----------', '----------', '----------', '----------');

max_depth = max(node_depths);
for d = max_depth:-1:1
    % 处理当前深度的节点
    current_level_nodes = all_nodes(node_depths(all_nodes) == d);
    
    for node = current_level_nodes'
        if ~processed(node)
            child_nodes = children{node};
            parent_node = parents(node);
            
            % 如果有子节点，需要计算子节点到当前节点的最大传输时间
            if ~isempty(child_nodes)
                max_transmission_time = 0;
                child_count = 0;
                
                for child = child_nodes
                    if processed(child)
                        child_count = child_count + 1;
                        
                        % 获取边权重
                        weight = filtered_adj_mat(node, child);
                        if weight == 0
                            weight = filtered_adj_mat(child, node);
                        end
                        
                        % 计算传输时间 = 子节点累积时间 + 当前边的传输时间
                        transmission_time = node_times(child) + (data_size / weight);
                        
                        % 更新最大传输时间
                        if transmission_time > max_transmission_time
                            max_transmission_time = transmission_time;
                        end
                    end
                end
                
                % 根据子节点数量决定是否需要添加汇聚时间
                needs_aggregation = child_count > 1;
                
                if needs_aggregation
                    total_time_value = max_transmission_time + gather_time;
                    gather_time_value = gather_time;
                else
                    total_time_value = max_transmission_time;
                    gather_time_value = 0;
                end
                
                node_times(node) = total_time_value;
                
                % 打印节点信息，确保与表头对齐
                fprintf('%-5d|%-6d|%-10d|%-10.2f|%-10.2f|%-10.2f\n', ...
                    node, node_depths(node), child_count, ...
                    max_transmission_time, gather_time_value, total_time_value);
            else
                % 如果没有子节点但不是叶子节点（不应该出现这种情况）
                fprintf('警告: 节点 %d 不是叶子节点但没有子节点\n', node);
                node_times(node) = 0;
            end
            
            processed(node) = true;
        end
    end
end

% 最后处理源节点
if ~processed(source_node)
    child_nodes = children{source_node};
    child_count = length(child_nodes);
    
    % 计算子节点的最大传输时间
    max_transmission_time = 0;
    for child = child_nodes
        if processed(child)
            weight = filtered_adj_mat(source_node, child);
            if weight == 0
                weight = filtered_adj_mat(child, source_node);
            end
            
            transmission_time = node_times(child) + (data_size / weight);
            
            if transmission_time > max_transmission_time
                max_transmission_time = transmission_time;
            end
        end
    end
    
    % 决定是否需要添加汇聚时间
    needs_aggregation = child_count > 1;
    
    if needs_aggregation
        total_time_value = max_transmission_time + gather_time;
        gather_time_value = gather_time;
    else
        total_time_value = max_transmission_time;
        gather_time_value = 0;
    end
    
    node_times(source_node) = total_time_value;
    
    % 打印源节点信息，确保与表头对齐
    fprintf('%-5d|%-6d|%-10d|%-10.2f|%-10.2f|%-10.2f\n', ...
        source_node, 0, child_count, ...
        max_transmission_time, gather_time_value, total_time_value);
    
    processed(source_node) = true;
end

% 计算总时间
total_time = node_times(source_node);

% 找出关键路径
[critical_path, critical_path_time] = find_critical_path(node_times, children, filtered_adj_mat, source_node, data_size, gather_time);

fprintf('\n关键路径分析:\n');
fprintf('关键路径时间: %.2f\n', critical_path_time);
fprintf('关键路径: ');
fprintf('%d -> ', critical_path(1:end-1));
fprintf('%d\n', critical_path(end));

% 打印汇总信息
fprintf('\n汇总信息:\n');
fprintf('总节点数: %d\n', length(all_nodes));
fprintf('叶子节点数: %d\n', length(leaf_nodes));
fprintf('数据大小: %.0f\n', data_size);
fprintf('固定汇聚时间: %.0f\n', gather_time);
fprintf('源节点: %d\n', source_node);
fprintf('数据汇聚总时间: %.2f\n', total_time);

end

function [critical_path, critical_path_time] = find_critical_path(node_times, children, filtered_adj_mat, source_node, data_size, gather_time)
% find_critical_path - 找出从叶子节点到源节点的关键路径
%
% 输入参数:
%   node_times - 每个节点的数据汇聚时间
%   children - 子节点关系
%   filtered_adj_mat - 过滤后的邻接矩阵
%   source_node - 源节点
%   data_size - 数据大小
%   gather_time - 固定汇聚时间
%
% 输出参数:
%   critical_path - 关键路径上的节点
%   critical_path_time - 关键路径时间

n = length(node_times);
current_node = source_node;
critical_path = [current_node];
critical_path_time = node_times(source_node);

% 遍历子节点，找出贡献最大延迟的路径
while ~isempty(children{current_node})
    child_nodes = children{current_node};
    max_time = -1;
    max_child = -1;
    
    for child = child_nodes
        weight = filtered_adj_mat(current_node, child);
        if weight == 0
            weight = filtered_adj_mat(child, current_node);
        end
        
        % 这个子节点的贡献 = 子节点的累积时间 + 传输时间
        transmission_time = node_times(child) + (data_size / weight);
        
        if transmission_time > max_time
            max_time = transmission_time;
            max_child = child;
        end
    end
    
    if max_child ~= -1
        critical_path = [max_child, critical_path];
        current_node = max_child;
    else
        break;
    end
end

end 