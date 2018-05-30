function gSub = fGraphSub(g, hFN, hFV, hTypeN, hCommt, options)
% Осуществляет выделение подграфов на основании топологии и состояния
% коммутационных аппаратов.
%
% gSub = fGraphSub(g, hFN, hFV, hTypeN, hCommt, options)
%
% gSub - выходной массив объектов класса CGraph подсхем
% g - граф разделяемой схемы( объект класса CGraph)
% hFN - handle ссылки на начало ветвей в модели сети
% hFV - handle ссылки на концы ветвей в модели сети
% hTypeN - Типы узлов в формате nTip
% hCommt - состояние коммутационных аппаратов в формате cmStat
% options - опции регулирующие способ разделения графа
% options.Size - опция определяет учет или неучет связанности ветвей через центры питания
% «Частн» - выделение подграфов без учета связанности через центр питания;
% «Полн» - выделение подграфов с учетом связанности через центр питания;
% options.Commt -  опция определяет учет или неучет положения коммутационных аппаратов при построении подграфов.
% «Без КА» - положение всех коммутационных аппаратов за исключением отключенных с запретом принимаем «включен»;
% «С КА» - учитывается положение комутационных аппаратов;
% options.Origin - опция определяет на какие номера участков и узлов опирается функция при построении подграфов.
% «Модель» - номера элементов принимаются из модели;
% «Граф» - номера элементов принимаются из опорного графа;
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% August 2017.

% Инициализация переменных
nod(g.nod.n,1)=struct('an',0,'ar',0); % массив отходящих узлов и ветвей (нумерация узлов графа)
nTypeGraph(g.nod.n)=0; % Массив типов узлов (нумерация узлов графа)
CommtGraph(g.rib.n,2)=0; % Массив состояния коммутационных аппаратов (нумерация узлов графа)
CommtLogicalGraph(g.rib.n)=0; % Логический массив состояния коммутационных аппаратов (нумерация узлов графа)
nZ=zeros(g.nod.n,1); % Нулевой массив - количество элементов равно количеству узлов
rZ=zeros(g.rib.n,1); % Нулевой массив - количество элементов равно количеству ветвей
NoteCurrN=nZ; % Логический массив обхода узлов на текущей итерации обхода
NoteSummN=nZ; % Логический массив обхода узлов на всех итерациях обхода
NoteCurrR=rZ; % Логический массив обхода ветвей на текущей итерации обхода
NoteSummR=rZ; % Логический массив обхода ветвей на всех итерациях обхода
NumbSubGraph=0; % Текущее количество подграфов на итерации
SubGraph=nZ; % Текущий подграф (узлы)
SubGraphRib=rZ; % Текущий подграф (ветви)
Nnsub=0; % Количество узлов в подграфе
Nrsub=0; % Количество ветвей в подграфе
CPflag=0; % Флаг наличия отходящих ветвей от ЦП
gSub(3)=CGraph; % Массив хранящий подграфы

% Запись массива отходящих линий и узлов, массива типов узлов
for i=1:g.nod.n
    nod(i)=struct('an',g.nod(i).an,'ar',g.nod(i).ar);
    nTypeGraph(i)=hTypeN(g.nod(i));
end

for i=1:g.rib.n
    CommtGraph(i,1:2)=hCommt(g.rib(i));
    CommtLogicalGraph(i)=1;
end

% Выбор источника данных для hFN и hFV
switch options.Origin
    case 'Граф'
        hFN=(1:g.nod.n);
        hFV=@(I)[g.rib(I).ny1 g.rib(I).ny2];
    case 'Модель'
        hFN=hFN;
        hFV=hFV;
    otherwise
        options.Origin='Модель';
        warning('Неопределенная опция "Источник" функции fGraphSub. Принято значение "Модель"');
end
% Проверка правильности ввода опции Size
switch options.Size
    case'Полн'
    case 'Частн'
    otherwise
        options.Commt='Полн';
        warning ('Введена неопределенная опция Size для построения подграфа.\n Ожидалось "Полн", "Частн". Установлено "Частн"');
end

% Перевод типа коммутационного аппарата из  в логический (1, 0)
for i=1:g.rib.n
    switch options.Commt
        case'С КА'
            if (CommtGraph(i,1)==cmStat.OO)||(CommtGraph(i,1)==cmStat.O)||(CommtGraph(i,2)==cmStat.OO)||(CommtGraph(i,2)==cmStat.O)
                CommtLogicalGraph(i)=0;
            end
        case 'Без КА'
            if (CommtGraph(i,1)==cmStat.OO)||(CommtGraph(i,2)==cmStat.OO)
                CommtLogicalGraph(i)=0;
            end
        otherwise
            if (CommtGraph(i,1)==cmStat.OO)||(CommtGraph(i,2)==cmStat.OO)
                CommtLogicalGraph(i)=0;
            end
            options.Commt='Без КА';
            warning ('Введена неопределенная опция Commt для построения подграфа.\n Ожидалось "С КА", "Без КА". Установлено "Без КА"');
    end
