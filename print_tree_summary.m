function print_tree_summary(filtered_adj_mat, tree_nodes, depth_info, spliced_depth_info, simple_spliced_info, secondary_spliced_info, source_node, pruned_paths)
% 打印综合树结构的节点和边信息汇总
% 输入:
%   filtered_adj_mat: 过滤后的邻接矩阵
%   tree_nodes: 骨干树包含的所有节点
%   depth_info: 包含不同深度节点的结构体 (从analyze_pruned_tree获取)
%   spliced_depth_info: 拼接骨干树的深度节点信息结构体 (从analyze_pruned_tree获取)
%   simple_spliced_info: 简单拼接的信息结构体 (从analyze_pruned_tree获取)
%   secondary_spliced_info: 次级拼接的信息结构体 (从analyze_pruned_tree获取)
%   source_node: 源节点编号
%   pruned_paths: 修剪后的路径集合 (从prune_balanced_tree直接获取)

% 确保tree_nodes是列向量
if size(tree_nodes, 1) == 1
    tree_nodes = tree_nodes';
end

fprintf('\n==================================================\n');
fprintf('               综合树信息汇总\n');
fprintf('==================================================\n\n');

% 收集所有节点和边信息
% 1. 从骨干树获取节点和边
backbone_nodes = [];
backbone_edges = [];

% 从pruned_paths中提取骨干树节点和边
if exist('pruned_paths', 'var') && ~isempty(pruned_paths)
    for i = 1:length(pruned_paths)
        path = pruned_paths{i};
        backbone_nodes = [backbone_nodes, path];
        
        % 提取路径中的边
        for j = 1:length(path)-1
            edge = sort([path(j), path(j+1)]);
            edge = reshape(edge, 1, 2);
            
            % 检查是否已经存在
            is_new_edge = true;
            if ~isempty(backbone_edges)
                for k = 1:size(backbone_edges, 1)
                    if all(backbone_edges(k,:) == edge)
                        is_new_edge = false;
                        break;
                    end
                end
            end
            
            if is_new_edge
                backbone_edges = [backbone_edges; edge];
            end
        end
    end
    backbone_nodes = unique(backbone_nodes)';
else
    backbone_nodes = tree_nodes;
end

% 2. 从拼接骨干树获取节点和边
spliced_nodes = [];
if isfield(spliced_depth_info, 'depth0_nodes')
    spliced_nodes = [spliced_nodes; spliced_depth_info.depth0_nodes(:)];
end
if isfield(spliced_depth_info, 'depth1_nodes')
    spliced_nodes = [spliced_nodes; spliced_depth_info.depth1_nodes(:)];
end
if isfield(spliced_depth_info, 'depth2_nodes')
    spliced_nodes = [spliced_nodes; spliced_depth_info.depth2_nodes(:)];
end
if isfield(spliced_depth_info, 'depth3_nodes')
    spliced_nodes = [spliced_nodes; spliced_depth_info.depth3_nodes(:)];
end
spliced_nodes = unique(spliced_nodes);

spliced_edges = [];
if isfield(spliced_depth_info, 'tree_edges') && ~isempty(spliced_depth_info.tree_edges)
    % 提取和整理边信息
    for i = 1:size(spliced_depth_info.tree_edges, 1)
        edge = spliced_depth_info.tree_edges(i, :);
        if length(edge) == 2
            edge = sort(edge);
            edge = reshape(edge, 1, 2);
            spliced_edges = [spliced_edges; edge];
        end
    end
end

% 3. 从拼接骨干树上的简单拼接获取节点和边
spliced_backbone_simple_nodes = [];
splice_edges = [];

if isfield(spliced_depth_info, 'simple_splice_info') && ~isempty(spliced_depth_info.simple_splice_info)
    splice_info = spliced_depth_info.simple_splice_info;
    
    % 获取拼接节点
    if isfield(splice_info, 'all_spliced_nodes')
        spliced_backbone_simple_nodes = splice_info.all_spliced_nodes;
    elseif isfield(splice_info, 'depth2_spliced_info') && isfield(splice_info.depth2_spliced_info, 'spliced_nodes')
        spliced_backbone_simple_nodes = splice_info.depth2_spliced_info.spliced_nodes;
    end
    
    % 处理边信息
    if isfield(splice_info, 'edges') && ~isempty(splice_info.edges)
        for i = 1:size(splice_info.edges, 1)
            edge = splice_info.edges(i, :);
            if length(edge) == 2
                edge = sort(edge);
                edge = reshape(edge, 1, 2);
                splice_edges = [splice_edges; edge];
            end
        end
    end
