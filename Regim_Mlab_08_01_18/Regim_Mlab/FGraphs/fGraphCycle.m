function gCycle = fGraphCycle(g, hFN, hFV, START, option)
%Необходима доработка в части оптимизации количества слагаемых
% Составляет независимый базис циклов в графе. Осуществляет обход графа
% в ширину для определения контурообразующих ветвей, далее -
% поочередный выбор данных ветвей в графе и возврат по дереву
% графа к стартовой точке от концов выбранной ветви одновременно по двум
% маршрутам. При пересечении 2-х маршрутов цикл считается завершенным.
%
% gCycle = fGraphCycle(g, hFN, hFV, START, option)
% gCycle - выходной массив типа CGraph, содержащий все независимые контуры;
% g - объект CGraph, содержащий связанную подсхему, в которой будет
% происходить поиск циклов;
% hFN - handle ссылки на начало ветвей в модели сети;
% hFV - handle ссылки на концы ветвей в модели сети;
% START - номер начального узла в соответствии с выбранным источником
% данных;
% option - позволяет выбрать источник данных для выходных номеров узлов и ветвей
% ("Граф" или "Модель");
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% August 2017.

% инициализация переменных
ParentN(g.nod.n)=0;
ParentR(g.nod.n)=0;
CurrN=0;
Queue=FIFO;
Queue.len;
ParentN(START)=-1;
ParentR(START)=-1;
Queue=add(Queue,START);
UsedR(g.rib.n)=0;
% количество контуров
nKont=g.rib.n-g.nod.n+1;
NotUsedR(nKont)=0;
% Выбор источника данных для hFN и hFV
switch option
    case 'Граф'
        hFN=(1:g.nod.n);
        hFV=@(I)[g.rib(I).ny1 g.rib(I).ny2];
    case 'Модель'
        hFN=hFN;
        hFV=hFV;
    otherwise
        option ='Модель';
        warning('Неопределенная опция "Источник" функции fGraphSub. Принято значение "Модель"');
end

% обход графа в ширину с использованием объекта класса FIFO (очередь)
while(isempty(Queue)==0)
    CurrN=Queue.last;  % текущий узел - первый в очереди обхода
    AN=g.nod(CurrN).an;
    AR=g.nod(CurrN).ar;
    % перебор всех отходящих узлов
    for j=1:length(AN)
        if (ParentN(AN(j))==0) % если не были в данном узле
            Queue=add(Queue, AN(j)); % добавить в очередь узел
            ParentN(AN(j))=CurrN; % определение родительского узла для узла AN(j)
            ParentR(AN(j))=AR(j); % ветви для узла AN(j)
            UsedR(AR(j))=1; % признак посещенности ветви
        end
    end
    clear AN;
    clear AR;
    Queue=del(Queue); % вычеркиваем первый элемент в очереди
end

% составление массива непосещенных при обходе ветвей
CounterNotUsed=0;
for i=1:g.rib.n
    if UsedR(i)==0
        CounterNotUsed=CounterNotUsed+1; % счетчик непосещенных ветвей
        NotUsedR(CounterNotUsed)=i; % массив непосещенных (контурообразующих ветвей)
    end
end
% Сопоставление расчетного кол-ва контуров с фактическим кол-вом непосещенных
% ветвей
if length(NotUsedR)~=nKont
    warning('Неверное количество контуров (неверно построен подграф)');
