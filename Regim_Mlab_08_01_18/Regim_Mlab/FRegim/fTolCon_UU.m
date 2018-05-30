function varargout = fTolCon_UU(g, Sin, Ibu, Zin, Uin, Options)
% Функция осуществляет контроль точности определения напряжений и токов
% путем расчета небалансов по узловым уравнениям, умноженных на величину
% опорного напряжения.
%
% varargout = fTolCon_UU(g, Sin, Ibu, Zin, Uin, Options)
%
% g - граф расчетной подсхемы, представленный объектом типа CGraph;
% Sin - структура векторов мощностей узлов;
% Ibu - структура векторов токов балансирующих узлов;
% Zin - структура векторов сопротивлений;
% Uin - структура векторов напряжений узлов;
% Options - опции расчета;
% Options.TolFun - точность расчета в кВт;
% varargout - cell-массив выходных данных функции;
% varargout{1} - параметр, показывающий достижение заданной точности,
% 0 - точность не достигнута, 1 - точность достигнута;
% varargout{2} - вектор небалансов по узловым уравнениям, позволяет оценить
% точность расчетов
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% November 2017.

switch nargin
    case 6
        TolFun=Options.TolFun;
    case 5
        TolFun=10^(-2);
    case 4
    otherwise
    error('Неверное количество входных параметров');
end
% нужно упростить контроль так как контроль по узловым уравнениям все равно
% не дает нормального результата при контроле токов, а не исходных
% мощностей
U=Uin.mod.*cos(Uin.d)+1i*Uin.mod.*sin(Uin.d);
S=Sin.P+1i*Sin.Q;
K=1:g.rib.n;
Z(K)=Zin.R(g.rib(K))+1i*Zin.X(g.rib(K));
clear K;
Nb_UU(g.nod.n)=0;
% добавление узлового тока для небалансирующих узлов
Nb_UU(Ibu.I1==0)=-(conj(S(Ibu.I1==0)./U(Ibu.I1==0)));
% добавление узлового тока для балансируюх узлов
Nb_UU(Ibu.I1~=0)=Nb_UU(Ibu.I1~=0)+Ibu.I1(Ibu.I1~=0);
Nb_UU(Ibu.I2~=0)=Nb_UU(Ibu.I2~=0)+1i*Ibu.I2(Ibu.I2~=0);
for J=1:g.nod.n;
    AN=g.nod(J).an;
    AR=g.nod(J).ar;
    % добваление составляющих от напряжений соседних узлов
    for K=1:length(AN)
        Nb_UU(J)=Nb_UU(J)+1000*(U(AN(K))-U(J))./Z(AR(K));
    end
    clear AN AR;
end
% умножение небаланса на величину напряжения для перевода из тока в
% мощность
Nb_UU=(Nb_UU).*U';
% задание признака выхода из решения контурных уравнений по достижению
% заданной точности
if sum(abs(Nb_UU)>TolFun)==0
    TolOk=1;
else
    TolOk=0;
end
    varargout{1}=TolOk;
if nargout==2
   varargout{2}=abs(Nb_UU);
end
end