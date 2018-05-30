function Fsign = fSignEq2_PI(g)
% ќсуществл€ет определение знаков составл€ющих от токов ветвей в уравнени€х
% по 2-му закону  ирхгофа на основании направлений ветвей в графе. «нак
% положительный когда ветвь сонаправлена с первой ветвью контура,
% отрицательный, когда противонаправлена.
%
% Fsign = fSignEq2(g)
% Fsign - выходной вектор, который может принимать значени€ -1 и 1;
% g - объект CGraph, содержащий рассматриваемый контур;
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% October 2017.

Flag=0;
Fsign(1:g.rib.n)=1;
% инициализаци€ знака первой ветви единицей
Fsign(1)=1;
for I=2:g.rib.n
    % определение абсолютного направлени€ рассматриваемой ветви
    if (g.rib(I).ny1==g.rib(I-1).ny2)
        Fsign(I)=1;
    elseif (g.rib(I).ny2==g.rib(I-1).ny2)
        Fsign(I)=-1;
    elseif (g.rib(I).ny1==g.rib(I-1).ny1)
        Fsign(I)=-1;
    elseif (g.rib(I).ny2==g.rib(I-1).ny1)
        Fsign(I)=1;
    else
        error('ќшибка функции выбора знака');
    end
    % определение направлени€ рассматриваемой ветви относительно первой
    Fsign(I)=Fsign(I)*Fsign(I-1);
end
end