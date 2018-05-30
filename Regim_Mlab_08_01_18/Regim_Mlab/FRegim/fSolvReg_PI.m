function varargout = fSolvReg_PI(Eq1,Eq2, X0Beg, Descr, g, Input, options)
% Осуществляет решение системы уравнения при помощи уравнений по 1-му и
% 2-му закону Кирхгофа. Осуществляет выбор метода решения в зависимости от
% линейности или нелинейности уравнений, а также контролирует отсутствие
% уравнений по 2-му закону Кирхгофа, в случае чего ведет расчет в обход
% решателя системы уравнений. Функция вызывается из fDriveRegim. Функция
% использует fCalcEq2, fResLim, fCalcU_PI, fTolCon_UU.
%
% varargout = fSolvReg_PI(Eq1,Eq2, X0Beg, Descr, g, Input, options)

% varargout - cell-массив выходных данных размерностью от 5 до 7;
% varargout{1} - вектор комплексных значений токов ветвей;
% varargout{2} - структура векторов модулей и фаз напряжений;
% varargout{2}.mod - модуль напряжения в узле;
% varargout{2}.d - фаза напряжения в узле;
% varargout{3} - вектор генерации реактивной мощности по результатам расчета;
% varargout{4} - тип узла по результатам расчета;
% varargout{5} - флаг статуса завершения расчета режима;
% varargout{6} - счетчик количества итераций;
% varargout{7} - вектор небалансов по узловых уравнений в узлах;
% Eq1 - структура уравнений по 1-му закону Кирхгофа, получаемая из fEq1_PI;
% Eq2 - структура уравнений по 2-му закону Кирхгофа, получаемая из fEq2_PI;
% X0Beg - вектор начальных приближений;
% Descr - вектор описателей начальных приближений переменных;
% g - граф расчетной подсхемы в виде объекта CGraph;
% Input - структура ссылок на поля модели из функции fInputCalcReg_PI;
% options - вектор опций расчета режима;
% options.TolFun - точность расчета;
% options.CountIter - максимальное количество итераций;
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% November 2017.

% контроль количества исходных данных
if nargout<4||nargout>7
    error('Неверное количество выходных параметров');
end
if nargin<6||nargin>7
    error('Неверное количество входных параметров');
end
if nargin==6
    options.TolFun=10^-2;
    options.MaxIter=20;
end
% задание опций для решения системы уравнений по 2-му закону Кирхгофа по
% метода Левенберга-Маркварта
optionsLM=optimoptions(@fsolve,'Algorithm','levenberg-marquardt',...
    'InitDamping',10^(-2),'TolFun',10^(-5),'TolX',10^(-5), 'Display','off',...
    'FinDiffType', 'central','FunValCheck','on','Jacobian','on');
ParamIterLim=1; % параметр, показывает количество итераций простоя перевода типов для увеличения точности определиния параметров режима
ParamLimAl=8; % параметр, показывает количество итераций до начала поодиночного перевода типов узлов
ParamNotCheckLim=2; % параметр, показывает количество итераций с неизменными типами узлов после которого происходит останов контроля типов
ParamStartLim=1; % Количество итераций расчета режима, проводимых со стартовым алгоритмом контроля точности
% инициализация переменных
Nn=g.nod.n;
Nb=g.rib.n;
nEq2= length(X0Beg);
% определение контуров
nKont=nEq2/2;
optionsU.TolFun=options.TolFun;
UmodCur=Input.Umod;
dUCur=Input.dU;
Qmin=Input.Qmin(1:g.nod.n);
Qmax=Input.Qmax(1:g.nod.n);
NodeTypeCur=Input.TypeN(1:g.nod.n);
NbVal(g.nod.n)=0;
nBU=0;
nPU=0;
I1(g.rib.n,1)=0;
I2(g.rib.n,1)=0;
Qg(g.nod.n,1)=0;
dU(g.nod.n,1)=0;
Su.P(g.nod.n,1)=0;
Su.Q(g.nod.n,1)=0;
Qn(g.nod.n,1)=0;
Ibu.I1(g.nod.n)=0;
Ibu.I2(g.nod.n)=0;
% определение мощности в узлах
% активная
Su.P(1:g.nod.n)=Input.Pn(1:g.nod.n)-Input.Pg(1:g.nod.n);
% реактивная
% для нагрузочных и балансирующих узлов
Su.Q(NodeTypeCur(1:g.nod.n)~=nTip.PU)=Input.Qn(NodeTypeCur(1:g.nod.n)~=nTip.PU)...
    -Input.Qg(NodeTypeCur(1:g.nod.n)~=nTip.PU);
