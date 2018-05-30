function Plot = fGraphPlot(varargin)
% ќсуществл€ет вывод графа типа CGraph в виде рисунка с помощью функции plot
%
% gPlot = fGraphPlot(g,option)
% gPlot - выходной элемент типа рисунок (при вызове вызывает форму с рисунком графа);
% g - входной граф типа CGraph;
% option - опци€, определ€юща€ необходимость вывода номер ветвей;
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% August 2017 Mod December 2017.

% обработка исходных данных
% обработка случа€ с пустыми исходными данными
if isempty(varargin)
    return;
    % обрабатываютс€ только объекты CGraph
elseif isa(varargin{1}, 'CGraph')
    % ввод опций расчета
    switch length(varargin)
        % ввод опций по умолчанию
        case 1
            g = varargin{1};
            option.MarkRib=1;
            % ручной ввод опций
        case 2
            g = varargin{1};
            option=varargin{2};
    end
else
    warning('ќжидалс€ объект типа "CGraph".');
    Plot=0;
    return;
end

% если граф непустой - вывод его на экран
if isempty(g)==0
    % построение стандратного Matlab графа
gPlot = graph(g.rib(:).ny1, g.rib(:).ny2, g.rib, g.nod.n);
if option.MarkRib==1 && isempty(g.rib)==0
    Plot=plot(gPlot,'NodeLabel',g.nod,'EdgeLabel',gPlot.Edges.Weight,'MarkerSize',4,'EdgeAlpha',1);
else
    Plot=plot(gPlot,'NodeLabel',g.nod,'MarkerSize',4,'EdgeAlpha',0.5);
end
axis square;
else
    Plot=0;
    return;
end