end

% 4. 从次级拼接获取节点和边
secondary_nodes = [];
secondary_edges = [];

if isfield(secondary_spliced_info, 'nodes') && ~isempty(secondary_spliced_info.nodes)
    % 收集次级拼接节点信息
    if isfield(secondary_spliced_info, 'depth1_nodes')
        secondary_nodes = [secondary_nodes; secondary_spliced_info.depth1_nodes(:)];
    end
    
    if isfield(secondary_spliced_info, 'depth2_nodes')
        secondary_nodes = [secondary_nodes; secondary_spliced_info.depth2_nodes(:)];
    end
    
    % 收集深度3节点
    if isfield(secondary_spliced_info, 'trees')
        for i = 1:length(secondary_spliced_info.trees)
            tree_info = secondary_spliced_info.trees{i};
            if isfield(tree_info, 'global_depth_info') && isfield(tree_info.global_depth_info, 'depth3_nodes')
                secondary_nodes = [secondary_nodes; tree_info.global_depth_info.depth3_nodes(:)];
            end
        end
    end
    secondary_nodes = unique(secondary_nodes);
    
    % 处理次级拼接边信息
    if isfield(secondary_spliced_info, 'edges') && ~isempty(secondary_spliced_info.edges)
        for i = 1:size(secondary_spliced_info.edges, 1)
            edge = secondary_spliced_info.edges(i, :);
            if length(edge) == 2
                edge = sort(edge);
                edge = reshape(edge, 1, 2);
                secondary_edges = [secondary_edges; edge];
            end
        end
    end
end

% 5. 从简单拼接获取节点和边
simple_nodes = [];
simple_edges = [];

if isfield(simple_spliced_info, 'all_spliced_nodes') && ~isempty(simple_spliced_info.all_spliced_nodes)
    simple_nodes = simple_spliced_info.all_spliced_nodes;
    
    % 处理简单拼接边信息
    if isfield(simple_spliced_info, 'edges') && ~isempty(simple_spliced_info.edges)
        for i = 1:size(simple_spliced_info.edges, 1)
            edge = simple_spliced_info.edges(i, :);
            if length(edge) == 2
                edge = sort(edge);
                edge = reshape(edge, 1, 2);
                simple_edges = [simple_edges; edge];
            end
        end
    end
end

% 合并所有节点和边信息
all_nodes = unique([backbone_nodes; spliced_nodes; spliced_backbone_simple_nodes; secondary_nodes; simple_nodes]);
all_edges_raw = [backbone_edges; spliced_edges; splice_edges; secondary_edges; simple_edges];

% 去除重复边
all_edges = [];
for i = 1:size(all_edges_raw, 1)
    edge = all_edges_raw(i, :);
    
    % 检查是否已存在
    is_new_edge = true;
    if ~isempty(all_edges)
        for j = 1:size(all_edges, 1)
            if all(all_edges(j,:) == edge)
                is_new_edge = false;
                break;
            end
        end
    end
    
    if is_new_edge
        all_edges = [all_edges; edge];
    end
end

% ===================== 按深度输出节点信息 =====================
fprintf('【综合树信息】\n');
fprintf('总节点数: %d\n', length(all_nodes));
fprintf('总边数: %d\n', size(all_edges, 1));

% 计算所有节点的深度
n = size(filtered_adj_mat, 1);
node_depths = -ones(n, 1);  % 初始化所有节点深度为-1
node_depths(source_node) = 0;  % 源节点深度为0

% 构建综合树的邻接矩阵
integrated_adj_mat = zeros(n);
for i = 1:size(all_edges, 1)
    node1 = all_edges(i, 1);
    node2 = all_edges(i, 2);
    integrated_adj_mat(node1, node2) = filtered_adj_mat(node1, node2);
    integrated_adj_mat(node2, node1) = filtered_adj_mat(node2, node1);
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

