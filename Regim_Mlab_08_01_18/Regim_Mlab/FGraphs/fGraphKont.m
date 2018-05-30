function [gKontBU, gKontPU, gCycle] = fGraphKont(g, hFN, hFV, TypeN, Nop)
% Осуществляет создание системы независимых контуров трех типов
% из связанного подграфа схемы, результат возвращает в виде массивов графов
% с разбиением по типам.
%
% [gKontBU, gKontPU, gCycle] = fGraphKont(g, hFN, hFV, TypeN)
% gKontBU - выходной массив типа CGraph, содеражащий контура типа ЦП-ЦП, а
% также контуры, созданные линиями, отходящими от одного ЦП;
% gKontPU - выходной массив типа CGraph, содержащий контуры типа ЦП-ИГ
%(источник генерации);
% gCycle - выходной массив типа CGraph, содержащий циклы;
% g - объект CGraph, содержащий связанную подсхему, из которой будет
% происходить выделение контуров;
% hFN - handle ссылки на начало ветвей в модели сети;
% hFV - handle ссылки на концы ветвей в модели сети;
% TypeN - Типы узлов в формате nTip.
% Nop - (резервный) номер опорного центра питания;
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% August 2017 Mod December 2017.

% инициализация переменных
if g.nod.n==0||g.rib.n==0
   gKontBU=[];
   gKontPU=[];
   gCycle=[];
   return;
end
Nmod(g.nod.n)=0;
Rmod(g.rib.n,2)=0;
count=0;
nBU=0;
nPU=0;
BU=[];
PU=[];
PromGraph=CGraph;
gKontBU=PromGraph(1:0);
gKontPU=PromGraph(1:0);
gCycle=PromGraph(1:0);
if isempty(hFN)||isempty(hFV)
    option='Граф';
else
    option='Модель';
end
switch option
    case 'Модель'
    case 'Граф'
        hFN=(1:g.nod.n);
        hFV=@(I)[g.rib(I).ny1 g.rib(I).ny2];
    otherwise
        hFN=(1:g.nod.n);
        hFV=@(I)[g.rib(I).ny1 g.rib(I).ny2];
        warning('Неправильно задана опция в разбиении контуров принято Граф');
end
 % служит для создания массивов нулевой длины типа CGraph
% подсчет количества и создание выборок узлов типа BU и PU
for i=1:g.nod.n
    if strcmpi(option,'Модель')
        iProm=g.nod(i);
    else
        iProm=i;
    end
    if TypeN(iProm) == nTip.BU
        nBU=nBU+1;
        BU(nBU)=i;
    elseif TypeN(iProm) == nTip.PU
        nPU=nPU+1;
        PU(nPU)=i;
    end
