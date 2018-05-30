function [NoteNod, NoteRib] = fGraphTravel(nod, Start, nType, CommtLogical, option)
% Осуществляет обход графа в глубину. Возвращает логические массивы для
% узлов и ветвей (1 - элемент посещен при обходе, 0 - элемент не посещен)
% [NoteNod, NoteRib] = fGraphTravel(nod, Start, nType, CommtLogical, option)
% nod - структура соседних узлов и ветвей (node.an - узлы, node.ar - ветви)
% Start - начальный узел обхода%
% nType - массив типов узлов
% CommtLogical - состояние коммутационных аппаратов
% option - опция определяет учет или неучет связанности ветвей через центры питания
% «Частн» - выделение подграфов без учета связанности через центр питания;
% «Полн» - выделение подграфов с учетом связанности через центр питания;
%
% Written by D. Kovalchuk
% Research group of energetic faculty,
% department of BNTU.
% August 2017.

% Инициализация переменных
Exit=0; % Признак завершения обхода графа
n=length(nod); % Количество узлов
nZ=zeros(n,1); % Нулевой массив - количество элементов равно количеству узлов
rZ=zeros(length(CommtLogical),1); % Нулевой массив - количество элементов равно количеству ветвей
NoteNod=nZ; % Логический массив признаков посещенния узлов при обходе
NoteRib=rZ; % Логический массив признаков посещенния ветвей при обходе
StepAn=ones(n,1); % Массив, определяющий для каждого узла номер первого присоединенного узла куда не осуществлялся обход из данного
CurrN=Start; % Текущий узел в обходе
PrevN=nZ; % Предыдущий узел в обходе
Shag=0; % Количество, произведенных шагов (для защиты от зацикливания)
Return=1; % Признак, определяющий необходимость возврата к предыдущему узлу

while Exit==0
    Return=1;
    Shag=Shag+1;
    if(NoteNod(CurrN)==0)
        NoteNod(CurrN)=1; % установка отметок на узлы
    end
    if (nType(CurrN)~=nTip.BU)||(CurrN==Start)||(strcmp(option,'Полн')) % Применение опции полноты обхода
        for j=StepAn(CurrN):length(nod(CurrN).ar) % Перебор отходящих узлов, линия соединения с которыми включена и которые еще не посещены
            if(CommtLogical(nod(CurrN).ar(j))==1) 
                NoteRib(nod(CurrN).ar(j))=1; % установка отметок на ветви             
                if(NoteNod(nod(CurrN).an(j))==0)
                StepAn(CurrN)=StepAn(CurrN)+1; % переход к следующему узлу
                PrevN(nod(CurrN).an(j))=CurrN;
                CurrN=nod(CurrN).an(j);
                Return=0;
                break;
                end
            end
        end
    end
    if (Return==1) % Возврат к пред узлу
        if CurrN~=Start % Выход в случае, если из стартового узла нет путей
            CurrN=PrevN(CurrN);
        else
            Exit=1;
            break;
        end
    end
    if (Shag>=1000000) % Защита от зацикливания
        error ('Зацикливание (количество шагов превысило 10^6). Текущий узел: %s',mat2str(CurrN));
        break;
    end
end
return % Конец