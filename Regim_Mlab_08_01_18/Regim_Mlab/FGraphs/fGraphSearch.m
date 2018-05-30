function gPath = fGraphSearch(g, hFN, hFV, START, GOAL, option)
% Осуществляет поиск кратчайших (минимальное количество участков) путей
%(через обход в ширину) от одного стартового узла до одной или нескольких
% целей, возвращает результат в форме массива графов, содержащих узлы и
% ветви, входящие в каждый из маршрутов. Использует класс FIFO (очередь).
%
% gPath = fGraphSearch(g, hFN, hFV, START, GOAL, option)
% gPath - выходной массив типа CGraph, содержащий пути от START до всех GOAL;
% g - объект CGraph, содержащий связанную подсхему, в которой будет
% происходить поиск маршрутов;
% hFN - handle ссылки на начало ветвей в модели сети;
% hFV - handle ссылки на концы ветвей в модели сети;
% START - номер начального узла в соответствии с выбранным источником
% данных;
% GOAL - массив номеров узлов-целей;
% option - позволяет выбрать источник данных для выходных номеров узлов и ветвей
% ("Граф" или "Модель");
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% August 2017.

ParentN(g.nod.n)=0;
ParentR(g.nod.n)=0;
CurrN=0;
Queue=FIFO;
Queue.len;
ParentN(START)=-1;
ParentR(START)=-1;
Queue=add(Queue,START);
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
    CurrN=Queue.last; % текущий узел - первый в очереди обхода
    AN=g.nod(CurrN).an;
    AR=g.nod(CurrN).ar;
    % перебор всех отходящих узлов
    for (j=1:length(AN))
        if (ParentN(AN(j))==0) % если не были в данном узле
            Queue=add(Queue, AN(j)); % добавить в очередь узел
            ParentN(AN(j))=CurrN; % определение родительского узла для узла AN(j)
            ParentR(AN(j))=AR(j); % ветви для узла AN(j)
        end
    end
    clear AN;
    clear AR;
    Queue=del(Queue); % вычеркиваем первый элемент в очереди
end

% инициализация
CurrN=0;
MarshN(10) = 0; % Узлы в маршруте
MarshR(10) = 0; % Ветви в маршруте
gPath(length(GOAL))= CGraph; % Выходной объект CGraph функции
% для всех целевых узлов
for i=1:length(GOAL)
    CurrN=GOAL(i); % Первый узел - целевой узел
    j=1;
    % работа с массивами переменной длины
    if length (MarshN)>10
    MarshN (11:end)=[];
    MarshR (11:end)=[];
    end
    MarshN(10) = 0;
    MarshR(10) = 0;
    MarshN(j)= CurrN; % Первый узел - целевой узел
    % Пока не достигнем стартового узла осуществляем поочередный переход от
    % цели по направлении к стартовому узлу
    while (CurrN~= START)
        % работа с массивом переменной длины
        if length(MarshN)<=j 
            MarshN(length(MarshN)+10)=0;
            MarshR(length(MarshR)+10)=0;
        end
        % операция перехода к след. узлу
        MarshR(j)=ParentR(CurrN); % Добавляем элемент в массив ветвей
        j=j+1;
        CurrN=ParentN(CurrN);  % Новый текущий узел - родитель старого 
        MarshN(j)=CurrN; % Добавляем элемент в массив узлов
    end
    % удаление лишних элементов из маршрута
    MarshN((j+1):end)=[];
    MarshR(j:end)=[];
    % применение опции источник данных
    if strcmpi(option, 'Граф')
        MarshN=MarshN;
        MarshR=MarshR;
    else
        for j=1:length(MarshN)
        MarshN(j)=g.nod(MarshN(j));
        if j~=length(MarshN)
        MarshR(j)=g.rib(MarshR(j));
        end
        end
    end
    gPath(i) = CGraph(hFN, MarshN, hFV, MarshR);
end
end