end

% Цикл разбиения на подграфы
for i=1:g.nod.n % Цикл по всем центрам питания
    % Проверка необходимости добавления элементов в массив gSub
    if nTypeGraph(i)==nTip.BU
        if length(gSub)<NumbSubGraph+length(nod(i).an)
            gSub(NumbSubGraph+2*(length(nod(i).an)+1))=CGraph;
        end
        for j=1:length(nod(i).an) % Цикл по отходяшим линиям от центра питания
            if (nTypeGraph(nod(i).an(j))~=nTip.BU)&&(CommtLogicalGraph(nod(i).ar(j))==1)
                if CPflag==0
                    CPflag=1;
                end
                if (NoteSummN(nod(i).an(j))==0)
                    StartTravel=nod(i).an(j);
                    % Запуск обхода графа от каждого узла присоединенного к ЦП
                    % , который удовлетворяет условиям, описанным выше
                    [NoteCurrN, NoteCurrR] = fGraphTravel(nod, StartTravel, nTypeGraph, CommtLogicalGraph, options.Size);
                    % Создание массива текущего подграфа (узлы)
                    for k=1:g.nod.n
                        if (NoteCurrN(k)==1)
                            NoteSummN(k)=NoteCurrN(k);
                            Nnsub=Nnsub+1;
                            if strcmpi(options.Origin,'Граф')==1
                                SubGraph(Nnsub)=k;
                            else
                                SubGraph(Nnsub)=g.nod(k);
                            end
                        end
                    end
                    % Создание массива текущего подграфа (ветви)
                    for k=1:g.rib.n
                        if (NoteCurrR(k)==1)
                            NoteSummR(k)=NoteCurrR(k);
                            Nrsub=Nrsub+1;
                            if strcmpi(options.Origin,'Граф')==1
                                SubGraphRib(Nrsub)=k;
                            else
                                SubGraphRib(Nrsub)=g.rib(k);
                            end
                        end
                    end
                    % Создание подграфа
                    NumbSubGraph=NumbSubGraph+1;
                    gSub(NumbSubGraph) = CGraph(hFN, SubGraph(1:Nnsub), hFV, SubGraphRib(1:Nrsub));
                    SubGraph=nZ;
                    SubGraphRib=rZ;
                    Nnsub=0;
                    Nrsub=0;
                end
            elseif (nTypeGraph(nod(i).an(j))==nTip.BU) && strcmpi(options.Size, 'Частн')
                if (NoteSummR(nod(i).ar(j))==0)&&(CommtLogicalGraph(nod(i).ar(j))==1)
            CPflag=1;
            NumbSubGraph=NumbSubGraph+1;
            NoteSummN(i)=1;
            NoteSummN(nod(i).an(j))=1;
            NoteSummR(nod(i).ar(j))=1;
            gSub(NumbSubGraph) = CGraph(hFN, [i; nod(i).an(j)], hFV, nod(i).ar(j));
                end
            end
        end
        % Обработка исключения с отсутствием отходящих от ЦП участков
        % ЦП должен входить хотя бы в один подграф даже при отсутствии
        % отходящих участков
        if (CPflag==0)&& NoteSummN(i)==0
            NumbSubGraph=NumbSubGraph+1;
            NoteSummN(i)=1;
            gSub(NumbSubGraph) = CGraph(hFN, i, hFV, []);
        end
        CPflag=0;
    end
end
% Создание подграфа со всеми неиспользованными ветвями и узлами
for i=1:g.nod.n
    if NoteSummN(i)==0
        Nnsub=Nnsub+1;
        if strcmpi(options.Origin,'Граф')==1
            SubGraph(Nnsub)=i;
        else
            SubGraph(Nnsub)=g.nod(i);
        end
    end
end
for i=1:g.rib.n
    if NoteSummR(i)==0
        Nrsub=Nrsub+1;
        if strcmpi(options.Origin,'Граф')==1
            SubGraphRib(Nrsub)=i;
        else
            SubGraphRib(Nrsub)=g.rib(i);
        end
    end
end

NumbSubGraph= NumbSubGraph+1;
gSub(NumbSubGraph) = CGraph(hFN, SubGraph(1:Nnsub), hFV, SubGraphRib(1:Nrsub));
gSub(NumbSubGraph+1:end)= [];

end % Конец



