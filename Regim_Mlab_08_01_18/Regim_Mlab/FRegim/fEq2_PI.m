function Eq2 = fEq2_PI(gKont, Eq1, Nn, Nb, Z, UIn)
% Функция осуществляет составление уравнений по 2-му закону Кирхгофа в виде
% структуры с соответствующими полями.
%
% Eq2 = fEq2_PI(gKont, Eq1, Nn, Nb, Z, UIn)
%
% gKont - структура графов, представляющих контуры;
% Eq1 - структура выражений по 1-му закону Кирхгофа;
% Nn - количество узлов в расчетной подсхеме;
% Nb - количество ветвей в расчетной подсхеме;
% Z - структура векторов, представляющая полные сопротивления;
% Z.R - активной сопротивление;
% Z.X - реактивное сопротивление;
% UIn - структура векторов напряжения в узлах;
% UIn.mod - вектор модулей напряжений;
% UIn.d - вектор фаз напряжений;
% Eq2 - структура, представляющая выражения по 2-му закону Кирхгофа;
% Eq2.Iv - структура векторов коэффициентов при токах независимых ветвей;
% Eq2.Iv.R - при действительной части;
% Eq2.Iv.I - при мнимой части;
% Eq2.G - структура векторов коэффициентов от генерирующих узлов;
% Eq2.G.QR - при действительной части тока генератора;
% Eq2.G.QI - при мнимой части тока генератора;
% Eq2.G.dU - при угле генератора;
% Eq2.Iu - структура векторов коэффициентов при токах узлов;
% Eq2.Iu.R - при действительной части;
% Eq2.Iu.I - при мнимой части;
% Eq2.UConst - константная составляющая от напряжений;
%
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% November 2017.

