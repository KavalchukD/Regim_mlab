classdef CData
    % CData  Value-класс обеспечивает ввод исходных данных
    % в модель сети из Excel-файла.
    
    % Written by D. Kovalchuk
    % Research group of energetic faculty,
    % department of BNTU.
    % Jule 2017 Mod December 2017
    
    properties(Access = private)
        % Поля объекта хранят данные в виде структур (COMM) или структур
        % массивов (NODE, VETV). При обращении к полям NODE, VETV,
        % синтаксис изменяется, имитируя обращение к массивам
        % структур.
        COMM  % Структура общей информации
        NODE  % Структура информации по узлам
        BRAN  % Структура информации по ветвям
    end
    
    methods
        function hDt = CData (xlsFile, options)
            % CData  Конструктор.
            %
            % hDt = Cdata(xlsFile, options)
            %
            % xlsFile - строковое имя файла MsExcel с данными по схеме сети;
            % options - структура параметров, необходимых для развётрывания
            % модели;
            %
            % Поля структуры options:
            % options.NodeSheet - номер листа в файле MsExcel с данными
            % по узлам;
            % options.BranchSheet - номер листа в файле MsExcel с данными
            % по ветвям;
            % options.KatLinesSheet - номер листа в файле MsExcel с
            % каложными данными по линиям;
            % options.KatTransSheet - номер листа в файле MsExcel с
            % каложными данными по трансформаторам
            % options.Method - метод ввода исходных данных.
            
            % УЗЛЫ
            [Data.Sub.Text, Data.Sub.Num, Data.Txt, Data.Num] = hDt.fread(xlsFile, options.NodeSheet, options);
            hDt.NODE = struct(...
                ... % Данные
                'Nn1',   int32(Data.Num(:,2)),...        % Пользовательские номера узлов
                'Type',  nTip(Data.Num(:,11)),... % Типы узлов (BU, PU или PQ)
                'Pn',    Data.Num(:,3),...        % Активная мощность нагрузки
                'Qn',    Data.Num(:,4),...        % Реактивная мощность нагрузки
                'Pg',    Data.Num(:,5),...        % Активная мощность генерации
                'Qg',    Data.Num(:,6),...        % Реактивная мощность генерации
                'Qmin',  Data.Num(:,7),...        % Минимальный предел реактивной мощности
                'Qmax',  Data.Num(:,8),...       % Максимальный предел реактивной мощности
                'Uu',    Data.Num(:,9),...       % Уставка напряжения генератора (ЦП)
                'dUu',   Data.Num(:,10)...       % Угол напряжения (ЦП)   
                );
            hDt.COMM = struct(...
                'TolFun', options.TolFun,...   % Точность вычислений
                'Un', Data.Num(1,1)...         % Номинальное напряжение, кВ
                );
            clear Data;
            [Data.Sub.Text, Data.Sub.Num, Data.Txt, Data.Num] = hDt.fread(xlsFile, options.BranchSheet, options);
            hDt.BRAN = struct(...
                ... % Данные
                'Nb1',    int32(Data.Num(:,1)),...          % Пользовательские номера ветвей
                'NbSt',   int32(Data.Num(:,2)),...           % Номер узла начала
                'NbF',    int32(Data.Num(:,3)),...           % Номер узла конца
                'CmTpS',  cmTip(Data.Num(:,10)),...   % Тип КА в начале
                'CmStS',  cmStat(Data.Num(:,11)),...  % Состояние КА в начале
                'CmTpF',  cmTip(Data.Num(:,12)),...   % Тип КА в конце
                'CmStF',  cmStat(Data.Num(:,13)),...  % Состояние КА в конце
                'Type',   bTip(Data.Num(:,9)),...    % Тип ветви
                'R',      Data.Num(:,4),...           % Активное сопротивление
                'X',      Data.Num(:,5),...           % Реактивное сопротивление
                'Pxx',    Data.Num(:,6),...           % Активная мощность холостого хода
                'Qxx',    Data.Num(:,7),...           % Реактивная мощность холостого хода
                'kt',     Data.Num(:,8)...            % Коэффициент трансформации
                );          
        clear Data;        
        end;
        
        function hDt = subsasgn(hDt, S, B)
            % Метод индексного присваивания. Выполняет присваивание полям
            % объекта новых значений. Синтаксис индексации полей объекта
            % осуществляется по принятым правилам.
            %
            % hDt = subsasgn(hDt, S, B)
            %
            % hDt - объект; S - структура индексации объекта; B -
            % присваиваемое значение.
            
            str = hDt.subs2str(S);
            eval(['hDt', str, '=', num2str(B),';']);
        end
        
        function B = subsref(hDt, S)
            % Метод индексной ссылки. Выполняет обращение к полям объекта
            % по принятым правилам синтаксиса индексации.
            %
            % B = subsref(hDt, S)
            %
            % hDt - объект; S - структура индексации объекта; B -
            % результат обращения к объекту по индексной ссылке.
            if length(S) == 1
                str=[S.type,S.subs];
                B = eval(['hDt', str]);
            elseif length(S) == 2 &&...
                    strcmp(S(2).type, '.') &&...
                    strcmp(S(2).subs, 'n')
                
                % Число элементов
                switch S(1).subs
                    case 'NODE'
                        B = length(hDt.NODE.Nn);
                    case 'BRANCH'
                        B = length(hDt.VETV.Nb);
                    otherwise
                        B = 0;
                        warning ('Невозможно найти длину поля %s (не существует)',S);
                end
            else
                % Параметры элементов
                str = hDt.subs2str(S);
                B = eval(['hDt', str]);
            end
        end
    end
    
    methods(Access = private)
        
        function [SubText, SubNumb ,DataText,DataNumb] = fread (hDt, xlsFile, NumSheet, options)
            % Метод существляет выбор способа считывания данных.
            % (реализован ввод данных из Excel, функция служит для
            % возможности расширения функционала).
            %
            % [SubText, SubNumb ,DataText, DataNumb] = fread (hDt, xlsFile, NumSheet, options)
            %
            % SubText - подписи в текстовом виде; SubNumb - подписи в
            % текстовом виде; DataText - данные в текстовой форме; DataNumb
            % - данные в цифровой форме.
            % hDt - объект, xlsFile - имя файла в виде строки, NumSheet -
            % номер листа в Excel, options - опции считывания данных
            if (options.Method ==  methTip.XLS)
                [SubText, SubNumb ,DataText,DataNumb] = hDt.fxlsread(xlsFile, NumSheet, options);
                %else if (options.Method ==  methTip.MANUAL)
                % Data= fmanualIn (Data);
                
            else
                error(['Неустановленный метод ввода данных']);
            end
        end
               
        function [SubText, SubNumb ,DataText,DataNumb] = fxlsread (hDt, xlsFile, NumSheet, options)
            % Метод считывания и обработки данных в формате xls
            % Обработка включает разбиение объема информации на текстовую и
            % цифровую
            %
            % [SubText, SubNumb ,DataText, DataNumb] = fxlsread (hDt, xlsFile, NumSheet, options)
            %
            % hDt - объект; xlsFile - имя файла; NumSheet - номер
            % считываемого листа; options - опции считывания данных.
            % SubText - текстовая подпись; SubNumb - цифровая подпись;
            % DataText - текстовые данные; DataNumb - численные данные.
            
            % чтение данных из файла
            [Xls.Num, Xls.Txt, Xls.Full] = xlsread (xlsFile, NumSheet);
            % интерпретация данных в зависимости от типа прочитанного (узлы, ветви, каталоги)
            switch NumSheet
                case options.NodeSheet % для данных по узлам
                    SubText = Xls.Full(2,2:3);
                    SubNumb = [Xls.Full(1,1),Xls.Full(2,1),Xls.Full(2,4:11), Xls.Full(2,3)];
                    DataText = Xls.Full(3:(size(Xls.Num,1)),2:3);
                    DataNumb = [zeros(size(Xls.Num,1)-2,1),...
                        cell2mat([Xls.Full(3:(size(Xls.Num,1)),1),...
                        Xls.Full(3:(size(Xls.Num,1)),4:11)])];
                    DataNumb(1,1)=cell2mat(Xls.Full(1,2));
                    % Перевод типа узла из текстового в цифровой вид и
                    % замена неопределенных типов узлов на нагр
                    DataNumb(:,11)=hDt.ftype(DataText(:,2), Tip.N);       
                case options.BranchSheet % для данных по ветвям
                    SubText = [Xls.Full(2,2),Xls.Full(2,5:6)];
                    SubNumb = [Xls.Full(2,1),Xls.Full(2,3:4),Xls.Full(2,7:11),Xls.Full(2,6)];
                    DataText = [Xls.Full(2:(size(Xls.Num,1)+1),2),Xls.Full(2:(size(Xls.Num,1)+1),5:6)];
                    DataNumb = cell2mat([Xls.Full(2:(size(Xls.Num,1)+1),1),...
                        Xls.Full(2:(size(Xls.Num,1)+1),3:4), Xls.Full(2:(size(Xls.Num,1)+1),7:11)]);
                    DataNumb(:,9)=hDt.ftype(DataText(:,3), Tip.B);
                    DataNumb(:,10:13)=hDt.ftype(DataText(:,2), Tip.Commt);    
                otherwise
                    error ('Неверный номер листа xls-файла. CData');
            end
            DataNumb(isnan(DataNumb)) = 0;  % Заменяем NaN на 0
        end    
    end
    
    methods(Static, Access = private)
        
        function Numb = ftype (Text, Object)
            % Метод перевод типов узлов и ветвей из формата текст в
            % цифровой для упрощения дальнейшего использования
            %
            % Numb = ftype(Text, Object);
            %
            % Text - столбец текстовой информации; Object - тип объекта
            % Tip.N, Tip.V, Commt.
            % Numb - информация об объекте в цифровом виде
            
            % выбор из трех типов объектов
            switch Object
                case Tip.N % узел
                    for i=1:size(Text,1)
                        switch 1
                            case (strcmpi(Text(i),'Нагр'))
                                Numb(i,1) = 1;
                            case (strcmpi(Text(i),'ЦП'))
                                Numb(i,1) = 2;
                            case (strcmpi(Text(i),'Ген'))
                                Numb(i,1)= 3;
                            otherwise
                                Numb(1,i) = 1;
                                warning (...
                                    'Неопределенный тип узла в строке %s файла\nТип установлен "Нагрузка"'...
                                    ,mat2str(i));
                        end
                    end
                case Tip.B % ветвь
                    for i=1:size(Text,1)
                        switch 1
                            case (strcmpi(Text(i),'Линия'))
                                Numb(i,1) = 1;
                            case (strcmpi(Text(i),'Транс'))
                                Numb(i,1) = 2;
                            otherwise
                                Numb(i,1) = 1;
                                warning (...
                                    'Неопределенный тип ветви в строке %s файла\nТип установлен "Линия"'...
                                    ,mat2str(i));
                        end
                    end
                    
                case Tip.Commt % коммутационный аппарат
                    clear k;
                    for i=1:size(Text,1)
                        k=Text{i};
                        if length(k)==4
                            for j= [1,3]
                                switch 1
                                    case (strcmpi(k(j),'Р'))
                                        Numb(i,j) = 1;
                                    case (strcmpi(k(j),'В'))
                                        Numb(i,j) = 2;
                                    case (strcmpi(k(j),'Н'))
                                        Numb(i,j) = 3;
                                    case (strcmpi(k(j),' '))
                                        Numb(i,j) = 4;
                                    otherwise
                                        Numb(i,j) = 4;
                                        warning (...
                                            'Неопределенный тип коммутационного аппарата в строке %s файла\nТип установлен " "'...
                                            ,mat2str(i));
                                end
                                switch 1
                                    case (strcmp(k(j+1),'0'))
                                        Numb(i,j+1) = 0;
                                    case (strcmp(k(j+1),'1'))
                                        Numb(i,j+1) = 1;
                                    case (strcmp(k(j+1),'2'))
                                        Numb(i,j+1) = 2;
                                    case (strcmp(k(j+1),'3'))
                                        Numb(i,j+1) = 3;
                                    case (strcmp(k(j+1),' '))
                                        Numb(i,j+1) = 3;
                                    otherwise
                                        Numb(i,j+1) = 3;
                                        warning (...
                                            'Неопределенное состояние коммутационного аппарата в строке %s файла\n установлено " "'...
                                            ,mat2str(i));
                                end
                            end
                        else
                            Numb(i,:) = [4,0,4,0]
                            warning ('Неверное количество символов в описании КА в строке %s файла\nТип установлен "    "'...
                                ,mat2str(i));
                        end
                    end
            end
        end
        
        
        function Str = subs2str(S)
            % Метод преобразует структуру индексации объекта в строку.
            % Определяет правила индексации объекта. Используется в методах
            % subsref и subsasgn.
            %
            % Str = subs2str(S)
            %
            % S - структура индексной ссылки; Str - строка индексации
            % объекта.
            %
            % Данные в полях объекта хранятся в виде структур массивов.
            % Однако при обращении к полям объекта применяется синтаксис
            % обращения к массивам структур. Метод subs2str как раз и
            % выполняет указанную подмену синтаксиса обращения.
            %
            % Реализованный синтаксис индексации полей объекта
            % иллюстрируется на следующих примерах обращения:
            %
            % a = hDt.NODE.Pn;
            
            if ~strcmp(S(1).type, '.')
                error(['На первом уровне индексации ожидается тип индекса ".".'])
            end
            
            switch length(S)
                case 2
                    if ~strcmp(S(2).type, '.')
                        error(['На втором уровне индексации ожидается тип индекса ".".'])
                    end
                    Str = [S(1).type, S(1).subs, S(2).type, S(2).subs];
                case 3
                    switch S(2).type
                        case '.'
                            Str = [S(1).type, S(1).subs, S(2).type,...
                                S(2).subs, S(3).type, S(3).subs];
                        case '()'
                            Str = [S(1).type, S(1).subs, S(3).type,...
                                S(3).subs, S(2).type(1),...
                                mat2str(S(2).subs{1}), S(2).type(2)];
                        otherwise
                            error(['На втором уровне индексации ожидается тип индекса "." или "()".'])
                    end
                otherwise
                    error('Ожидалось два или три уровня индексации.')
            end
        end
    end
end