% для генераторных узлов
Su.Q(NodeTypeCur(1:g.nod.n)==nTip.PU)=Input.Qn(NodeTypeCur(1:g.nod.n)==nTip.PU);
% инициализация массивов для раздельного хранения реактивной мощности
% нагрузки и генерации
Qn(1:g.nod.n)=Input.Qn(1:g.nod.n);
Qg(1:g.nod.n)=Input.Qg(1:g.nod.n);
IuR(1:g.nod.n)=0;
IuI(1:g.nod.n)=0;
nPU=0;
nBU=0;
BU=[];
PU=[];
noPU=0;
% создание списков балансирующих и PU узлов
for J=1:g.nod.n
    switch NodeTypeCur(J)
        % балансирующий узел
        case nTip.BU
            nBU=nBU+1;
            BU(nBU)=J;
            if nBU==1
                NopG=J;
            end
            % генераторный узел
        case nTip.PU
            nPU=nPU+1;
            PU(nPU)=J;
        otherwise
    end
end
PUMod=false;
% инициализация вектора признаков изменения типов узлов
if nPU>0
    PUMod(nPU)=false;
end
% инициализация напряжения опорного узла
Uop.mod=double(UmodCur(NopG));
Uop.d=double(dUCur(NopG));
FlagNolinBeg=0;
I1(g.rib.n)=0;
I2(g.rib.n)=0;
% определение признака нелинейности уравнений
if nPU==0
    FlagNolinBeg=0;
else
    FlagNolinBeg=1;
end
FlagNolinCur=FlagNolinBeg;
X0Cur=X0Beg;
% Обработка исключения когда соединены напрямую центр питания с центром
% питания
if isempty(Eq1)==1 % если нет уравнений по первому закону Кирхгофа
    Xres=fCalcEq2(Eq2, XDescr); % расчет уравнения по второму закону Кирхгофа
    varargout{1}=Xres(1)+1i*Xres(2);
    varargout{2}=struct('mod',UmodCur,'d',dUCur);
    varargout{3}=struct(Qg);
    varargout{4}=NodeTypeCur;
    % определение необходимости вывода диагностических о решении уравнений
    if nargout>4
        varargout{5}=1;
        if nargout>5
            varargout{6}=0;
        end
        if nargout>5
            varargout{7}=0;
        end
    end
    return;
end
% конец обработки исключения
% инициализация структуры сопротивлений
Z.R=@(J)Input.Z.R(1:g.rib.n);
Z.X=@(J)Input.Z.X(1:g.rib.n);
I1(g.rib.n)=0;
I2(g.rib.n)=0;
% выделение памяти под выражения независимых токов
IEq2=spalloc(nEq2,2*Nn+1,nEq2*Nn);
if isempty(Eq2)==0
    ActEq2(1:nEq2)=true;
    % если есть генераторные узлы
    if nPU>0
        % контроль пределов реактивной мощности
        FirstLimPU=1;
        CountIterLim=0; % счетчик простоя смены типа узлов для увеличения точности определения параметров режима
        FlagChangeLim=1; % флаг, используется для определения необходимости останова контроля пределов реактивной мощности
        UseStartLim=1; % флаг, используется для использования стартового алгоритма контроля пределов
        [NodeTypeCur(PU), PUMod]=fResLim(NodeTypeCur(PU), Qg(PU),...
            struct('Qmin',Qmin(PU), 'Qmax', Qmax(PU)), UmodCur(PU),...
            Input.Uumod(PU),FirstLimPU, CountIterLim, ParamIterLim, UseStartLim);
    else
        % выражение независимых токов путем решения линейной системы
        % уравнений по 2-му закону Кирхгофа
        IEq2=[Eq2.Iv.R, Eq2.Iv.I]\[-Eq2.Iu.R, -Eq2.Iu.I, -Eq2.UConst];
    end
else
    ActEq2=[];