% 按深度分类节点
depth0_nodes = all_nodes(node_depths(all_nodes) == 0);
depth1_nodes = all_nodes(node_depths(all_nodes) == 1);
depth2_nodes = all_nodes(node_depths(all_nodes) == 2);
depth3_nodes = all_nodes(node_depths(all_nodes) == 3);
unknown_depth_nodes = all_nodes(node_depths(all_nodes) == -1);

% 输出按深度分类的节点
fprintf('\n按深度分类的节点：\n');
fprintf('深度0节点（源节点）: %d个 [%s]\n', length(depth0_nodes), num2str(depth0_nodes'));
fprintf('深度1节点: %d个 [%s]\n', length(depth1_nodes), num2str(depth1_nodes'));
fprintf('深度2节点: %d个 [%s]\n', length(depth2_nodes), num2str(depth2_nodes'));
fprintf('深度3节点: %d个 [%s]\n', length(depth3_nodes), num2str(depth3_nodes'));
if ~isempty(unknown_depth_nodes)
    fprintf('未知深度节点: %d个 [%s]\n', length(unknown_depth_nodes), num2str(unknown_depth_nodes'));
end

% ===================== 按深度组织边信息 =====================
% 分类边：深度0-1，深度1-2，深度2-3
depth0_1_edges = [];
depth1_2_edges = [];
depth2_3_edges = [];
other_edges = [];

for i = 1:size(all_edges, 1)
    edge = all_edges(i, :);
    depth1 = node_depths(edge(1));
    depth2 = node_depths(edge(2));
    
    % 确定边的类型
    if (depth1 == 0 && depth2 == 1) || (depth1 == 1 && depth2 == 0)
        depth0_1_edges = [depth0_1_edges; edge];
    elseif (depth1 == 1 && depth2 == 2) || (depth1 == 2 && depth2 == 1)
        depth1_2_edges = [depth1_2_edges; edge];
    elseif (depth1 == 2 && depth2 == 3) || (depth1 == 3 && depth2 == 2)
        depth2_3_edges = [depth2_3_edges; edge];
    else
        other_edges = [other_edges; edge];
    end
end

% 输出按深度分类的边
fprintf('\n按深度分类的边：\n');
fprintf('深度0-1边: %d条\n', size(depth0_1_edges, 1));
for i = 1:size(depth0_1_edges, 1)
    node1 = depth0_1_edges(i,1);
    node2 = depth0_1_edges(i,2);
    fprintf('  %d -- %d (权重: %.2f)\n', node1, node2, filtered_adj_mat(node1, node2));
end

fprintf('\n深度1-2边: %d条\n', size(depth1_2_edges, 1));
for i = 1:size(depth1_2_edges, 1)
    node1 = depth1_2_edges(i,1);
    node2 = depth1_2_edges(i,2);
    fprintf('  %d -- %d (权重: %.2f)\n', node1, node2, filtered_adj_mat(node1, node2));
end

fprintf('\n深度2-3边: %d条\n', size(depth2_3_edges, 1));
for i = 1:size(depth2_3_edges, 1)
    node1 = depth2_3_edges(i,1);
    node2 = depth2_3_edges(i,2);
    fprintf('  %d -- %d (权重: %.2f)\n', node1, node2, filtered_adj_mat(node1, node2));
end

if ~isempty(other_edges)
    fprintf('\n其他深度边: %d条\n', size(other_edges, 1));
    for i = 1:size(other_edges, 1)
        node1 = other_edges(i,1);
        node2 = other_edges(i,2);
        fprintf('  %d -- %d (深度: %d-%d, 权重: %.2f)\n', node1, node2, node_depths(node1), node_depths(node2), filtered_adj_mat(node1, node2));
    end
end

% ===================== 计算覆盖率 =====================
% 计算节点覆盖率（相对于可连接的节点）
filtered_adj_mat_graph = graph(filtered_adj_mat ~= 0);
comp = conncomp(filtered_adj_mat_graph);
source_comp = comp(source_node);
potential_nodes = find(comp == source_comp)';
coverage_rate = length(all_nodes) / length(potential_nodes) * 100;
fprintf('\n节点覆盖率: %.2f%% (%d/%d)\n', coverage_rate, length(all_nodes), length(potential_nodes));

fprintf('\n==================================================\n');
end

function [performance_metrics] = evaluate_tree_performance(filtered_adj_mat, integrated_adj_mat, all_nodes, all_edges, node_depths, source_node)
% 计算树的性能指标和时间分析
% 输入:
%   filtered_adj_mat: 过滤后的邻接矩阵
%   integrated_adj_mat: 综合树的邻接矩阵
%   all_nodes: 综合树中的所有节点
%   all_edges: 综合树中的所有边
%   node_depths: 各节点的深度信息
%   source_node: 源节点编号
% 输出:
%   performance_metrics: 包含各项性能指标的结构体

% ===================== 1. 初始化性能指标结构体 =====================
performance_metrics = struct();

% ===================== 2. 时间性能指标 =====================
% 数据包传输时延
performance_metrics.avg_transmission_delay = 0; % 平均传输时延
performance_metrics.max_transmission_delay = 0; % 最大传输时延
performance_metrics.path_delays = []; % 各路径的传输时延

% 计算数据包传输时延（伪代码，待实现）
% TODO: 根据边权重和路径长度计算传输时延

% ===================== 3. 拓扑性能指标 =====================
% 路径分析
performance_metrics.avg_path_length = 0; % 平均路径长度
performance_metrics.max_path_length = 0; % 最大路径长度

% 计算平均路径长度（伪代码，待实现）
% TODO: 计算从源节点到各目标节点的平均路径长度和最大路径长度

% 节点度分布
performance_metrics.degree_distribution = []; % 节点度分布
performance_metrics.avg_degree = 0; % 平均节点度

% 计算节点度分布（伪代码，待实现）
% TODO: 计算各节点的度以及整体分布情况

% ===================== 4. 带宽和流量指标 =====================
% 带宽利用率
performance_metrics.bandwidth_utilization = 0; % 带宽利用率

% 流量分布
performance_metrics.traffic_distribution = []; % 各节点的流量分布

% 计算带宽利用率和流量分布（伪代码，待实现）
% TODO: 基于边权重和网络拓扑计算带宽利用率和流量分布

% ===================== 5. 可靠性指标 =====================
% 可靠性分析
performance_metrics.reliability = 0; % 网络可靠性指标
performance_metrics.robustness = 0; % 抗故障能力

% 计算可靠性（伪代码，待实现）
% TODO: 分析网络结构的可靠性和抗故障能力

% ===================== 6. 综合性能得分 =====================
% 综合评分，考虑多个指标的加权平均
performance_metrics.overall_score = 0; % 综合性能得分

% 计算综合得分（伪代码，待实现）
% TODO: 根据各项指标计算加权综合得分

% ===================== 7. 打印性能分析结果 =====================
fprintf('\n==================================================\n');
fprintf('               树结构性能分析\n');
fprintf('==================================================\n\n');

% 打印时间性能指标
fprintf('【1. 时间性能指标】\n');
fprintf('平均传输时延: %.2f ms\n', performance_metrics.avg_transmission_delay);
fprintf('最大传输时延: %.2f ms\n', performance_metrics.max_transmission_delay);

% 打印拓扑性能指标
fprintf('\n【2. 拓扑性能指标】\n');
fprintf('平均路径长度: %.2f\n', performance_metrics.avg_path_length);
fprintf('最大路径长度: %d\n', performance_metrics.max_path_length);
fprintf('平均节点度: %.2f\n', performance_metrics.avg_degree);

% 打印带宽和流量指标
fprintf('\n【3. 带宽和流量指标】\n');
fprintf('带宽利用率: %.2f%%\n', performance_metrics.bandwidth_utilization * 100);

% 打印可靠性指标
fprintf('\n【4. 可靠性指标】\n');
fprintf('网络可靠性: %.2f\n', performance_metrics.reliability);
fprintf('抗故障能力: %.2f\n', performance_metrics.robustness);

% 打印综合性能得分
fprintf('\n【5. 综合性能评分】\n');
fprintf('综合性能得分: %.2f/10.0\n', performance_metrics.overall_score);

fprintf('\n==================================================\n');

end