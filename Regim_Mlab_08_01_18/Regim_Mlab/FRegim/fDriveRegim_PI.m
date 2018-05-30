function varargout = fDriveRegim_PI(g, Input)
% Осуществляет управление процессом расчета режима, подготавливает исходные
% данные и обрабатывает результаты расчета режима, который производится в
% функции fSolvReg_PI. В данной функции и всех функциях, которые использует
% данная применяется индексация согласно нумерации узлов и ветвей в графе
% подхемы.
%
% varargout = fDriveRegim_PI(g, Input)
% g - граф расчетной подсхемы, представленный объектом типа CGraph;
% Input - структура входных данных, образованная в функции fInputCalcReg,
% представляющая собой ссылки на поля модели;
% Input.COMM - общие данные;
% Input.NODE - данные по узлам;
% Input.BRAN - данные по ветвям;
% varargout - cell-массив выходных данных
% varargout{1} - структура данных по узлам;
% varargout{2} - структура данных по ветвям;
% varargout{3} - структура диагностических данных о расчете режима;
% varargout{1}.QgR - вектор результирующих реактивных мощностей генераторов;
% varargout{1}.CurrType - вектор результирующих типов узлов (генераторных);
% varargout{1}.U - вектор модулей напряжений в узлах;
% varargout{1}.dU - вектор фаз напряжений в узлах;
% varargout{2}.Pn - вектор потока активной мощности в начале ветви;
% varargout{2}.Pk - вектор потока активной мощности в конце ветви;
% varargout{2}.Qn - вектор потока реактивной мощности в начале ветви;
% varargout{2}.Qk - вектор потока реактивной мощности в конце ветви;
% varargout{3}.Flag - переменная означающая статус завершения расчета режима (1 - расчет завершен нормально, 2 - превышено максимальное число итераций);
% varargout{3}.Iter - количество итераций;
% varargout{3}.NbVal - вектор небалансов по узловым уравнениям в узлах.

% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% November 2017.
%%
Input.COMM.Nn=g.nod.n;
Input.COMM.Nb=g.rib.n;
Nop=1;
% обработка исключения когда единственный узел в подсхеме
if Input.COMM.Nn==1
    % инициализация выходных массивов
    % по узлам
    varargout{1} = struct(...
        'QgR',      Input.NODE.Qg(1),...               % Реактивная мощность генерации, квар
        'CurrType', Input.NODE.Type(1),...             % Текущий тип узла в уравнениях
        'U',        Input.NODE.Uu(1),...            % Модуль напряжения в узле, кВ
        'dU',       Input.NODE.dUu(1)...              % Угол напряжения в узле, рад
        );
    % по ветвям
    varargout{2} = struct(...
        'Pn',       [],...        % Поток P в начале, кВт
        'Pk',       [],...        % Поток P в конце, кВт
        'Qn',       [],...        % Поток Q в начале, квар
        'Qk',       []...        % Поток Q в конце, квар
        );
    % диагностическая информация
    if nargout==3
        varargout{3}.Flag=11;
        varargout{3}.Iter=0;
        varargout{3}.NbVal=0;
    end
    return
end
% создание объектов типа граф, хранящих контуры
[gKont.BU, gKont.PU, gKont.Cycle] = fGraphKont(g, [], [], Input.NODE.Type, Nop);
% количество контуров
nKont=length(gKont.BU)+length(gKont.PU)+length(gKont.Cycle);
% ввод исходных данных для решения уравнений по 1 закону
% Кирхгофа
HordG=[];
if length(gKont.Cycle)>0
    HordG(length(gKont.Cycle))=int32(0);
end

for J=1:length(gKont.Cycle)
    HordG(J)=gKont.Cycle(J).rib(1);
end
% составление уравнений и решение по 1 закону Кирхгофа
% в результате имеем выражения для токов ветвей через токи узлов и
% независимые переменные
Eq1= fEq1_PI(g, HordG, Input.NODE.Type, Nop);
% инициализация начального приближения
X0=[];
if nKont>0
    X0((nKont)*2,1)= 0;
