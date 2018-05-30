classdef CGraph
    % CGraph  Value-класс строит граф схемы и предоставляет интерфейсы для
    % работы с графом. Конструктор класса возвращает созданный объект
    % класса.
    %
    % Поддерживается следующий синтаксис обращения к объекту g данного
    % класса:
    % g.nod.n - число узлов графа;
    % g.nod(i) - массив индексов узлов схемы;
    % g.nod(i).an - массив индексов смежных узлов графа
    % g.nod(i).ar - массив индексов смежных ветвей графа
    % g.rib.n - число ветвей графа;
    % g.rib(i) - массив индексов ветвей схемы;
    % g.rib(i).ny1 - массив индексов узлов начала (в nod)
    % g.rib(i).ny2 - массив индексов узлов конца (в nod)
    %
    % Written by A.Zolotoy
    % Research group of energetic faculty,
    % department of BNTU.
    % April 2017, June 2017.
    
    properties(Access = private)
        nod   % Массив длиной n индексов узлов в общем массиве данных по узлам схемы длиной N (n <= N)
        ira   % Массив чисел смежных узлов длиной n, где n - число узлов
        lra   % Массив начал расположения адресов смежных узлов и ветвей в массивах ka и kb длиной n, где n - число узлов
        rib   % Массив длиной m индексов ветвей в общем массиве данных по ветвям схемы длиной M (m <= M)
        ny1   % Массив адресов узлов начала ветвей (в nod) длиной m, где m - число ветвей
        ny2   % Массив адресов узлов конца ветвей (в nod) длиной m, где m - число ветвей
        ka    % Массив адресов смежных узлов (в nod) длиной 2m, где m - число ветвей
        kb    % Массив адресов смежных ветвей (в rib) длиной 2m, где m - число ветвей
        ny    % количество узлов
        nb    % количество ветвей
    end
    
    methods
        function g = CGraph(varargin)
            % CGraph  Конструктор.
            %
            % g = CGraph
            % g = CGraph(g1)
            % g = CGraph(hFN, I, hFV, J)
            %
            % g = CGraph конструктор по умолчанию. Создаёт пустой объект.
            %
            % g = CGraph(g1) конструктор копирования. Копирует данные из
            % объекта g1 аналогичного типа.
            %
            % g = CGraph(hFN, I, hFV, J) строит граф по схемным данным.
            % I, J - массивы индексов узлов и ветвей в данных по схеме
            % размерами n-на-1 и m-на-1, где n - число узлов, m - число
            % ветвей; hFN, hFV - handles функций, которые по индексам в
            % массивах данных возвращают номера узлов и ветвей схемы.
            % N = hFN(I) - возвращает массив n-на-1 номеров узлов схемы;
            % V = hFN(J) - возвращает массив m-на-1 номеров ветвей схемы
            % (V(:,1) - номера начал, V(:,2) - номера концов).
            
            if isempty(varargin)
                return
            elseif length(varargin) == 1
                if isa(varargin{1}, 'CGraph')
                    g = varargin{1};
                else
                    error('Ожидался объект типа "CGraph".');
                end
            elseif length(varargin) == 4
                hFN = varargin{1};
                I = varargin{2};
                hFV = varargin{3};
                J = varargin{4};
                
                g.ny = length(I);
                g.nb = length(J);
                g.nod = I;
                g.ira = zeros(g.ny, 1);
                g.lra = zeros(g.ny, 1);
                g.rib = J;
                g.ny1 = zeros(g.nb, 1);
                g.ny2 = zeros(g.nb, 1);
                g.ka = zeros(2, 1);
                g.kb = zeros(2, 1);
                
                N = hFN(I);
                V = hFV(J);
                if isempty(V)==0
                    g = g.CalcAdr(N, V);
                end
            else
                msg = ['Неверное количество входных аргументов - \n',...
                    '%s\n%s\n%s'];
                error(msg, 'g = CGraph;', 'g = CGraph(g1);',...
                    'g = CGraph(hFN, I, hFV, J).'); %#ok<CTPCT>
            end
        end
        
        function B = subsref(g, S)
            % Метод индексной ссылки. Выполняет обращение к полям объекта
            % по принятым правилам синтаксиса индексации.
            %
            % B = subsref(g, S)
            %
            % g - объект; S - массив структур индексации объекта; B -
            % результат обращения к объекту по индексной ссылке.
            
            if length(S) == 2 &&...
                    strcmp(S(1).type, '.') &&...
                    strcmp(S(2).type, '.') &&...
                    strcmp(S(2).subs, 'n')
                % Число элементов графа (g - скаляр)
                switch S(1).subs
                    case 'nod'
                        B = g.ny;
                    case 'rib'
                        B = g.nb;
                    otherwise
                        B = 0;
                end
            elseif length(S) == 3 &&...
                    strcmp(S(1).type, '()') &&...
                    strcmp(S(2).type, '.') &&...
                    strcmp(S(3).type, '.') &&...
                strcmp(S(3).subs, 'n')
                % Число элементов графа (g - матрица)
                switch S(2).subs
                    case 'nod'
                        str = g.s2str(S(1));
                        B = eval(['length(g', str, '.nod)']);
                    case 'rib'
                        str = g.s2str(S(1));
                        B = eval(['length(g', str, '.rib)']);
                    otherwise
                        B = 0;
                end
            elseif length(S) > 2 &&...
                    strcmp(S(end-2).type, '.') &&...
                    strcmp(S(end-1).type, '()') &&...
                    strcmp(S(end).type, '.') &&...
                    strcmp(S(end).subs, 'ny')
                if strcmp(S(end-2).subs, 'rib')
                    if length(S) > 3
                    str1 = [g.s2str(S(1))];
                    else
                        str1='';
                    end
                    str2 = [g.subs2str(S(end-1))];
                    B(:,1) = eval(['g',str1,'.ny1',str2]);
                    B(:,2) = eval(['g',str1,'.ny2',str2]);
                    return;
                else
                    B = 0;
                end
            else
                % Параметры элементов графа
                if length(g(:)) < 2 && strcmp(S(1).type, '.')
                    str = g.subs2str(S);
                elseif length(S) < 2
                    str = g.s2str(S(1));
                else
                    str = [g.s2str(S(1)), g.subs2str(S(2:end), 2)];
                end
                B = eval(['g', str]);
            end
        end
        
        function TF = isempty(g)
            % Метод возвращает true если объект пустой.
            %
            % TF = isempty(g)
            %
            % g - объект.
            
            TF = isempty(g.nod) && isempty(g.rib);
        end
    end
    
    methods(Access = private)
        function g = CalcAdr(g, N, V)
            % Метод вычисляет адресные отображения.
            %
            % g = CalcAdr(g, N, V)
            %
            % N - массив размером n-на-1 номеров узлов схемы, где n - число
            % узлов; V - массив размером m-на-2 номеров ветвей схемы, где
            % m - число ветвей (V(:,1) - номера начал, V(:,2) - номера
            % концов).
            
            %ny = length(g.nod);
            %nb = length(g.rib);
            
            % Адресные отображения ветвей:
            for i = 1:g.ny
                g.ny1(V(:,1) == N(i)) = i;
                g.ny2(V(:,2) == N(i)) = i;
            end
            
            % Адресные отображения узлов:
            jrab = 0;
            for i = 1:g.ny
                irab = 0;
                for j = 1:g.nb
                    if (i == g.ny1(j))
                        jrab = jrab + 1;
                        irab = irab + 1;
                        g.ka(jrab) = g.ny2(j);
                        g.kb(jrab) = j;
                    end;
                    if (i == g.ny2(j))
                        jrab = jrab + 1;
                        irab = irab + 1;
                        g.ka(jrab) = g.ny1(j);
                        g.kb(jrab) = j;
                    end
                    g.lra(i) = jrab - irab;
                end
                g.ira(i) = irab;
            end
        end
        
        function K = getan(g, I)
            % Метод возвращает массивы индексов смежных узлов графа.
            %
            % K = getan(g, I)
            %
            % g - объект; I - массив индексов узлов длиной n, где n - число
            % узлов, для которых требуется вернуть массивы индексов смежных
            % узлов; K - массивы индексов смежных узлов.
            %
            % I может быть скаляром или вектором. Есди I скаляр, то K
            % является массивом индексов узлов графа размером k-на-1, где
            % k - число узлов, смежных узлу графа с индексом, указанном в
            % I. Если I вектор, то К является массивом ячеек (cell array)
            % размером n-на-1, где n - длина вектора I. В каждой ячейке
            % массива К содержится массив индексов узлов графа, смежных
            % узлу, индекс которого указан в соответствующем элементе
            % массива I.
            
            if length(I) > 1
                K = cell(length(I), 1);
                for i = 1:length(I)
                    lrab = g.lra(I(i)) + 1;
                    irab = g.lra(I(i)) + g.ira(I(i));
                    K{i} = g.ka(lrab:irab);
                end
            else
                lrab = g.lra(I) + 1;
                irab = g.lra(I) + g.ira(I);
                K = g.ka(lrab:irab);
            end
        end
        
        function K = getar(g, I)
            % Метод возвращает массивы индексов смежных ветвей графа.
            %
            % K = getar(g, I)
            %
            % g - объект; I - массив индексов узлов длиной n, где n - число
            % узлов, для которых требуется вернуть массивы индексов смежных
            % ветвей; K - массивы индексов смежных веьвей.
            %
            % I может быть скаляром или вектором. Есди I скаляр, то K
            % является массивом индексов ветвей графа размером k-на-1, где
            % k - число ветвей, смежных узлу графа с индексом, указанном в
            % I. Если I вектор, то К является массивом ячеек (cell array)
            % размером n-на-1, где n - длина вектора I. В каждой ячейке
            % массива К содержится массив индексов ветвей графа, смежных
            % узлу, индекс которого указан в соответствующем элементе
            % массива I.
            
            if length(I) > 1
                K = cell(length(I), 1);
                for i = 1:length(I)
                    lrab = g.lra(I(i)) + 1;
                    irab = g.lra(I(i)) + g.ira(I(i));
                    K{i} = g.kb(lrab:irab);
                end
            else
                lrab = g.lra(I) + 1;
                irab = g.lra(I) + g.ira(I);
                K = g.kb(lrab:irab);
            end
        end
        
        function Str = subs2str(g, S, i)
            % Метод преобразует массив структур индексации объекта в строку.
            % Определяет правила индексации объекта. Использкется в методах
            % subsref и subsasgn.
            %
            % Str = subs2str(S)
            %
            % g - объект; S - массив структур индексной ссылки; i -
            % абсолютный индекс первого элемента в массиве структур S для
            % формирования относительного индекса в строке индексации
            % объекта; Str - строка индексации объекта.
            %
            % Поддерживается следующий синтаксис обращения к объекту:
            % g.nod.n - число узлов графа;
            % g.nod(i) - массив индексов узлов схемы;
            % g.nod(i).an - массив индексов смежных узлов графа
            % g.nod(i).ar - массив индексов смежных ветвей графа
            % g.rib.n - число ветвей графа;
            % g.rib(i) - массив индексов ветвей схемы;
            % g.rib(i).ny1 - массив индексов узлов начала (в nod)
            % g.rib(i).ny2 - массив индексов узлов конца (в nod)
            % g.rib(i).kc1 - массив индексов параметров начала ветвей графа
            % g.rib(i).kc2 - массив индексов параметров конца ветвей графа
            
            if nargin < 3
                i = 1;
            end
            
            if strcmp(S(1).type, '.') && (...
                    strcmp(S(1).subs, 'nod') || strcmp(S(1).subs, 'rib'))
                % Обращение к полям объекта с изменением синтаксиса
                switch length(S)
                    case 1
                        Str = [S(1).type, S(1).subs];
                    case 2
                        if ~strcmp(S(2).type, '()')
                            msg = ['На %d-м уровне ожидается тип ',...
                                'индекса "()".'];
                            error(msg, i+1)
                        end
                        Str = [S(1).type, S(1).subs,...
                            S(2).type(1), mat2str(S(2).subs{1}), S(2).type(2)];
                    case 3
                        if ~strcmp(S(3).type, '.')
                            msg = ['На %d-м уровне ожидается тип ',...
                                'индекса ".".'];
                            error(msg, i+2)
                        end
                        switch S(3).subs
                            case 'an'
                                if strcmp(S(1).subs, 'nod')
                                    Str = [S(3).type, 'getan(S(',...
                                        mat2str(i+1),').subs{1})'];
                                else
                                    msg = ['На %d-м уровне индексации ',...
                                        'ожидался строковый индекс ',...
                                        '"nod".'];
                                    error(msg, i)
                                end
                            case 'ar'
                                if strcmp(S(1).subs, 'nod')
                                    Str = [S(3).type, 'getar(S(',...
                                        mat2str(i+1),').subs{1})'];
                                else
                                    msg = ['На %d-м уровне индексации ',...
                                        'ожидался строковый индекс ',...
                                        '"nod".'];
                                    error(msg, i)
                                end
                            case {'ny1', 'ny2', 'ny'}
                                if strcmp(S(1).subs, 'rib')
                                    Str = [S(1).type, S(3).subs,...
                                        S(2).type(1), mat2str(S(2).subs{1}),...
                                        S(2).type(2)];
                                else
                                    msg = ['На %d-м уровне индексации ',...
                                        'ожидался строковый индекс ',...
                                        '"rib".'];
                                    error(msg, i)
                                end
                        end
                    otherwise
                        msg = 'Ожидалось %d или %d уровня индексации.';
                        error(msg, i, i+2)
                end
            else
                % Остальные случаи обращения - без изменения синтаксиса
                Str = g.s2str(S);
            end
        end
    end
    methods(Static, Access = private)
        function Str = s2str(S)
            % Метод преобразует массив структур индексации объекта в строку
            % без изменения синтаксиса обращения.
            %
            % Str = s2str(S)
            %
            % S - массив структур индексной ссылки; Str - строка индексации
            % объекта.
            
            Str = [];
            for i = 1:length(S)
                switch S(i).type
                    case '()'
                        Str = [Str, S(i).type(1)]; %#ok<AGROW>
                        for j = 1:length(S(i).subs)
                            Str = [Str, mat2str(S(i).subs{j})]; %#ok<AGROW>
                            if j < length(S(i).subs)
                                Str = [Str, ',']; %#ok<AGROW>
                            end
                        end
                        Str = [Str, S(i).type(2)]; %#ok<AGROW>
                    case '.'
                        Str = [Str, S(i).type, S(i).subs]; %#ok<AGROW>
                end
            end
        end
    end
end