end
% Выделение циклов
for i=1:length(NotUsedR) % цикл по количеству контурообразующих ветвей
    % инициализация
    CountN1=1;
    CountN2=1;
    Stop1=0;
    Stop2=0;
    Fin=0;
    StopLine=0;
    % работа с массивами переменной длины
    MarN1(1:10)=0;
    MarN2(1:10)=0;
    MarR1(1:10)=0;
    MarR2(1:10)=0;
    if length (MarN1)>10
        MarN1(1)=[];
        MarN2(1)=[];
        MarR1(1)=[];
        MarR2(1)=[];
    end
    
    % Инциализация
    Visited(1:g.nod.n)=0; % Массив посещенных узлов
    CountN1=1; % Количиство ветвей по первому маршруту
    CountN2=1; % Количиство ветвей по второму маршруту
    MarN1(CountN1)=g.rib(NotUsedR(i)).ny1; % Начальная точка первого маршрута - первый конец контурообразующей ветви
    MarN2(CountN2)=g.rib(NotUsedR(i)).ny2; % Начальная точка второго маршрута - второй конец контурообразующей ветви
    while (Fin==0) % пока переменная финишной точки равна нулю
        % проверка на недостижение стартового узла
        if (ParentN(MarN1(CountN1))== START)
            Stop1=1; % останов продвижения при достижении стартового узла по первому маршруту
        end
        if (ParentN(MarN2(CountN2))== START)
            Stop2=1; % останов продвижения при достижении стартового узла по второму маршруту
        end
        % проверка на недостижение стартового узла по 2 линиям
        if (ParentN(MarN1(CountN1))== START) && (ParentN(MarN2(CountN2))== START)
            warning ('Достигнут стартовый узел fGraphCycle по двум путям');
        end
        % работа с массивами переменной длины
        if (length (MarN1)+1)<=(CountN1)
            MarN1(length(MarN1)+10)=0;
            MarR1(length(MarR1)+10)=0;
        end
        if (length (MarN2)+1)<=(CountN2)
            MarN2(length(MarN2)+10)=0;
            MarR2(length(MarR2)+10)=0;
        end
        
        if Stop1==0 % если не достигнут стартовый узел
            if Visited(ParentN(MarN1(CountN1)))==0; % если родительский узел от данного не посещен
                CountN1=CountN1+1; % Добавляем родительский узел и соотв ветвь в маршрут
                MarN1(CountN1)=ParentN(MarN1(CountN1-1));
                MarR1(CountN1-1)=ParentR(MarN1(CountN1-1));
                Visited(MarN1(CountN1))=1; % признак посещенности = 1
            else
                MarR1(CountN1)=ParentR(MarN1(CountN1)); % добавляем ветвь в маршрут
                StopLine=1; % значение =1 если замыкание контура произошло на первом маршруте и 2, если на втором
                Fin= ParentN(MarN1(CountN1)); % узел на котором произошло объединение маршрутов
                break;
            end
        end
        if Stop2==0 % если не достигнут стартовый узел
            if Visited(ParentN(MarN2(CountN2)))==0; % если родительский узел от данного не посещен
                CountN2=CountN2+1; % Добавляем родительский узел и соотв ветвь в маршрут
                MarN2(CountN2)=ParentN(MarN2(CountN2-1));
                MarR2(CountN2-1)=ParentR(MarN2(CountN2-1));
                Visited(MarN2(CountN2))=1; % признак посещенности = 1
            else
                MarR2(CountN2)=ParentR(MarN2(CountN2)); % добавляем ветвь в маршрут
                StopLine=2; % значение =1 если замыкание контура произошло на первом маршруте и 2, если на втором
                Fin= ParentN(MarN2(CountN2)); % конечный узел в контуре
                break;
            end
        end
    end
    % работа с массивом переменной длины - удаление лишних элементов
    MarN1(CountN1+1:end)=[];
    MarN2(CountN2+1:end)=[];
    % по первому маршруту
    if StopLine==1 % если пересечение маршрутов произошло на первом
        % удаление лишних ветвей (кол-во ветвей зависит от признака StopLine)
        MarR1(CountN1+1:end)=[];
        MarR2(CountN2:end)=[];
        if MarN1(CountN1)~=START % если узел пересечения маршрутов не стартовый (тогда удаление лишних эл-тов не нужно)
            % удаление лишних элементов из маршрута по которому останов не
            % проиходил
            for j=CountN2:1 % перебор маршрута от конца до начала до наступления стоп
                if MarN2(j)==Fin % если досгнут узел объединения машрутов, то стоп
                    break;
                else
                    MarN2(j)=[]; % удаление лишних ветвей и узлов
                    MarR2(j-1)=[];
                end
            end
        end
        % по второму маршруту
    elseif StopLine==2 % если пересечение маршрутов произошло на втором
        MarR1(CountN1:end)=[];
        MarR2(CountN2+1:end)=[];
        if MarN2(CountN2)~=START % если узел пересечения маршрутов не стартовый (тогда удаление лишних эл-тов не нужно)
            % удаление лишних элементов из маршрута по которому останов не
            % проиходил
            for j=CountN1:1
                if MarN1(j)==Fin  % если досгнут узел объединения машрутов, то стоп
                    break;
                else
                    MarN1(j)=[]; % удаление лишних ветвей и узлов
                    MarR1(j-1)=[];
                end
            end
        end
        % применение опции источник данных
        if strcmpi(option, 'Граф')
            MarN1=MarN1;
            MarN2=MarN2;
            MarR1=MarR1;
            MarR2=MarR2;
        else
            for j=1:length(MarN1)
                MarN1(j)=g.nod(MarN1(j));
                if j~=length(MarN1)
                    MarR1(j)=g.rib(MarR1(j));
                end
            end
            for j=1:length(MarN2)
                MarN2(j)=g.nod(MarN2(j));
                if j~=length(MarN)
                    MarR2(j)=g.rib(MarR2(j));
                end
            end
        end       
    else % если нет линии останова, то ошибка обнаружения контура
        warning ('Ошибка обнаружения контура');
    end
    % создание объекта CGraph (узлы и ветви второго маршрута записаны в обратном порядке для отображения последовательности элементов в графе)
    gCycle(i)=CGraph(hFN, [MarN1(1:end), MarN2(end:-1:1)], hFV, [g.rib(NotUsedR(i)), MarR1(1:end), MarR2(end:-1:1)]);
end
end