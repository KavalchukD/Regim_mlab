classdef cmStat < double
% cmStat  Класс определяет перечисления типов положений КА.

    enumeration
        OO (0) % Отключен с запретом
        O  (1) % Отключен
        V  (2) % Включен
        VV (3) % Включен с запретом
    end
end