end
CountIter=0;
exit=0;
% основной цикл решения уравнений режима, в нем осуществляется многократное
% переопределение токов с учетом изменения напряжений на итерациях, расчет
% завершается когда признак выхода из уравнений отличен от 0.
while exit==0
    CountIter=CountIter+1; % счетчик количества итераций
    % обработка изменения типов узлов PU, установка реактивной мощности и
    % напряжений генераторных узлов в соответсвии с измененными типами
    if (nPU>0)
        % если типы PU узлов изменились
        if (sum(PUMod)>0)
            % пересоздание списка PU узлов
            PUModProm=PU(PUMod==1);
            NumPU=1:nPU;
            NPUModProm=NumPU(PUMod==1);
            clear NumPU;
            % определение количества PU узлов
            nPUCur=sum(NodeTypeCur(PU)==nTip.PU);
            % переопределение признака нелинейности системы уравнений
            if nPUCur>0
                if FlagNolinCur==0
                    FlagNolinCur=1;
                end
            elseif FlagNolinCur>0
                FlagNolinCur=0;
            end
            % переопределение реактивной мощности и напряжений в гераторных
            % узлах
            for J=1:length(PUModProm)
                PUProm=PUModProm(J); % текущий генераторный узел
                switch NodeTypeCur(PUProm)
                    % если тип PU (возврат в пределы по реактивной мощности)
                    case nTip.PU
                        % установка приближения по реактивной мощности узла
                        % для расчета уравнений по 2-му закону Кирхгофа,
                        % включение соответствующего уравнения
                        Su.Q(PUProm)=Qn(PUProm);
                        X0Cur((nKont-nPU)*2+NPUModProm(J))=Qg(PUProm);
                        ActEq2((nKont-nPU+NPUModProm(J))*2-1:(nKont-nPU+NPUModProm(J))*2)=true;
                        % если тип PU на верхнем пределе
                    case nTip.PUmax
                        % установка реактивной мощности на верхний предел,
                        % отключение соответствующего уравнения
                        Qg(PUProm)=Qmax(PUProm);
                        Su.Q(PUProm)=Qn(PUProm)-Qg(PUProm);
                        X0Cur((nKont-nPU)*2+NPUModProm(J))=Qg(PUProm);
                        ActEq2((nKont-nPU+NPUModProm(J))*2-1:(nKont-nPU+NPUModProm(J))*2)=false;
                    case nTip.PUmin
                        % установка реактивной мощности на нижний предел,
                        % отключение соответствующего уравнения
                        Qg(PUProm)=Qmin(PUProm);
                        Su.Q(PUProm)=Qn(PUProm)-Qg(PUProm);
                        X0Cur((nKont-nPU)*2+NPUModProm(J))=Qg(PUProm);
                        ActEq2((nKont-nPU+NPUModProm(J))*2-1:(nKont-nPU+NPUModProm(J))*2)=false;
                    otherwise
                        warning('задан неверный тип в установлении пределов')
                end
            end
            clear NPUModProm PUModProm PUstrM PUstrG
        end
    end
    % конец обработки изменения типов узлов PU
    
    % если есть уравнения по 2-му закону Кирхгофа и изменялись типы
    % генераторных узлов, но все источники генерации вышли на предел
    % реактивной мощности
    if sum(PUMod)>0 && FlagNolinCur==0 && sum(ActEq2)>0
        % решение линейной системы уравнений по 2-му закону Кирхгофа,
        % получение выражений независимых токов через токи нагрузок
        IEq2(ActEq2,:)=[Eq2.Iv.R(ActEq2,:), Eq2.Iv.I(ActEq2,:)]...
            \[-Eq2.Iu.R(ActEq2,:), -Eq2.Iu.I(ActEq2,:), -Eq2.UConst(ActEq2)];
    end
    % Определение токов в узлах (не PU-узлы) в зависимости от напряжений
    IuR=(Su.P.*cos(dUCur)+Su.Q.*sin(dUCur))./UmodCur;
    IuI=(Su.P.*sin(dUCur)-Su.Q.*cos(dUCur))./UmodCur;
    
    % определение составляющих при токе генераторного узла (PU-узел) при текущем
    % значении напряжения
    for J=1:nPU
        if NodeTypeCur(PU(J))==nTip.PU
            Ig.ConstR(J)=(Su.P(PU(J))*cos(dUCur(PU(J)))+Qn(PU(J))...
                *sin(dUCur(PU(J))))/UmodCur(PU(J));
            Ig.ConstI(J)=(Su.P(PU(J))*sin(dUCur(PU(J)))-Qn(PU(J))...
                *cos(dUCur(PU(J))))/UmodCur(PU(J));
            Ig.VarR(J)=-sin(dUCur(PU(J)))/UmodCur(PU(J));
            Ig.VarI(J)=cos(dUCur(PU(J)))/UmodCur(PU(J));
        end
    end
    
    % В случе если имеются активные уравнения по 2-му закону Кирхгофа
    % производится решение уравнений по второму закону Киргофа, обработка
    % результатов
    if isempty(Eq2)==0 && sum(ActEq2)>0
        noPU=(nKont-nPU)*2; % количество "негенераторных" уравнений
        % составление логического вектора призанаков того, что узел
        % генераторный
        LogPU=NodeTypeCur(PU)==nTip.PU;
        % составление логического вектора активности переменных режима в
        % зависимости от активных уравнений
        LogActX(nEq2)=false;
        LogActX(1:noPU/2)=ActEq2(1:2:noPU-1);
        LogActX(noPU/2+1:noPU)=ActEq2(2:2:noPU);
        LogActX(noPU+1:noPU+nPU)=ActEq2(noPU+1:2:nEq2-1);
        LogActX(noPU+nPU+1:nEq2)=ActEq2(noPU+2:2:nEq2);
        % выбор решателя (линейный или нелинейный)
        if FlagNolinCur==1
            % нелинейный решатель
            % решение системы уравнений по 2-му закону Кирхгофа по методу
            % Левенберга-Маркварта, в решатель подаются только активные
            % уравнения, принимаются только активные переменные Хres
            [Xres(LogActX),exitFlagEq2]=fCalcEq2(...
                Eq2.Iv.R(ActEq2,ActEq2(1:size(Eq2.Iv.R,2))),...
                Eq2.Iv.I(ActEq2,ActEq2(size(Eq2.Iv.R,2)+1:2*size(Eq2.Iv.R,2))),...
                Eq2.G.QR(ActEq2,LogPU),Eq2.G.QI(ActEq2,LogPU),...
                Eq2.G.dU(ActEq2,LogPU), Eq2.Iu.R(ActEq2,:), Eq2.Iu.I(ActEq2,:),...
                Eq2.UConst(ActEq2), IuR, IuI, ...
                struct('ConstR',Ig.ConstR(LogPU),...
                'ConstI',Ig.ConstI(LogPU),'VarR',Ig.VarR(LogPU),...
                'VarI',Ig.VarI(LogPU)), Descr(ActEq2,1:2),...
                X0Cur(LogActX), optionsLM); %#ok<AGROW>
            % дезактивированным Х присваиваем NaN
            Xres(LogActX==false)=NaN; %#ok<AGROW>
            % выдача предупреждения, если расчеты завершились с "плохим"
            % статусом
            if exitFlagEq2<1
                warning('Ошибка решения системы нелинейных уравнений по 2-му закону Кирхгофа-точное решение не найдено');
            end
        else
            % линейный решатель, решение осуществляется путем подстановки
            % токов нагрузки, найденных по напряжениям на текущей итерации
            % в выражения, полученные путем решения системы линейных
            % уравнений по 2-му закону Кирхгофа
            Xres(LogActX)=IEq2(ActEq2,1:Nn)*IuR(1:Nn)+IEq2(ActEq2,Nn+1:2*Nn)...
                *IuI(1:Nn)+IEq2(ActEq2,2*Nn+1);
            Xres(LogActX==false)=NaN;
        end
        % интерпретация результатов расчета - запись Х в соответствующие
        % поля
        for J=1:nPU
            JJ=noPU+J;
            % для активных уравнений
            if ActEq2(noPU+2*J)==1
                % определение генерируемой мощности, фазы напряжения, токов
                % генераторных узлов
                Qg(Descr(noPU+2*J))=Xres(JJ);
                dU(Descr(noPU+2*J))=Xres(JJ+nPU);
                IuR(Descr(noPU+2*J))=Ig.ConstR(J)+Ig.VarR(J).*Qg(PU(J));
                IuI(Descr(noPU+2*J))=Ig.ConstI(J)+Ig.VarI(J).*Qg(PU(J));
            end
        end
        % в качестве первого приближения на следующей итерации для
        % нелинейного решателя принимаем значения Х, полученные на данной
        % итерации
        X0Cur(LogActX)=Xres(LogActX);
    end
    % конец блока решения уравнений по 2-му закону Кирхгофа
    
    % Определение составляющих токов ветвей по уточненным значениям токов
    % узлов по выражениям по 1-му закону Кирхгофа
    I1=Eq1.Iu*IuR;
    I2=Eq1.Iu*IuI;
    % если количество "негенераторных" уравнений больше нуля %
    if noPU-1>0
        for J=1:Nb
            % определение составляющих токов ветвей от контурных токов по
            % выражениям по 1-му закону Кирхгофа
            I1(J)=I1(J)+Eq1.InDep(J,:)*(Xres(1:noPU/2))';
            I2(J)=I2(J)+Eq1.InDep(J,:)*(Xres(noPU/2+1:noPU))';
        end
    end
    % создание ссылок на токи ветвей
    I.I1=@(J)I1(J);
    I.I2=@(J)I2(J);
    % расчет модуля и фазы напряжений в узлах
    [UmodCur, dUCur]=fCalcU_PI(g, I, Z, Uop, NopG);
    % подстановка в балансирующие узлы исходных значений напряжений
    UmodCur(NodeTypeCur==nTip.BU)=Input.Uumod(NodeTypeCur==nTip.BU);
    dUCur(NodeTypeCur==nTip.BU)=Input.dU(NodeTypeCur==nTip.BU);
    % если есть генерирующие узлы (начальный тип)
    if nPU>0
        % контроль пределов реактивной мощности, в результате получаем
        % вектор типов узлов и вектор признаков изменения типа узла
        CountIterLim=CountIterLim+1;
        if sum(PUMod)>0
            CountIterLim=0;
        end
        if CountIterLim>ParamIterLim+ParamNotCheckLim
            if FlagChangeLim~=0
                FlagChangeLim=0;
            end
        end
        if FlagChangeLim==1
            if CountIter<=ParamLimAl
               UseStartLim=1;
            else
               UseStartLim=0;
            end
        end
        [NodeTypeCur(PU), PUMod]=fResLim(NodeTypeCur(PU), Qg(PU),...
            struct('Qmin',Qmin(PU), 'Qmax', Qmax(PU)), UmodCur(PU),...
            Input.Uumod(PU),FirstLimPU,CountIterLim, ParamIterLim, UseStartLim);
        if sum(PUMod)>0
            FlagChangeLim=1;
        end
        if FirstLimPU~=0
            if CountIter>=ParamStartLim
                FirstLimPU=0;
            end
        end
    end
    % если типы узлов не изменились (если типы узлов изменились в любом
    % случае осуществляем переход к следующей итерации)
    if sum(PUMod)==0
        % для всех балансирующих узлов определяем узловой ток (суммарное значение тока
        % по всем отходящим линиям)
        for J=1:nBU
            AR=g.nod(BU(J)).ar;
            Ibu.I1(BU(J))=0;
            Ibu.I2(BU(J))=0;
            for K=1:length(AR)
                % если рассматриваемый узел - начало ветви
                if g.rib(AR(K)).ny1==BU(J);
                    Ibu.I1(BU(J))=Ibu.I1(BU(J))+I.I1(AR(K));
                    Ibu.I2(BU(J))=Ibu.I2(BU(J))+I.I2(AR(K));
                else % если конец
                    Ibu.I1(BU(J))=Ibu.I1(BU(J))-I.I1(AR(K));
                    Ibu.I2(BU(J))=Ibu.I2(BU(J))-I.I2(AR(K));
                end
            end
        end
        % в зависимости от состава необходимых выходных данных проводим
        % контроль необходимости завершения расчетов путем расчета
        % небалансов по узловым уравнениям
        if nargout<7
            [exit]=fTolCon_UU(g, struct('P',Su.P,'Q', Qn-Qg), Ibu, Z, struct('mod',UmodCur,'d', dUCur), optionsU);
        elseif nargout==7
            [exit, NbVal]=fTolCon_UU(g, struct('P',Su.P,'Q', Qn-Qg), Ibu, Z, struct('mod',UmodCur,'d', dUCur), optionsU);
        end
    end
    if (exit==1) && nPU>0
        % Итоговый контроль пределов PU узлов
        FirstLimPU=1;
        [NodeTypeCur(PU), PUMod]=fResLim(NodeTypeCur(PU), Qg(PU),...
            struct('Qmin',Qmin(PU), 'Qmax', Qmax(PU)), UmodCur(PU),...
            Input.Uumod(PU),FirstLimPU,CountIterLim,ParamIterLim,1);
        if sum(PUMod)>0
            exit=0;
        end
    end
    % если превышено максимальное число итераций - завершаем расчет
    if (CountIter>=options.MaxIter) && exit~=1
        exit=2;
        break;
    end
