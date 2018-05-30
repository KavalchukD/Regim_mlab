classdef CModelRS < handle
    % CModelRS  Handle-класс читает из указанного объекта с данными по
    % схеме распределительной электричекой сети, обеспечивает их хранение и
    % предоставление доступа. Осуществляет дорасчет дополнительных
    % параметров
    %
    % Written by A.Zolotoy Mod Kovalchuk
    % Research group of energetic faculty,
    % department of BNTU.
    % April 2017 mod December 2017.
    
    properties(Access = private)
        % Поля объекта хранят данные в виде структур (COMM) или структур
        % массивов (NODE, VETV). При обращении к полям NODE, VETV
        %, синтаксис изменяется, имитируя обращение к массивам
        % структур.
        COMM  % Структура общей информации
        NODE  % Структура информации по узлам
        BRAN  % Структура информации по ветвям
    end
    
    methods
        function hM = CModelRS(DataNODE, DataBRAN, DataCOMM)
            % CModelRS  Конструктор.
            %
            % hM = CModelRS(DataNODE, DataBRAN, DataCOMM)
            
            % hM - handle созданного объекта класса;
            % DataNODE - объект класса исходных данных CData;
            % DataBRAN - поле объекта класса CData, хранящий данные по
            % ветвям
            % DataCOMM - структура параметров, необходимых для развётрывания
            % модели; 

            %
            
            % УЗЛЫ
            nN=size(DataNODE.Nn1,1);
            nZ = zeros(nN, 1);
            hM.NODE = struct(...
                ... % Данные
                'Nn',    [1:nN],...                     % Номера узлов
                'Nn1',   DataNODE.Nn1,...              % Пользовательские номера узлов
                'Type',  DataNODE.Type,...             % Типы узлов (BU, PU или PQ)
                'Pn',    DataNODE.Pn,...               % Активная мощность нагрузки, кВт
                'PnX',   DataNODE.Pn,...               % Активная мощность нагрузки с учетом потерь холостого хода, кВт                
                'Qn',    DataNODE.Qn,...               % Реактивная мощность нагрузки, квар
                'QnX',   DataNODE.Qn,...               % Рективная мощность нагрузки с учетом потерь холостого хода, кВт                       
                'Pg',    DataNODE.Pg,...               % Активная мощность генерации, кВт
                'Qg',    DataNODE.Qg,...               % Реактивная мощность генерации, квар
                'Qmin',  DataNODE.Qmin,...             % Минимальный предел реактивной мощности, квар
                'Qmax',  DataNODE.Qmax,...             % Максимальный предел реактивной мощности, квар
                'Uu',    DataNODE.Uu,...               % Уставка напряжения генератора (ЦП), кВ
                'dUu',   DataNODE.dUu.*pi./180,...     % Уставка напряжения генератора (ЦП), кВ
                ... % Рабочие массивы
                'Pnb',      DataNODE.Pn,...            % Активная мощность нагрузки после балансировки
                'Qnb',      DataNODE.Qn,...            % Реактивная мощность нагрузки после балансировки
                'QgR',      DataNODE.Qg,...            % Реактивная мощность генерации, квар
                'CurrType', DataNODE.Type,...          % Текущий тип узла в уравнениях
                'U',        DataNODE.Uu,...            % Модуль напряжения в узле, кВ
                'Unn',      DataNODE.Uu,...            % Модуль напряжения по низкой стороне трансформатора, кВ
                'dU',       DataNODE.dUu.*pi./180 ...  % Фаза напряжения в узле (ЦП), град
            );
            % создание handle функций для вычисления зависимых параметров по узлам 
            hM.NODE.U1=@(J)hM.NODE.U(J).*cos(hM.NODE.dU(J));
            hM.NODE.U2=@(J)hM.NODE.U(J).*sin(hM.NODE.dU(J));
            % ВЕТВИ
            nB=size(DataBRAN.Nb1,1);
            vZ = zeros(nB, 1);
            hM.BRAN = struct(...
                ... % Данные
                'Nb',     [1:nB],...              % Номера узлов
                'Nb1',    DataBRAN.Nb1,...       % Пользовательские номера ветвей
                'NbSt',   DataBRAN.NbSt,...      % Номер узла начала
                'NbStM',  vZ,...      % Номер узла начала
                'NbF',    DataBRAN.NbF,...       % Номер узла конца
                'NbFM',   vZ,...       % Номер узла конца
                'CmTpS',  DataBRAN.CmTpS,...     % Тип КА в начале
                'CmStS',  DataBRAN.CmStS,...     % Состояние КА в начале
                'CmTpF',  DataBRAN.CmTpF,...     % Тип КА в конце
                'CmStF',  DataBRAN.CmStF,...     % Состояние КА в конце
                'Type',   DataBRAN.Type,...      % Тип ветви
                'R',      DataBRAN.R,...         % Активное сопротивление, Ом
                'X',      DataBRAN.X,...         % Реактивное сопротивление, Ом
                'Pxx',    DataBRAN.Pxx,...       % Активная мощность холостого хода, кВт
                'Qxx',    DataBRAN.Qxx,...       % Реактивная мощность холостого хода, кВт
                'kt',     DataBRAN.kt,...        % Коэффициент трансформации
                ... % Результаты по ветвям
                'Pn', vZ,...        % Поток P в начале, кВт
                'Pk', vZ,...        % Поток P в конце, кВт
                'Qn', vZ,...        % Поток Q в начале, квар
                'Qk', vZ...        % Поток Q в конце, квар
                );
            for J=1:nB
                hM.BRAN.NbStM(J)=hM.NODE.Nn(hM.NODE.Nn1(1:nN)==hM.BRAN.NbSt(J));
                hM.BRAN.NbFM(J)=hM.NODE.Nn(hM.NODE.Nn1(1:nN)==hM.BRAN.NbF(J));
            end
            
            % создание handle функций для вычисления зависимых параметров
            % электрической сети по ветвям
            % токи ветвей
            % действительная часть
            
            hM.BRAN.I1=@(J)(hM.BRAN.Pn(J).*hM.NODE.U1(hM.BRAN.NbStM(J))+...
                hM.BRAN.Qn(J).*hM.NODE.U2(hM.BRAN.NbStM(J)))./(sqrt(3)*hM.NODE.U(hM.BRAN.NbStM(J)).^2);
            % мнимая часть
            hM.BRAN.I2=@(J)(hM.BRAN.Pn(J)*hM.NODE.U2(hM.BRAN.NbStM(J))-...
                hM.BRAN.Qn(J).*hM.NODE.U1(hM.BRAN.NbStM(J)))./(sqrt(3)*hM.NODE.U(hM.BRAN.NbStM(J)).^2);
            % комплексный ток начала и конца
            hM.BRAN.Is=@(J)abs(hM.BRAN.I1(J)+1i*hM.BRAN.I2(J));
            % мощности начал и концов ветвей
            hM.BRAN.Sn=@(J)abs(hM.BRAN.Pn(J)+1i*hM.BRAN.Qn(J));
            hM.BRAN.Sk=@(J)abs(hM.BRAN.Pk(J)+1i*hM.BRAN.Qk(J));
            hM.BRAN.dP=@(J)abs(hM.BRAN.Pn(J)-hM.BRAN.Pk(J));
            hM.BRAN.dQ=@(J)abs(hM.BRAN.Qn(J)-hM.BRAN.Qk(J));
            % падения напряжений в ветвях
            hM.BRAN.dU1=@(J)(hM.NODE.U1(hM.BRAN.NbStM(J))-hM.NODE.U1(hM.BRAN.NbFM(J)));
            hM.BRAN.dU2=@(J)(hM.NODE.U2(hM.BRAN.NbStM(J))-hM.NODE.U2(hM.BRAN.NbFM(J)));
            hM.BRAN.dU=@(J)abs(hM.BRAN.dU1(J)+1i*hM.BRAN.dU2(J));
            % ОБЩАЯ ИНФОРМАЦИЯ О СХЕМЕ
            % Суммарные потери в линиях
            LINE = struct(...
                'dpn', 0,...  % Потери Pнаг в линиях, кВт
                'dpx', 0,...  % Потери Pхх в линиях, кВт
                'dp', 0,...   % Потери P в линиях, кВт
                'dqn', 0,...  % Потери Qнаг в линиях, квар
                'dqx', 0,...  % Потери Qхх в линиях, квар
                'dq', 0 ...   % Потери Q в линиях, квар
                );
         
            % Суммарные потери в трансформаторах
            TRANS = struct(...
                'dpn', 0,...  % Потери Pнаг в тр-рах, кВт
                'dpx', 0,...  % Потери Pхх в тр-рах, кВт
                'dp', 0,...   % Потери D в тр-рах, кВт
                'dqn', 0,...  % Потери Qнаг в тр-рах, квар
                'dqx', 0,...  % Потери Qхх в тр-рах, квар
                'dq', 0 ...   % Потери Q в тр-рах, квар
                );
            
            hM.COMM = struct(...
                'TolFun', DataCOMM.TolFun,...   % Точность вычислений
                'Un', DataCOMM.Un,...           % Номинальное напряжение, кВ
                ... % Cуммарные нагрузка и генерация
                'ppotr', sum(hM.NODE.Pnb),...     % Нагрузка P схемы, кВт
                'pgen', sum(hM.NODE.Pg),...      % Генерация P схемы, кВт
                'qpotr', sum(hM.NODE.Qnb),...     % Нагрузка Q схемы, квар
                'qgen', 0,...      % Генерация Q схемы, квар
                ... % Суммарные потери в линиях и тр-рах
                'LINE', LINE,...    % Потери акт м в линиях
                'TRANS', TRANS,...  % Потери акт м в тр-рах
                ... % Суммарные потери в схеме
                'dpn', 0,...       % Потери Pнаг в схеме, МВт
                'dpx', 0,...       % Потери Pхх в схеме, МВт
                'dp', 0,...        % Потери P в схеме, МВт
                'dqn', 0,...       % Потери Qнаг в схеме, Мвар
                'dqx', 0,...       % Потери Qхх в схеме, Мвар
                'dq', 0 ...        % Потери Q в схеме, Мвар
                );
                hM = CalcXX(hM);
        end
        
        function hM = subsasgn(hM, S, B)
            % Метод индексного присваивания. Выполняет присваивание полям
            % объекта новых значений. Синтаксис индексации полей объекта
            % осуществляется по принятым правилам.
            %
            % hM = subsasgn(hM, S, B)
            %
            % hM - handel объекта; S - структура индексации объекта; B -
            % присваиваемое значение.
            
            str = hM.subs2str(S);
            eval(['hM', str, '= B;']);
        end
        
        function B = subsref(hM, S)
            % Метод индексной ссылки. Выполняет обращение к полям объекта
            % по принятым правилам синтаксиса индексации.
            %
            % B = subsref(hM, S)
            %
            % hM - handel объекта; S - структура индексации объекта; B -
            % результат обращения к объекту по индексной ссылке.
            
            if length(S) == 2 &&...
                    strcmp(S(2).type, '.') &&...
                    strcmp(S(2).subs, 'n')
                % Число элементов
                switch S(1).subs
                    case 'NODE'
                        B = length(hM.NODE.Nn1);
                    case 'BRAN'
                        B = length(hM.BRAN.Nb1);
                    otherwise
                        B = 0;
                end
            else
                % Параметры элементов
                str = hM.subs2str(S);
                B = eval(['hM', str]);
            end
        end
        
        function hM = CalcSum(hM)
            % Метод производит расчет интегральных параметров потерь
            % мощности. Результаты расчета записываются в объект hM.
            % Обращение к результатам возможно по общим правилам для модели
            % класса CModelRS.
            %
            % hM = CalcSum(hM)
            %
            % hM - handle созданного объекта класса;
            
            % данные по линиям
            LINE.dpn=sum(hM.BRAN.dP(hM.BRAN.Type==bTip.L));
            LINE.dpx=sum(hM.BRAN.Pxx(hM.BRAN.Type==bTip.L));
            LINE.dp=LINE.dpn+LINE.dpx;   
            LINE.dqn=sum(hM.BRAN.dQ(hM.BRAN.Type==bTip.L));
            LINE.dqx=sum(hM.BRAN.Qxx(hM.BRAN.Type==bTip.L));
            LINE.dq=LINE.dqn+LINE.dqx;
            % данные по трансформаторам
            TRANS.dpn=sum(hM.BRAN.dP(hM.BRAN.Type==bTip.T));
            TRANS.dpx=sum(hM.BRAN.Pxx(hM.BRAN.Type==bTip.T));
            TRANS.dp=TRANS.dpn+TRANS.dpx;   
            TRANS.dqn=sum(hM.BRAN.dQ(hM.BRAN.Type==bTip.T));
            TRANS.dqx=sum(hM.BRAN.Qxx(hM.BRAN.Type==bTip.T));
            TRANS.dq=TRANS.dqn+TRANS.dqx;
            % общие данные
            hM.COMM.ppotr=sum(hM.NODE.Pn);
            hM.COMM.pgen=sum(hM.NODE.Pg);
            hM.COMM.qpotr=sum(hM.NODE.Qn);
            hM.COMM.qgen=sum(hM.NODE.QgR);
            hM.COMM.LINE = LINE;
            hM.COMM.TRANS = TRANS;
            clear LINE TRANS;
            hM.COMM.dpn= hM.COMM.LINE.dpn+hM.COMM.TRANS.dpn;
            hM.COMM.dpx= hM.COMM.LINE.dpx+hM.COMM.TRANS.dpx;
            hM.COMM.dp= hM.COMM.LINE.dp+hM.COMM.TRANS.dp;
            hM.COMM.dqn= hM.COMM.LINE.dqn+hM.COMM.TRANS.dqn;
            hM.COMM.dqx= hM.COMM.LINE.dqx+hM.COMM.TRANS.dqx; 
            hM.COMM.dq= hM.COMM.LINE.dq+hM.COMM.TRANS.dq;
        end
        
        function hM = CalcXX(hM)
            % Метод производит учет потерь холостого хода линий и
            % трансформаторов в нагрузках узлов.
            %
            % hM = CalcXX(hM)
            %
            % hM - handle созданного объекта класса;
            
            % добавление потерь холостого хода по линиям
            % к узлу начала
            Lin=hM.BRAN.Type==bTip.L;
            StL=hM.BRAN.NbStM(Lin);
            hM.NODE.PnX(StL)=hM.NODE.Pn(StL)+hM.BRAN.Pxx(Lin)/2;
            hM.NODE.QnX(StL)=hM.NODE.Qn(StL)+hM.BRAN.Qxx(Lin)/2;
            clear StL;
            % к узлу конца
            FL=hM.BRAN.NbFM(Lin);
            hM.NODE.PnX(FL)=hM.NODE.Pn(FL)+hM.BRAN.Pxx(Lin)/2;
            hM.NODE.QnX(FL)=hM.NODE.Qn(FL)+hM.BRAN.Qxx(Lin)/2;
            clear FL;
            clear Lin;
            
            % добавление потерь холостого хода по трансформаторам
            % к узлу начала
            Tr=hM.BRAN.Type==bTip.T;
            StT=hM.BRAN.NbStM(Tr);
            hM.NODE.PnX(StT)=hM.NODE.Pn(StT)+hM.BRAN.Pxx(Tr);
            hM.NODE.QnX(StT)=hM.NODE.Qn(StT)+hM.BRAN.Qxx(Tr);
            clear StT;
            clear Tr;
        end
        
        function hM = CalcUT(hM)
            % Метод производит пересчет напряжений узлов на нижней стороне
            % трансформаторов.
            %
            % hM = CalcUT(hM)
            %
            % hM - handle созданного объекта класса;
            
            hM.NODE.Unn=hM.NODE.U;
            % создание массива концов трансформаторных ветвей
            Tr=hM.BRAN.Type==bTip.T;
            FT=hM.BRAN.NbFM(Tr); 
            % деление приведенного к высшей стороне напряжения на
            % коэффициент трансформации
            hM.NODE.Unn(FT)=hM.NODE.U(FT)./hM.BRAN.kt(Tr);
            clear FT;
            clear Tr;
        end
end
    methods(Static, Access = private)
        function Str = subs2str(S)
            % Метод преобразует структуру индексации объекта в строку.
            % Определяет правила индексации объекта. Использкется в методах
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
            % к общей информации -
            % a1 = hM.COMM.TolFun;
            % a2 = hM.COMM.LINE.dp;
            %
            % к узлам -
            % a3_15 = hM.NODE(3:15).nb1;
            % a_all = hM.NODE(:).nb1;
            %
            % к ветвям -
            % a3_15 = hM.VETV(3:15).nvn;
            % a_all = hM.VETV(:).nvk;
            %
            % к полиномам -
            % a3_15 = hM.POLI(2:3).a0;
            % a_all = hM.POLI(:).a1;
            
            if ~strcmp(S(1).type, '.')
                error(['На первом уровне индексации ожидается тип ',...
                    'индекса ".".'])
            end
            
            switch length(S)
                case 2
                    if ~strcmp(S(2).type, '.')
                        error(['На втором уровне индексации ожидается ',...
                            'тип индекса ".".'])
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
                            error(['На втором уровне индексации ',...
                                'ожидается тип индекса "." или "()".'])
                    end
                otherwise
                    error('Ожидалось два или три уровня индексации.')
            end
        end
    end
end