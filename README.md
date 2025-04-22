# Metro网络拓扑分析与可视化系统

## 1. 系统概述
本系统用于分析和可视化Metro网络拓扑结构，实现了从原始拓扑生成到树结构构建、修剪和拼接的完整流程。系统支持骨干树、拼接骨干树、次级拼接和简单拼接的可视化，并提供了丰富的节点和边的颜色编码方案。

## 2. 函数实现详解

### 2.1 拓扑生成与过滤

#### Metro1.m - 网络拓扑生成
实现方法：
1. 节点生成
   - 创建38个节点的网络结构
   - 使用邻接矩阵表示节点连接关系

2. 权重计算
   - 使用指数衰减函数：weight = base_weight * exp(-0.3 * distance)
   - 加入正态分布随机因子：randn() * 5
   - 确保权重范围在35-100之间
   - 权重计算考虑节点间距离影响

3. 统计信息生成
   - 计算边权重均值
   - 计算标准差
   - 记录节点度分布

输出：
- adj_mat：38x38的邻接矩阵
- weight_stats：包含权重统计信息的结构体

#### Metro_filter.m - 网络过滤
实现方法：
1. 阈值过滤
   - 遍历邻接矩阵中的所有边
   - 将权重低于阈值的边设为0
   - 保持矩阵对称性

2. 连通性检查
   - 使用深度优先搜索(DFS)验证网络连通性
   - 记录分离的子图数量
   - 确保关键路径的连通性

输出：
- filtered_adj_mat：过滤后的邻接矩阵

### 2.2 树结构构建与分析

#### build_balanced_tree.m - 平衡树构建
实现方法：
1. BFS遍历
   - 从源节点开始进行广度优先搜索
   - 使用队列存储待处理节点
   - 记录访问顺序

2. 子节点选择
   - 对每个节点最多选择两个子节点
   - 基于边权重排序选择最优子节点
   - 使用优先队列实现权重排序

3. 树结构维护
   - 记录父子关系
   - 更新节点状态
   - 构建树的邻接矩阵

输出：
- tree_adj_mat：树的邻接矩阵
- tree_edges：记录树边的结构体

#### prune_balanced_tree.m - 树修剪
实现方法：
1. 路径分析
   - 使用DFS找出所有从根到叶的路径
   - 为每条路径保留前4个节点
   - 记录保留节点的深度信息

2. 结构修剪
   - 移除不在保留路径上的节点
   - 更新邻接矩阵
   - 保持树的层次结构

3. 路径优化
   - 合并重复路径
   - 优化节点连接关系
   - 确保修剪后的结构完整性

输出：
- pruned_tree_mat：修剪后的树邻接矩阵
- pruned_paths：保留的路径信息

### 2.3 拼接处理

#### analyze_pruned_tree.m - 骨干树分析
实现方法：
1. 深度计算
   - 使用BFS计算每个节点的深度
   - 创建深度层级映射
   - 记录每层节点集合

2. 特殊过滤
   - 过滤骨干树节点间的边
   - 处理深度为3的节点连接
   - 应用过滤规则

3. 信息整理
   - 生成深度统计信息
   - 记录节点分类
   - 准备拼接数据

输出：
- filtered_adj_mat_copy：特殊过滤后的邻接矩阵
- depth_info：节点深度信息
- spliced_depth_info：拼接相关的深度信息

#### simple_splice.m - 简单拼接
实现方法：
1. 节点选择
   - 识别深度为2的节点
   - 计算节点度数
   - 按度数和编号排序

2. 拼接边创建
   - 查找可连接的非树节点
   - 创建新的拼接边
   - 处理多节点连接情况

3. 拼接信息记录
   - 记录拼接边信息
   - 更新节点状态
   - 维护拼接结构

输出：
- simple_spliced_info：拼接信息结构体

### 2.4 可视化实现

#### visualize_metro_graph.m - 原始拓扑显示
实现方法：
1. 布局计算
   - 使用force-directed算法
   - 实现圆形初始布局
   - 添加重力效应

2. 节点绘制
   - 设置节点大小和颜色
   - 添加节点标签
   - 突出显示源节点