end
% инициализация выходных данных
varargout{1}=I1+1i*I2; % токи
varargout{2}=struct('mod',UmodCur,'d',dUCur); % напряжения
varargout{3}=Qg; % мощность генераторов
varargout{4}=NodeTypeCur; % типы узлов
% в случае необходимости - выводим диагностическую информацию
if nargout>4
    varargout{5}=exit; % признак выхода
    if nargout>5
        varargout{6}=CountIter; % количество итераций
    end
    if nargout>6
        varargout{7}=NbVal; % небаланс по узловым уравнениям
    end
end
end

function [Xres,exitflag] = fCalcEq2(EqInDepIvR, EqInDepIvI, EqIndepGQR, ...
    EqIndepGQI, EqInDepGdU, EqConstIuR, EqConstIuI, EqConstU, IuR, IuI, Ig,...
    Descr, X0, optionsLM)
% Функция осуществляет управление и ввод данных Matlab-решателем fsolve.
%
% [Xres,exitflag] = fCalcEq2(EqInDepIvR, EqInDepIvI, EqIndepGQR, EqIndepGQI, EqInDepGdU, EqConstIuR, EqConstIuI, EqConstU, IuR, IuI, Ig, Descr, X0, optionsLM)
% Xres - вектор решения системы уравнений;
% exitflag - параметр, при успешном решении системы равен 1, при превышении числа итераций используется для генерации warning;
% EqInDepIvR - вектор действительных составляющих уравнений при контурном токе;
% EqInDepIvI - вектор мнимых составляющих уравнений при контурном токе;
% EqIndepGQR - вектор действительных составляющих уравнений при реактивной мощности генерирующих источников;
% EqIndepGQI - вектор мнимых составляющих уравнений при реактивной мощности генерирующих источников;
% EqInDepGdU - вектор составляющих уравнений при угле напряжения генераторных
% узлов;
% EqConstIuR - вектор постоянных составляющих уравнений при действительных зависимых токах узлов;
% EqConstIuI - вектор постоянных составляющих уравнений при мнимых зависимых токах узлов;
% EqConstU - вектор постоянных составляющих уравнений от напряжений;
% IuR - действительная составляющая тока узла;
% IuI - мнимая составляющая тока узла;
% Ig - ток генерации;
% Descr - описатель вектора переменных;
% X0 - вектор начальных приближений;
% optionsLM - опции для fsolve.
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% November 2017.