% Инициализация исходных данных
R(1,:)=Z.R(1:Nb);
X(1,:)=Z.X(1:Nb);
U=UIn.mod(1:Nn);
dU=UIn.d(1:Nn);
% Определение количества контуров всех типов и количества уравнений
nBUKont=length(gKont.BU);
nPU=length(gKont.PU);
nCycle=length(gKont.Cycle);
nKont=nBUKont+nPU+nCycle;
nEq=2*nKont;
% Выделение памяти под поля структуры уравнений по 2-му закону Кирхгофа
Eq2.Iv.R=spalloc(double(nEq), double(nKont-nPU), double((nEq)*(nKont-nPU)));
Eq2.Iv.I=spalloc(double(nEq), double(nKont-nPU), double((nEq)*(nKont-nPU)));
Eq2.G.QR=spalloc(double(nEq), double(nPU), double((nEq)*(nPU)));
Eq2.G.QI=spalloc(double(nEq), double(nPU), double((nEq)*(nPU)));
Eq2.G.dU=spalloc(double(nEq), double(nPU), double((nEq)*(nPU)));
Eq2.Iu.R=spalloc(double(nEq), double(Nn), double(nEq*int32(Nn/2)));
Eq2.Iu.I=spalloc(double(nEq), double(Nn), double(nEq*int32(Nn/2)));
Eq2.UConst=spalloc(double(nEq), 1, double(nEq));
% Составление уравнений
% Для контуров типа БУ (между балансирующими узлами)
for J=1:nBUKont
    % Определение знака тока ветви в уравнении
    Sign=fSignEq2_PI(gKont.BU(J));
    K=1:gKont.BU(J).rib.n;
    RibN=gKont.BU(J).rib(K);
    % Добавление к уравнениям составляющих от токов узлов
    % В первое уравнение для контура (действительная часть)
    Eq2.Iu.R(2*J-1,:)=(R(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    Eq2.Iu.I(2*J-1,:)=-(X(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    % Во второе уравнение для контура (мнимая часть)
    Eq2.Iu.R(2*J,:)=(X(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    Eq2.Iu.I(2*J,:)=(R(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    
    % Добавление к уравнениям составляющих от токов ветвей
    % В первое уравнение для контура (действительная часть)
    Eq2.Iv.R(2*J-1,:)=(R(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    Eq2.Iv.I(2*J-1,:)=-(X(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    % Во второе уравнение для контура (мнимая часть)
    Eq2.Iv.R(2*J,:)=(X(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    Eq2.Iv.I(2*J,:)=(R(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    clear RibN Sign;
    
    % Добавление составляющей от разности напряжений по концам контура
    % Выделяем случай когда один и тот же БУ на разных концах цикла БУ-БУ
    if ((gKont.BU(J).rib(1).ny1~=gKont.BU(J).nod.n)&&...
            (gKont.BU(J).rib(1).ny2~=gKont.BU(J).nod.n))...
            ||gKont.BU(J).rib.n==1
        % Определение знака составляющей от напряжений в уравнении
        if gKont.BU(J).rib(1).ny1==1
            SignU=1;
        elseif gKont.BU(J).rib(1).ny2==1
            SignU=-1;
        else
            error(['Ошибка определения знака составляющей',...
                'от разности напряжений']);
        end
        % Добавка составляющей от напряжений
        % В первое уравнение для контура (действительная часть)
        Eq2.UConst(2*J-1,1)=1000*(U(gKont.BU(J).nod.n)*...
            cos(dU(gKont.BU(J).nod.n))-U(gKont.BU(J).nod.n)*...
            cos(dU(gKont.BU(J).nod(1))))*SignU;
        % Во второе уравнение для контура (мнимая часть)
        Eq2.UConst(2*J,1)=1000*(U(gKont.BU(J).nod.n)...
            *sin(dU(gKont.BU(J).nod.n))-U(gKont.BU(J).nod.n)...
            *sin(dU(gKont.BU(J).nod(1))))*SignU;
    end
end

% Для контуров типа цикл, образованы циклами в графе
for J=1:nCycle
    % Определение знака тока ветви в уравнении
    JJ=nBUKont+J;
    Sign=fSignEq2_PI(gKont.Cycle(J));
    K=1:gKont.Cycle(J).rib.n;
    RibN=gKont.Cycle(J).rib(K);
    % Добавление составляющих от токов узлов
    % В первое уравнение для контура (действительная часть)
    Eq2.Iu.R(2*JJ-1,:)=(R(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    Eq2.Iu.I(2*JJ-1,:)=-(X(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    % Во второе уравнение для контура (мнимая часть)
    Eq2.Iu.R(2*JJ,:)=(X(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    Eq2.Iu.I(2*JJ,:)=(R(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    
    % Добавление составляющих от токов ветвей
    % В первое уравнение для контура (действительная часть)
    Eq2.Iv.R(2*JJ-1,:)=(R(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    Eq2.Iv.I(2*JJ-1,:)=-(X(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    % Во второе уравнение для контура (мнимая часть)
    Eq2.Iv.R(2*JJ,:)=(X(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    Eq2.Iv.I(2*JJ,:)=(R(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    clear K RibN Sign;
end

% Для контуров между балансирующим узлов и PU-узлом
for J=1:nPU
    % Определение знака тока ветви в уравнении
    JJ=nBUKont+nCycle+J;
    Sign=fSignEq2_PI(gKont.PU(J));
    K=1:gKont.PU(J).rib.n;
    RibN=gKont.PU(J).rib(K);
    % Добавление составляющих от токов узлов
    % В первое уравнение для контура (действительная часть)
    Eq2.Iu.R(2*JJ-1,:)=(R(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    Eq2.Iu.I(2*JJ-1,:)=-(X(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    % Во второе уравнение для контура (мнимая часть)
    Eq2.Iu.R(2*JJ,:)=(X(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    Eq2.Iu.I(2*JJ,:)=(R(RibN).*Sign(K))*Eq1.Iu(RibN,:);
    
    % Добавление составляющих от токов ветвей
    % В первое уравнение для контура (действительная часть)
    Eq2.Iv.R(2*JJ-1,:)=(R(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    Eq2.Iv.I(2*JJ-1,:)=-(X(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    % Во второе уравнение для контура (мнимая часть)
    Eq2.Iv.R(2*JJ,:)=(X(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    Eq2.Iv.I(2*JJ,:)=(R(RibN).*Sign(K))*Eq1.InDep(RibN,:);
    clear K RibN Sign;
    % Добавка составляющей от напряжений
    % определение знака составляющей от напряжений в уравнении
    if gKont.PU(J).rib(1).ny1==1
        SignU=1;
    elseif gKont.PU(J).rib(1).ny2==1
        SignU=-1;
    end
    % Добавление составляющей от модуля напряжений
    % В первое уравнение для контура (действительная часть)
    Nnod=gKont.PU(J).nod.n;
    Eq2.UConst(2*JJ-1,1)=1000*(U(gKont.PU(J).nod(Nnod))...
        *cos(dU(gKont.PU(J).nod(Nnod))))*SignU;
    % Во второе уравнение для контура (мнимая часть)
    Eq2.UConst(2*JJ,1)=1000*(U(gKont.PU(J).nod(Nnod))...
        *sin(dU(gKont.PU(J).nod(Nnod))))*SignU;
    % Добавление составляющей от фазы напряжений в первое и второе
    % уравнение для контура
    Eq2.G.dU(2*JJ-1:2*JJ,J)=-1000*U(gKont.PU(J).nod(1))*SignU;
end
for J=1:nPU
    % Добавление составляющей от реактивной мощности генераторных узлов
    Eq2.G.QR(:,J)=Eq2.Iu.R(:,gKont.PU(J).nod(1));
    Eq2.G.QI(:,J)=Eq2.Iu.I(:,gKont.PU(J).nod(1));
end
end