3. 边绘制
   - 显示边权重
   - 设置边的样式
   - 添加半透明背景

#### visualize_all_trees.m - 综合显示
实现方法：
1. 颜色编码
   - 根据节点深度设置颜色
     - 深度0（源节点）：红色，大小为12
     - 深度1：紫色，大小为10
     - 深度2：绿色，大小为10
     - 深度3：蓝色，大小为10
   - 骨干树边：浅蓝色
   - 拼接边：红色

2. 布局优化
   - 改进force布局参数
   - 优化节点分布
   - 减少边的交叉

3. 图例生成
   - 创建清晰的图例
   - 标注各类元素
   - 优化显示位置

## 3. 关键算法实现

### 3.1 深度优先搜索(DFS)
```matlab
function dfs(node, visited)
    visited(node) = true;
    neighbors = find(adj_mat(node, :));
    for next_node = neighbors
        if ~visited(next_node)
            dfs(next_node, visited);
        end
    end
end
```

### 3.2 广度优先搜索(BFS)
```matlab
function [depths] = bfs(source)
    queue = [source];
    depths = inf(1, n);
    depths(source) = 0;
    while ~isempty(queue)
        node = queue(1);
        queue(1) = [];
        neighbors = find(adj_mat(node, :));
        for next_node = neighbors
            if depths(next_node) == inf
                depths(next_node) = depths(node) + 1;
                queue = [queue next_node];
            end
        end
    end
end
```

### 3.3 Force-Directed布局
```matlab
function [pos] = force_layout(adj_mat)
    % 初始化位置
    pos = initialize_circular_layout();
    
    % 迭代优化
    for iter = 1:max_iterations
        % 计算斥力
        [fx, fy] = calculate_repulsive_forces(pos);
        
        % 计算引力
        [fx, fy] = add_attractive_forces(fx, fy, adj_mat, pos);
        
        % 更新位置
        pos = update_positions(pos, fx, fy);
    end
end
```

## 4. 数据结构

### 4.1 邻接矩阵
- 大小：38x38
- 类型：double
- 存储：边权重信息

### 4.2 深度信息结构体
```matlab
depth_info = struct(
    'nodes', cell(1,4),     % 每层节点集合
    'depths', zeros(1,38),  % 节点深度映射
    'stats', struct()       % 统计信息
);
```

### 4.3 拼接信息结构体
```matlab
spliced_info = struct(
    'edges', [],        % 拼接边列表
    'nodes', [],        % 拼接节点
    'weights', []       % 边权重
);
```

## 5. 性能优化

### 5.1 计算优化
- 使用矩阵运算代替循环
- 预分配大型数组
- 优化搜索算法

### 5.2 内存优化
- 及时清理临时变量
- 使用稀疏矩阵
- 优化数据结构

### 5.3 显示优化
- 批量绘制图形元素
- 使用适当的刷新策略
- 优化标签位置计算

## 6. 使用说明
1. 确保所有.m文件在同一目录
2. 运行main.m文件
3. 可调整参数：
   - threshold：带宽阈值
   - source_node：源节点编号
4. 程序将自动执行完整流程并显示结果

## 7. 更新说明
### 7.1 主要更新内容
1. 优化了拼接骨干树的节点和边显示
   - 统一了节点颜色方案
   - 改进了边的显示效果
   - 添加了节点大小区分

2. 改进了信息传递机制
   - 确保拼接骨干树节点信息正确传递
   - 避免节点信息被错误覆盖
   - 优化了数据结构更新逻辑

3. 增强了可视化效果
   - 添加了更清晰的图例
   - 优化了节点和边的显示顺序
   - 改进了布局算法

4. 修复了关键错误
   - 修复了边比较时的维度不匹配问题
   - 优化了边的重复检查逻辑
   - 改进了节点深度信息的处理

### 7.2 具体改进
1. 节点显示
   - 深度0（源节点）：红色，大小为12
   - 深度1：紫色，大小为10
   - 深度2：绿色，大小为10
   - 深度3：蓝色，大小为10

2. 边显示
   - 骨干树边：浅蓝色
   - 拼接边：红色

3. 信息传递
   - 修复了深度1节点显示为灰色的问题
   - 确保拼接骨干树节点信息正确传递
   - 优化了数据结构更新逻辑