% инициализация переменных
Xres(size(Descr,1),1)=0;
nPU=length(Ig.VarR);
EqGQ(size(Descr,1),nPU)=0;
FlagNolin=0;
Const(size(Descr,1),1)=0;
% определение вектора константных составляющих уравнений
for J=1:length(Xres)
    switch Descr(J,2)
        case {1,3}
            Const(J)=EqConstU(J);
        case 2
            Const(J)=0;
        otherwise
            error('Ошибка задания вида контура 1,2 или 3');
    end
end
Const=Const+EqConstIuR*IuR+EqConstIuI*IuI;
% определение составляющей при реактивной мощности
for J=1:size(Descr,1)
    EqGQ(J,:)=EqIndepGQR(J,:).*(Ig.VarR)+EqIndepGQI(J,:).*(Ig.VarI);
end
% создание handle на функцию, реализующую расчет значения функции небаланса
% контурных уравнений и ее Якобиана, производимые на итерациях
funEq2=@(X)fhEq2_Matr(X, [EqInDepIvR, EqInDepIvI, EqGQ], EqInDepGdU, Const, nPU);
% запуск решателя по методу Левенберга-Мардкварта с начальным приближением
[Xres,fval,exitflag,output]=fsolve(funEq2,X0,optionsLM);
end

