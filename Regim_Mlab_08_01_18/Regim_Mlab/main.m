%--------------------------------------------------------------------------
% MATLAB скрипт.
%
% Скрипт является управляющим блоком для расчета режима, использует
% окружение для создание модели сети, графа, представляющего сеть,
% графического вывода схемы и расчета режима сети.
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% December 2017.
%--------------------------------------------------------------------------
% запись путей доступа к файлам программы в перечень путей Matlab
go;
% создание структуры опций расчета режима, где Method - метод ввода данных
% (необходим при расширении системы), NodeSheet - номер листа исходных
% данных по узлам, BranchSheet - номер листа исходных данных по ветвям,
% TolFun - точность расчета в кВт.
%
inopts = struct('Method', methTip (0),'NodeSheet', 1, 'BranchSheet',2, 'TolFun', 1*10^-2);
% ввод имени Excel файла
xlsFile = '\Excel Data\Исходные_данные_5';
xlsOut = '\Excel Data\Результаты';
% ввод исходных данных в объект класса CData
oDt=CData(xlsFile, inopts);
% создание модели объекта на основании исходных данных класса CData
hM = CModelRS(oDt.NODE, oDt.BRAN, oDt.COMM);
clear oDt;
% создание handle указателей на номера узлов и ветвей в модели, типов узлов
% и состояния коммутационных аппаратов
hFN = @(I)hM.NODE(I).Nn1;
hFV = @(I)[hM.BRAN(I).NbSt  hM.BRAN(I).NbF];
hType =@(I)hM.NODE(I).Type;
hComt = @(I)[hM.BRAN(I).CmStS  hM.BRAN(I).CmStF];
% создание графа схемы
g = CGraph(hFN, (1:hM.NODE.n)', hFV, (1:hM.BRAN.n)');
% графическое отображение полного графа сети
optionPlot.MarkRib=0;
Plot=fGraphPlot(g, optionPlot);
% разбинение общего графа на подграфы (хранение данных в массиве типа CGraph)
optSubGraph = struct('Size', 'Частн','Commt','С КА','Origin', 'Модель');
gSub= fGraphSub(g, hFN, hFV, hType, hComt, optSubGraph);
for J=1:length(gSub)-1
    % создание ссылок на необходимые поля объекта модели
    InputCalcReg=fInputCalcReg_PI(gSub(J),hM);
    [NODE, RIB, DiagnRegim]=fDriveRegim_PI(gSub(J),InputCalcReg);
    % запись в модель результатов расчета режима по узлам
    hM.NODE(gSub(J).nod).QgR=NODE.QgR;
    hM.NODE(gSub(J).nod).CurrType=NODE.CurrType;
    hM.NODE(gSub(J).nod).U=NODE.U;
    hM.NODE(gSub(J).nod).dU=NODE.dU;
    % запись в модель результатов расчета режима по ветвям
    clear NODE;
    hM.BRAN(gSub(J).rib).Pn=RIB.Pn;
    hM.BRAN(gSub(J).rib).Pk=RIB.Pk;
    hM.BRAN(gSub(J).rib).Qn=RIB.Qn;
    hM.BRAN(gSub(J).rib).Qk=RIB.Qk;
    clear RIB;
end
% расчет суммарных потерь в сети
hM = CalcSum(hM);
% расчет напряжений по низкой стороне трансформаторов
hM = CalcUT(hM);
% запись результатов расчета в xls-файл
StatePlot = fExcelOut(hM, xlsOut);
if StatePlot==1
    display(['Расчет завершен. Результаты расчетов приведены в xls файле ', xlsOut]);
else
    warning(['неудачная запись в файл результатов расчета режима ',xlsOut]);
end
% завершение работы программы