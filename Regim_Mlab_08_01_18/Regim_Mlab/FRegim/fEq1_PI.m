function [Eq1] = fEq1_PI(g, Hord, InTypeN, Nop)
% Функция осуществляет вывод выражений токов зависимых ветвей через
% контурные токи и токи узлов путем решения линейной системы уравений
% методом LU-разложения.
%
% [Eq1] = fEq1_PI(g, Hord, InTypeN, Nop)
%
% g - граф расчетной подсхемы, представленный объектом типа CGraph;
% Hord - список хорд в графе;
% InTypeN - типы узлов;
% Nop - номер опорного узла;
% Eq1 - структура матриц выражений по первому закону Кирхгофа;
% Eq1.Iu - матрица коэффициентов при токах узлов для выражения тока
% соответствующей ветви;
% Eq1.InDep - матрица коэффициентов при токах независимых ветвей;
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% November 2017.

% инициализация данных о графе
Nn=int32(g.nod.n);
TypeN=InTypeN(1:Nn);
Nb=int32(g.rib.n);
Nod=int32(g.nod);
Rib=int32(g.rib);
Ny1=int32(g.rib(:).ny1);
Ny2=int32(g.rib(:).ny2);
% создание перечней баланисирующих узлов и узлов типа PU, индексация
% полученных массивов с опорой на подсхему
nBU=int32(0);
nPU=int32(0);
% для всех узлов
J=1:Nn;
% создание перечня балансирующих узлов
BU=J(TypeN(J) == nTip.BU);
nBU=length(BU);
% создание перечня генераторных узлов
PU=J(TypeN(J) == nTip.PU);
nPU=length(PU);
nCycle=length(Hord);
clear J;
% определение количества контуров
nKont=nCycle+nPU;
for J=1:nBU
    nKont=nKont+length(g.nod(BU(J)).ar);
end
nKont=nKont-1;
%
% выделение памяти под массив правой части уравнений
Eq1B=spalloc(double(Nn), double(nKont-nPU), double((Nn)*2));
% Создание пометок на ветвях, ток которых является независимой переменной
Independ(Nb)=false;
CountBU=0;
% для всех балансирующих узлов
for J=1:nBU
    % отходящие ветви от балансирующего узла
    AR=g.nod(BU(J)).ar;
    % для всех отходящих ветвей
    for K=1:length(AR)
        % если не первая отходящая ветвь от опорного узла
        if (J~=Nop)||(K~=1)
            % присвоение признаков Independ
            Independ(AR(K))=1;
            CountBU=CountBU+1;
            % создание правой части уравнений для узлов, которые
            % присоединены к балансирующим узлам
            if TypeN(Ny1(AR(K)))~=nTip.BU
                Eq1B(Ny1(AR(K)), CountBU)=1;
            elseif TypeN(Ny2(AR(K)))~=nTip.BU
                Eq1B(Ny2(AR(K)), CountBU)=-1;
            end
        end
    end
    clear AR;
end
% для всех хорд признак независимости равен 1
Independ(Hord)=1;
% создание правой части уравений для узлов, которые присоединены к хордам
for J=1:nCycle;
    Eq1B(Ny1(Hord(J)), CountBU+J)=1;% в графе
    Eq1B(Ny2(Hord(J)), CountBU+J)=-1;
end
% выдедение памяти под левую часть уравнений
Eq1A=spalloc(double(Nn), double(Nb), double((Nn-nBU)*4));

% Составление уравнений по первому закону Кирхгофа, уравнение представлено
% в виде А*Х=В, где А и В матрицы описанных размеров, для первого закона
% Кирхгофа элементы матриц А и В могут принимать значения -1, 0, 1.
Counter=0;
% для всех узлов
for J=1:Nn
    AR=int32(g.nod(J).ar);
    % для всех отходящих линий
    for K=1:length(AR);
        % если узел не балансирующий и ток ветви - зависимый
        if TypeN(J)~=nTip.BU && Independ(AR(K))==0
            % если рассматриваемый узел начало рассматриваемой ветви
            if J==Ny1(AR(K))
                Eq1A(J, AR(K))=-1;
            elseif J==Ny2(AR(K)) % если конец
                Eq1A(J, AR(K))=1;
            end
        end
    end
    clear AR;
end
% добавление к правой части уравнений узловых токов
Eq1B=[sparse(eye(Nn)),Eq1B];
% выделение памяти под матрицу, храняющую решение системы
Eq1Full=spalloc(double(Nb), double(Nn+nKont-nPU), double((Nb)*4));
% решение системы уравений методом LU-разложения
Eq1Full=Eq1A(TypeN~=nTip.BU,:)\Eq1B(TypeN~=nTip.BU,:);
clear Eq1A Eq1B;
% создание выходных структур
% по токам узлов
Eq1.Iu=sparse(double(Nb), double(Nn));
Eq1.Iu=Eq1Full(:,1 : Nn);
% по независимым ветвям
Eq1.InDep=sparse(double(Nb), double(nKont-nPU));
Eq1.InDep=Eq1Full(:,Nn+1 : Nn+nKont-nPU);
clear Eq1Full;
CountBU=0;
% присвоение 1 соотвествующим элементам
% для балансирующих узлов
for J=1:nBU
    AR=g.nod(BU(J)).ar;
    for K=1:length(AR)
        if (J~=Nop)||(K~=1)
            CountBU=CountBU+1;
            Eq1.InDep(AR(K), CountBU)=1;
        end
    end
    clear AR;
end
% для хорд
for J=1:nCycle;
    Eq1.InDep(Hord(J), CountBU+J)=1;
end
end