function [OutType, FlagMod] = fResLim(EntrType, Qg, Qbor, Ucurr, Uust,...
    First, CountIter,ParamIter, UseStart)
% Осуществляет определение узлов для которых должны измениться типы по
% заданным условиям для первых итераций.
%
% [OutType, FlagMod] = fResLimSt(EntrType, Qg, Qbor, Ucurr, Uust, First, CountIter,ParamIter)
%
% OutType - вектор результирующих типов ген. узлов после переустановки;
% FlagMod - вектор признаков (logical) изменения типа генераторов
% на итерации;
% EntrType - вектор входных (текущих) типов генераторных узлов;
% Qg - вектор реактивных мощностей генерации в узлах по результатам
% решения системы уравнений по 2-му закону Кирхгофа;
% Qbor - структура, представляющая границы реактивной мощности генераторов
% Qbor.Qmax - вектор верхних границ;
% Qbor.Qmin - вектор нижних границ;
% Ucurr - вектор модулей напряжения генераторов на текущей итерации;
% Uust - вектор уставок напряжений генераторов;
% First - признак первой итерации;
% CountIter - счетчик числа итераций.
% ParamIter - счетчик числа итераций.
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% November 2017.

N=length(EntrType);
FlagMod(N)=false;
OutType=EntrType;
FlagOneNod=0;
FlagDf=0;
if UseStart==1
    for J=1:N
        switch EntrType(J)
            % текущий тип генератора - PU
            case nTip.PU
                if Qg(J)>Qbor.Qmax(J)&&(CountIter>=ParamIter||First==1)
                    OutType(J)=nTip.PUmax;
                    FlagMod(J)=true;
                    FlagDf=1;
                end
                % текущий тип генератора - PUmin
            case nTip.PUmin
                if Ucurr(J)<Uust(J)
                    if(CountIter>=ParamIter||First==1)||Ucurr(J)<0.8*Uust(J)
                        OutType(J)=nTip.PU;
                        FlagMod(J)=true;
                        FlagDf=1;
                    end
                end
                
            case nTip.PUmax
                if Ucurr(J)>1.2*Uust(J)
                    OutType(J)=nTip.PU;
                    FlagMod(J)=true;
                    FlagDf=1;
                end
            otherwise
                warning('Неверно задан тип узла при контроле пределов генератора');
        end
    end
    if ((FlagDf==0)&&CountIter>=ParamIter)||(First==1)
        for J=1:N
            switch EntrType(J)
                % текущий тип генератора - PU
                case nTip.PU
                    if Qg(J)<Qbor.Qmin(J)
                        OutType(J)=nTip.PUmin;
                        FlagMod(J)=true;
                    end
                    % текущий тип генератора - PUmax
                case nTip.PUmax
                    if Ucurr(J)>Uust(J)
                        OutType(J)=nTip.PU;
                        FlagMod(J)=true;
                    end
                case nTip.PUmin
                otherwise
                    warning('Неверно задан тип узла при контроле пределов генератора');
            end
        end
    end