end

    
% подсчет количества циклов в графе (с учетом контуров, созданных
% отходящими от одного ЦП линиями)
nKont123=g.rib.n-g.nod.n+1;
% запуск основной подпрограммы поиска контуров, если присутствует хотя бы
% один вид контуров
if (nBU>1)||(nPU>0)||(nKont123>0)
    % выбор опорного узла для выделения контуров
    OU=BU(1);
    % инициализация модифицированных массивов узлов и ветвей в графе
    % для фиктивного разделения источников питания с несколькими отходящими линиями
    Nmod=1:g.nod.n;
    for i=1:g.rib.n
        Rmod(i,1)=g.rib(i).ny1;
        Rmod(i,2)=g.rib(i).ny2;
    end
    CurrN = length(Nmod); % инициализация переменной текущего количества узлов
    NumbNewNod=0; % инициализация переменной количества новых узлов
    % расчет необходимого количества новых узлов и ветвей
    for i=1:length(BU)
        NumbNewNod=NumbNewNod+length(g.nod(BU(i)).ar) - 1;
    end
    % пересчет количества циклов с учетом контуров, образованных
    % источниками питания с несколькими отходящими линиями
    nKont123=nKont123-NumbNewNod;
    % Добавление элементов в мод. массив номеров узлов в графе в
    % соответствии с кол-вом добавленных узлов
    if NumbNewNod>0
        Nmod(length(Nmod)+NumbNewNod)=0;
    end
    % цикл перебора источников питания
    for i=1:length(BU)
        AR=g.nod(BU(i)).ar; % массив отходящих ветвей
        % если от ИП отходит более одной линии, то добавляем узлы
        if length(AR)>1
            for j=2:(length(AR)) % цикл по всем отходящим линиям
                % увеличиваем количество узлов на 1 (фиктивные узлы записываются в конец массива!!!, Nmod - массив
                % соответствия узлов между модифицированным и начальным графом
                CurrN=CurrN+1;
                Nmod(CurrN)= BU(i);
                % Изменяем один из концов ветви отходящей от данного ЦП,
                % так чтобы он был подключен к созданному узлу
                if Rmod(AR(j),1)== BU(i) % если начало - БУ
                    Rmod(AR(j),1)=CurrN;
                elseif Rmod(AR(j),2)==BU(i) % если конец - БУ
                    Rmod(AR(j),2)=CurrN;
                end
            end
        end
    end
    % создание handle на мод. массив ветвей
    hFVmod=@(I)[Rmod(I,1) Rmod(I,2)];
    % создание модифицированного графа (нумерация узлов и ветвей
    % соответствует Nmod и Rmod и начальному графу, за исключением добавленных узлов)
    gMod=CGraph([1:CurrN], [1:CurrN], hFVmod, [1:size(Rmod,1)]);
    
    % если есть контуры типа ЦП-ЦП и ЦП-ИГ запускаем алгоритм поиска путей, источник номеров узлов и ветвей - "Граф",
    % создаем массив графов, содержащий искомые пути (контуры ЦП-ЦП, ЦП-ИГ),
    % если нет - создаем массив графов CGraph нулевой длины
    if (nBU-1+nPU+NumbNewNod)<1
        gKontCP = PromGraph(1:0);
    else
        gKontCP =  fGraphSearch(gMod, hFN, hFV, OU, [BU(2:end),[g.nod.n+1:CurrN],PU(1:end)], 'Граф');
    end
    
    % если есть циклы в графе запускаем алгоритм поиска циклов, источник номеров узлов и ветвей - "Граф",
    % создаем массив графов, содержащий искомые циклы,
    % если нет - создаем массив графов CGraph нулевой длины
    if (nKont123)<1
        gCycleProm = PromGraph(1:0);
    else
        gCycleProm = fGraphCycle(gMod, hFN, hFV, OU, 'Граф');
    end
    clear gMod; clear Rmod; clear AN; clear AR;
    
    % инициализируем подграф, содержащий приведенные к модели номера узлов
    % и ветвей (в подпрограмме fKont используется "Граф") фиктивные узлы
    % удалены, номер начал и концов ветвей, как в модели, если нет контуров
    % ЦП-ЦП ЦП-ИГ, то инициализируем графом нулевой длины
    if (nBU-1+nPU+NumbNewNod)<1
        gKontRet = PromGraph(1:0);
    else
        gKontRet(nBU-1+nPU+NumbNewNod) = CGraph;
    end
    
    for i=1:length(gKontCP) % цикл по всем контурам ЦП-ЦП, ЦП-ИГ
        % инициализируем переменные, использумые для хранения переведенных
        % номеров узлов и ветвей
        NodReturn(1:gKontCP(i).nod.n)=0;
        RibReturn(1:gKontCP(i).rib.n)=0;
        Count=0;
        % удаление излишних элементов, оставшихся после предыдущей итерации
        if length(NodReturn)>gKontCP(i).nod.n
            RibReturn(gKontCP(i).nod.n+1:end)=[];
        end;
        if length(RibReturn)>gKontCP(i).rib.n
            RibReturn(gKontCP(i).rib.n+1:end)=[];
        end;
        % удаление фиктивных узлов, приведение номеров к модели
        for j=1:gKontCP(i).nod.n
            % если узел не фиктивный (фиктивные в конце), то приводим номер
            % узла, входящего в контур, к модели и запоминаем
            if gKontCP(i).nod(j)<=g.nod.n
                Count=Count+1; % счетчик количества нефиктивных узлов
                % приведение номера узла к модели, запись в массив
                % если узел не опорный (чтобы не дублировать его в цикле),
                % приводятся номера узлов в мод. графа к номерам узлов в
                % начальном графе, далее приводятся к номерам узлов в модели
                if strcmpi(option, 'Модель')
                NodReturn(Count)= g.nod(gKontCP(i).nod(j));
                else
                NodReturn(Count)= gKontCP(i).nod(j);
                end
            elseif Nmod(gKontCP(i).nod(j))~=OU
                Count=Count+1;
                if strcmpi(option, 'Модель')
                NodReturn(Count)= g.nod(Nmod(gKontCP(i).nod(j)));
                else
                NodReturn(Count)= Nmod(gKontCP(i).nod(j));
                end
            end
        end
        % удаление излишних элементов после предыдущих операций после
        % уточнения количества элементов NodReturn для цикла
        if length(NodReturn)>Count
            NodReturn(Count+1:end)=[];
        end;
        % запись в массив номеров ветвей из начального графа, входящих в
        % контур
        if strcmpi(option, 'Модель')
        RibReturn=g.rib(gKontCP(i).rib(:));
        else
        RibReturn=gKontCP(i).rib(:);
        end
        % создание массив графов, содержащего результат в номерах модели
        gKontRet(i) = CGraph(hFN, NodReturn, hFV, RibReturn);
    end
    clear gKontCP;
    clear NodReturn;
    clear RibReturn;
    % разбиение массива графов на 2 составляющие ЦП-ЦП и ЦП-ИГ
    if nBU-1+NumbNewNod>0
        gKontBU = gKontRet(1:(nBU-1+NumbNewNod));
    else
        gKontBU = PromGraph(1:0);
    end
    if nPU>0
        gKontPU = gKontRet((nBU+NumbNewNod):end);
    else
        gKontPU = PromGraph(1:0);
    end
    clear gKontRet;
    % инициализируем подграф, содержащий приведенные к модели номера узлов
    % и ветвей (в подпрограмме fKont используется "Граф"), если нет циклов
    % , то инициализируем графом нулевой длины
    if (nKont123)<1
        gCycle = PromGraph(1:0);
    else
        gCycle(nKont123) = CGraph;
    end
    % итерации по всем циклам графа
    for i=1:length(gCycleProm)
        % инициализируем переменные, использумые для хранения переведенных
        % номеров узлов и ветвей
        NodReturn(1:gCycleProm(i).nod.n)=0;
        RibReturn(1:gCycleProm(i).rib.n)=0;
        % удаляем излишние элементы после предыдущих итераций
        if length(NodReturn)>gCycleProm(i).nod.n
            RibReturn(gCycleProm(i).nod.n+1:end)=[];
        end;
        if length(RibReturn)>gCycleProm(i).rib.n
            RibReturn(gCycleProm(i).rib.n+1:end)=[];
        end;
        % приводим номера в графе к номерам узлов в модели, записываем
        if strcmpi(option, 'Модель')
        NodReturn= g.nod(gCycleProm(i).nod(:));
        RibReturn=g.rib(gCycleProm(i).rib(:));
        else
        NodReturn= gCycleProm(i).nod(:);
        RibReturn=gCycleProm(i).rib(:);
        end

        % приводим номера в графе к номерам ветвей в модели, записываем
        % создание массива графов, содержащего результат (циклы) в номерах
        % модели (данный элемент является выходным в подпрограмме)
        gCycle(i) = CGraph(hFN, NodReturn, hFV, RibReturn);
    end
end
end