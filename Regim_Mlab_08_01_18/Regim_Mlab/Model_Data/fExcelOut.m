function StatePlot = fExcelOut(hM, filename)
% Осуществляет вывод полей объекта типа CModelRS по узлам, ветвям и общим
% данным в excel файл название, которого передается в исходных данных.
%
% StatePlot = fExcelOut(hM, filename)
% hM - объект класса CModelRS;
% filename - строка с названием файла результатов;
% StatePlot - возвращает 1, если печать прошла успешно, 0 в ином случае;
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% December 2017.

sheetN = 1; % номер листа с данными по узлам
sheetB = 2; % номер листа с данными по ветвям
sheetO = 3; % номер листа с общими данными
xlRange = 'A2';
Empty{1500,10}=0;
% чистка файла
StatePlot=xlswrite(filename,...
    Empty,...
    1,xlRange);
StatePlot=xlswrite(filename,...
    Empty,...
    2,xlRange);
StatePlot=xlswrite(filename,...
    Empty,...
    3,xlRange);
clear Empty;

% вывод данных по узлам
for J=1:hM.NODE.n
    OutN{J,1}=hM.NODE(J).Nn1; % номер узла
    % вывод типа узла
    switch hM.NODE(J).CurrType
        case nTip.PQ
            OutN{J,2}='Нагр';
        case nTip.BU
            OutN{J,2}='ЦП';
        case nTip.PU
            OutN{J,2}='Ген';
        case nTip.PUmax
            OutN{J,2}='Ген+';
        case nTip.PUmin
            OutN{J,2}='Ген-';
    end
    OutN{J,3}=hM.NODE(J).Pn; % активная мощность нагрузки
    OutN{J,4}=hM.NODE(J).Qn; % реактивная мощность нагрузки
    OutN{J,5}=hM.NODE(J).Pg; % активная мощность генерации
    OutN{J,6}=hM.NODE(J).QgR; % реактивная мощность генерации
    OutN{J,7}=hM.NODE(J).Qmin; % нижние пределы реактивной мощности
    OutN{J,8}=hM.NODE(J).Qmax; % верхние пределы реактивной мощности
    OutN{J,9}=hM.NODE(J).Unn; % модуль напряжения в узле
    OutN{J,10}=hM.NODE(J).dU*180/pi; % фаза напряжения в узле
end
% Запись данных по узлам в файл
StatePlotN=xlswrite(filename,...
    OutN,sheetN,xlRange);
clear OutN;

% запись данных по ветвям
xlRange = 'A2';
for J=1:hM.BRAN.n
    OutB{J,1}=hM.BRAN(J).Nb1; % номер ветви
    OutB{J,2}=hM.BRAN(J).NbSt; % номер начала ветви
    OutB{J,3}=hM.BRAN(J).NbF; % номер конца ветви
    % запись типа ветви
    switch hM.BRAN(J).Type
        case bTip.T
            OutB{J,4}='Транс';
        case bTip.L
            OutB{J,4}='Линия';
    end
    OutB{J,5}=hM.BRAN(J).Pn; % активная мощность начала
    OutB{J,6}=hM.BRAN(J).Qn; % реактивная мощность начала
    OutB{J,7}=hM.BRAN(J).Pk; % активная мощность конца
    OutB{J,8}=hM.BRAN(J).Qk; % реактивная мощность конца
    OutB{J,9}=hM.BRAN(J).Is; % ток ветви
    OutB{J,10}=hM.BRAN(J).dU; % потери напряжения на ветви
end
% запись данных в файл
StatePlotB=xlswrite(filename,...
    OutB,sheetB,xlRange);
clear OutB;
% запись общих данных
xlRange = 'A2';
    OutO{1}=hM.COMM.pgen; % активная генерация
    OutO{2}=hM.COMM.ppotr; % активная мощность нагрузки
    OutO{3}=hM.COMM.qgen; % реактивная мощность генерации
    OutO{4}=hM.COMM.qpotr; % реактиная мощность потребителей
    OutO{5}=hM.COMM.dp; % потери активной мощности
    OutO{6}=hM.COMM.dq; % потери реактивной мощности
    OutO{7}=hM.COMM.dpn; % нагрузочные потери активной мощности
    OutO{8}=hM.COMM.dpx; % потери активной мощности холостого хода
    OutO{9}=hM.COMM.LINE.dp; % потери активной мощности в линиях 
    OutO{10}=hM.COMM.TRANS.dp; % потери активной мощности в трансформаторах
    % запись общих данных в Excel
StatePlotO=xlswrite(filename,...
    OutO,...
    sheetO,xlRange);
clear OutO;
% создание результурующей переменной статуса печати, которая является
% логической суммой статуса печати по листам
if StatePlotN==1 && StatePlotB==1 && StatePlotO==1
    StatePlot=1;
else
    StatePlot=0;
end
end