else
    
    for J=1:N
        if FlagOneNod==0
            switch EntrType(J)
                % текущий тип генератора - PU
                case nTip.PU
                    if Qg(J)>Qbor.Qmax(J)&&(CountIter>=ParamIter)
                        OutType(J)=nTip.PUmax;
                        FlagMod(J)=true;
                        FlagOneNod=1;
                    end
                    % текущий тип генератора - PUmin
                case nTip.PUmin
                    if Ucurr(J)<Uust(J)
                        if(CountIter>=ParamIter)||Ucurr(J)<0.8*Uust(J)
                            OutType(J)=nTip.PU;
                            FlagMod(J)=true;
                            FlagOneNod=1;
                        end
                    end
                    
                case nTip.PUmax
                    if Ucurr(J)>1.2*Uust(J)
                        OutType(J)=nTip.PU;
                        FlagMod(J)=true;
                        FlagOneNod=1;
                    end
                otherwise
                    warning('Неверно задан тип узла при контроле пределов генератора');
            end
        end
    end
    if (CountIter>=ParamIter&&FlagOneNod==0)
        for J=1:N
            if FlagOneNod==0
                switch EntrType(J)
                    % текущий тип генератора - PU
                    case nTip.PU
                        if Qg(J)<Qbor.Qmin(J)
                            OutType(J)=nTip.PUmin;
                            FlagMod(J)=true;
                            FlagOneNod=1;
                        end
                        % текущий тип генератора - PUmax
                    case nTip.PUmax
                        if Ucurr(J)>Uust(J)
                            OutType(J)=nTip.PU;
                            FlagMod(J)=true;
                            FlagOneNod=1;
                        end
                    case nTip.PUmin
                    otherwise
                        warning('Неверно задан тип узла при контроле пределов генератора');
                end
            end
        end
    end
end
end