end
for J=1:length(gKont.PU)
    X0((nKont-length(gKont.PU))*2+J)=Input.NODE.Qg(gKont.PU(J).nod(1));
    X0(nKont*2-length(gKont.PU)+J)=Input.NODE.dUu(gKont.PU(J).nod(1));%#ok<*AGROW>
end
% инициализация начального приближения для напряжений
J=1:Input.COMM.Nn;
U0mod(Input.NODE.Type(J)==nTip.PQ,1)=Input.COMM.Un;
U0mod(Input.NODE.Uu(J)~=0,1)=Input.NODE.Uu(Input.NODE.Uu(J)~=0);
dU0(J,1)=Input.NODE.dUu(J);
clear J;
%%
% создание структуры входных данных для решателя уравнений режима
Input_fSolvReg = struct(...
    'Umod',   U0mod,...
    'Uumod',  U0mod,...    
    'dU',     dU0,...    
    'Qmin',   Input.NODE.Qmin,...  
    'Qmax',   Input.NODE.Qmax,...  
    'TypeN',  Input.NODE.Type,...
    'Pn',     Input.NODE.Pn,...
    'Qn',     Input.NODE.Qn,...
    'Pg',     Input.NODE.Pg,...
    'Qg',     Input.NODE.Qg,...
    'Z',      struct('R', Input.BRAN.R,'X',Input.BRAN.X)...
    );
% инициализация опций, точность и максимальное количество итераций по
% напряжениям
optionsSol.TolFun=Input.COMM.TolFun;
optionsSol.MaxIter=100;
% если есть контуры в схеме
if nKont>0
    % создание описателей для уравнений. Описатель - номер ветви(для
    % контурных токов) или узла (для генераторных узлов) в подсхеме
    % для балансирующих узлов
    for J=1:length(gKont.BU)
        Descr(2*J-1:2*J,1)=gKont.BU(J).rib(1);
        Descr(2*J-1:2*J,2)=1;
    end
    % для циклов
    for J=1:length(gKont.Cycle)
        JJ=length(gKont.BU)+J;
        Descr(2*JJ-1:2*JJ,1)=gKont.Cycle(J).rib(1);
        Descr(2*JJ-1:2*JJ,2)=2;
    end
    % для PU-узлов
    for J=1:length(gKont.PU)
        JJ=length(gKont.BU)+length(gKont.Cycle)+J;
        Descr(2*JJ-1:2*JJ,1)=gKont.PU(J).nod(1);
        Descr(2*JJ-1:2*JJ,2)=3;
    end
    % составление уравнений по второму закону Кирхгофа
    Eq2=fEq2_PI(gKont, Eq1, g.nod.n, g.rib.n, ...
        struct('R', Input.BRAN.R, 'X', Input.BRAN.X),...
        struct('mod', Input.NODE.Uu, 'd', Input.NODE.dUu));
    % уточнение первой итерации по напряжениям для улучшения значения тока
    % в узле
    if length(gKont.PU)>0
        % перевод всех PU узлов к типу PQ
        Input_fSolvReg.TypeN=Input_fSolvReg.TypeN(':');
        Input_fSolvReg.TypeN(Input_fSolvReg.TypeN==nTip.PU)=nTip.PQ;
        MaxIterPrev=optionsSol.MaxIter;
        optionsSol.MaxIter=1;
        Input_fSolvReg.Qg=Input.NODE.Qg(':');
        % вводим 0 как начальное приближение реактивной мощности, так как
        % эмпирическим путем подобрано, что такое значение переменной
        % является оптимальной для схемы 7
        LogPU=Input.NODE.Type(':')==nTip.PU;
        Input_fSolvReg.Qg(LogPU)=0;
        Input_fSolvReg.Qg(Input_fSolvReg.Qg(LogPU)...
            <Input.NODE.Qmin(LogPU))=Input.NODE.Qmin(Input_fSolvReg.Qg(LogPU)...
            <Input.NODE.Qmin(LogPU));
        Input_fSolvReg.Qg(Input_fSolvReg.Qg(LogPU)...
            >Input.NODE.Qmax(LogPU))=Input.NODE.Qmax(Input_fSolvReg.Qg(LogPU)...
            <Input.NODE.Qmin(LogPU)); 
        %Input_fSolvReg.Qg(Input.NODE.Type(':')==nTip.PU)=...
        %    (Input_fSolvReg.Qmax(Input.NODE.Type(':')==nTip.PU)...
        %   -Input_fSolvReg.Qmin(Input.NODE.Type(':')==nTip.PU))/2;
        
        % расчет первого приближения модуля и фазы напряжений путем
        % подстановки вместо мощностей всех генераторных узлов нулей
        [~, Ucalc, ~, ~]=...
            fSolvReg_PI(Eq1, Eq2, [], Descr, g, Input_fSolvReg, optionsSol);

        Input_fSolvReg.Umod=Ucalc.mod;
        Input_fSolvReg.dU=Ucalc.d;
        % возврат исходных данных
        Input_fSolvReg.TypeN=Input.NODE.Type;
        optionsSol.MaxIter=MaxIterPrev;
        for J=1:length(gKont.PU)
            X0(nKont*2-2*length(gKont.PU)+J)=Input_fSolvReg.Qg(gKont.PU(J).nod(1));
            X0(nKont*2-length(gKont.PU)+J)=Input_fSolvReg.dU(gKont.PU(J).nod(1));%#ok<*AGROW>
        end
        clear MaxIterPrev;
    end
    % решение уравнений режима при наличии контуров (по 2-му закону
    % Кирхгофа)
    [Icalc, Ucalc, QgCalc, TypeCalc, FlagTerm, CountIter, NbVal]=...
        fSolvReg_PI(Eq1, Eq2, X0, Descr, g, Input_fSolvReg, optionsSol); %#ok<*ASGLU>
