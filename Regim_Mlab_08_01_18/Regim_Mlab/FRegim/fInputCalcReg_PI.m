function InputReg = fInputCalcReg_PI(g, hM)
% Функция. Осуществляет создание ссылок на поля модели для ввода исходных
% данных в функцию управления расчетом режима fDriveRegim, а также
% приведение индексов к нумерации графа подсхемы.
%
% InputReg = fInputCalcReg_PI(g, hM)
% g - граф расчетной подсхемы в виде объекта класса CGraph;
% hM - модель рассчитываемой распределительной сети класса CModelRS;
% InputReg - структура ссылок на поля модели:
% InputReg.COMM - структура общих данных;
% InputReg.NODE - структура ссылок на данные о узлах;
% InputReg.BRAN - структура ссылок на данные о ветвях;
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% August 2017.

% общие данные
InputReg.COMM.Un= hM.COMM.Un;                  % номинальное напряжение
InputReg.COMM.TolFun= hM.COMM.TolFun;          % точность расчета
% данные о узлах
InputReg.NODE.Uu=@(I)hM.NODE(g.nod(I)).Uu;     % данные о модуле напряжений
InputReg.NODE.dUu=@(I)hM.NODE(g.nod(I)).dUu;   % данные о угле напряжения
% (начальное приближение и уставка для балансирующих узлов)
InputReg.NODE.Pn=@(I)hM.NODE(g.nod(I)).PnX;    % данные о активной нагрузке
InputReg.NODE.Pg=@(I)hM.NODE(g.nod(I)).Pg;     % данные о активной генерации
InputReg.NODE.Qn=@(I)hM.NODE(g.nod(I)).QnX;    % данные о реактивной нагрузке
InputReg.NODE.Qg=@(I)hM.NODE(g.nod(I)).QgR;    % данные о реактивной генерации
InputReg.NODE.Qmin=@(I)hM.NODE(g.nod(I)).Qmin; % данные о нижнем пределе реактивной мощности для PU-узла
InputReg.NODE.Qmax=@(I)hM.NODE(g.nod(I)).Qmax; % данные о верхнем пределе реактивной мощности для PU-узла
InputReg.NODE.Type=@(I)hM.NODE(g.nod(I)).Type; % данные о типе узла
% данные о ветвях
InputReg.BRAN.R=@(I)hM.BRAN(g.rib(I)).R;       % величина активного сопротивления ветви
InputReg.BRAN.X=@(I)hM.BRAN(g.rib(I)).X;       % величина реактивного сопротивления ветви
InputReg.BRAN.Pxx=@(I)hM.BRAN(g.rib(I)).Pxx;   % величина активной мощности холостого хода ветви
InputReg.BRAN.Qxx=@(I)hM.BRAN(g.rib(I)).Qxx;   % величина реактивной мощности холостого хода ветви
InputReg.BRAN.kt=@(I)hM.BRAN(g.rib(I)).kt;     % величина коэффициента трансформации
InputReg.BRAN.Type=@(I)hM.BRAN(g.rib(I)).Type; % ланные о типе ветви
end