4. 错误修复
   - 改进了边的比较逻辑，避免维度不匹配错误
   - 优化了边的重复检查机制
   - 增强了代码的健壮性

### 7.3 最新更新
1. 代码健壮性提升
   - 添加了边界检查
   - 优化了数据结构初始化
   - 改进了错误处理机制

2. 性能优化
   - 优化了边的比较算法
   - 改进了节点信息的更新逻辑
   - 提升了代码执行效率

3. 可视化改进
   - 优化了边的显示顺序
   - 改进了节点的颜色方案
   - 增强了图例的可读性

## 8. 数据汇聚时间分析功能

### 8.1 数据汇聚时间计算
系统新增了计算树结构中数据汇聚时间的功能，通过以下步骤实现：

1. 参数设置
   - 数据大小：默认设置为1000单位（可理解为MB或KB）
   - 基础汇聚时间：默认为5单位时间（可理解为ms或s）

2. 计算方法
   - 基于树的深度结构计算数据从叶节点到源节点的传输时间
   - 考虑边权重对传输速度的影响
   - 综合考虑骨干树和拼接结构的不同传输特性

3. 核心函数
```matlab
[node_times, total_time] = calculate_tree_performance(filtered_adj_mat, 
    tree_nodes, depth_info, spliced_depth_info, simple_spliced_info, 
    secondary_spliced_info, source_node, pruned_paths, data_size, gather_time);
```

4. 输出结果
   - node_times：每个节点的数据汇聚时间
   - total_time：整体网络的数据汇聚总时间

### 8.2 时间信息可视化
系统提供了带时间信息的综合树可视化功能：

1. 可视化实现
```matlab
visualize_integrated_tree(filtered_adj_mat, tree_nodes, depth_info, 
    spliced_depth_info, simple_spliced_info, secondary_spliced_info, 
    source_node, pruned_paths, node_times);
```

2. 可视化特点
   - 保持节点颜色编码（深度0-3分别为红、紫、绿、蓝）
   - 边的颜色区分（骨干树边为浅蓝色，拼接边为红色）
   - 添加时间信息标签，显示数据传输耗时
   - 节点大小可反映数据汇聚量或重要性

## 9. 综合功能流程

通过main.m主函数，系统按照以下流程执行全部功能：

1. 初始化与数据准备
   - 设置随机种子(rng(40))确保结果可复现
   - 设置带宽阈值(threshold=40)和源节点(source_node=18)

2. 拓扑生成与过滤
   - 生成原始拓扑并可视化
   - 根据阈值过滤并可视化

3. 树结构构建
   - 构建平衡二叉树并可视化
   - 修剪树结构形成骨干树

4. 拼接处理
   - 分析骨干树并进行特殊过滤
   - 进行简单拼接和次级拼接

5. 综合可视化
   - 显示不同类型的树结构
   - 输出节点和边的统计信息

6. 性能分析
   - 计算数据汇聚时间
   - 可视化带时间信息的综合树结构

## 10. 使用示例

### 10.1 基本使用
直接运行main.m文件即可执行全部功能流程：
```matlab
% 在MATLAB命令窗口中执行
run('main.m');
```

### 10.2 数据汇聚时间分析
可以单独执行数据汇聚时间分析部分：
```matlab
% 设置参数
data_size = 1000;  % 数据大小
gather_time = 5;   % 基础汇聚时间

% 计算汇聚时间
[node_times, total_time] = calculate_tree_performance(filtered_adj_mat, 
    tree_nodes, depth_info, spliced_depth_info, simple_spliced_info, 
    secondary_spliced_info, source_node, pruned_paths, data_size, gather_time);

% 显示结果
fprintf('源节点 %d 的数据汇聚总时间: %.2f\n', source_node, total_time);
```

### 10.3 带时间信息的可视化
可以单独执行带时间信息的可视化：
```matlab
% 生成带时间信息的综合树可视化
visualize_integrated_tree(filtered_adj_mat, tree_nodes, depth_info, 
    spliced_depth_info, simple_spliced_info, secondary_spliced_info, 
    source_node, pruned_paths, node_times);
``` 