else % если отсутствуют контуры в схеме
    X0Descr=[];
    % решение уравнений режима при отсутствии контуров (путем уточнения
    % токов (пересчет напряжений) в выражения из первого закона Кирхгофа)
    [Icalc, Ucalc, QgCalc, TypeCalc, FlagTerm, CountIter, NbVal]=...
        fSolvReg_PI(Eq1, [],[],[], g, Input_fSolvReg, optionsSol);
end
J=1:g.rib.n;
NY1=g.rib(:).ny1;
NY2=g.rib(:).ny2;
% итоговой расчет (определение потоков мощности, потерь: всех величин
% необходимых в модели)
Scalc.n(J)=Ucalc.mod(NY1(J)).*(cos(Ucalc.d(NY1(J)))+...
    1i*sin(Ucalc.d(NY1(J)))).*(conj(Icalc(J)));
Scalc.k(J)=Ucalc.mod(NY2(J)).*(cos(Ucalc.d(NY2(J)))+...
    1i*sin(Ucalc.d(NY2(J)))).*(conj(Icalc(J)));
clear J NY1 NY2;
% инициализация выходной структуры данных - ссылок на данные
% по узлам
J=1:g.nod.n;
varargout{1} = struct(...
    'QgR',      QgCalc(J),...               % Реактивная мощность генерации, квар
    'CurrType', TypeCalc(J),...             % Текущий тип узла в уравнениях
    'U',        Ucalc.mod(J),...            % Модуль напряжения в узле, кВ
    'dU',       Ucalc.d(J)...               % Угол напряжения в узле, рад
    );
% по ветвям
J=1:g.rib.n;
varargout{2} = struct(...
    'Pn',       real(Scalc.n(J)),...        % Поток P в начале, кВт
    'Pk',       real(Scalc.k(J)),...        % Поток P в конце, кВт
    'Qn',       imag(Scalc.n(J)),...        % Поток Q в начале, квар
    'Qk',       imag(Scalc.k(J))...         % Поток Q в конце, квар
    );
% вывод диагностической информации при необходимости
if nargout==3
    varargout{3}.Flag=FlagTerm;
    varargout{3}.Iter=CountIter;
    varargout{3}.NbVal=NbVal;
end
% если флаг завершения расчетов имеет "плохой" статус - вывод
% предупреждения
if FlagTerm~=1
    warning('ошибка в функции расчета токов и напряжений fSolvReg, полученные значения могут быть неточными');
end
end
