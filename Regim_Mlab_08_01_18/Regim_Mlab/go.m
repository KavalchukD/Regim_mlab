function go
% Устанавливает текущие пути поиска
Paths = {
    '..\Regim_Mlab'
    };

for i = 1:length(Paths)
    if isdir(Paths{i}) && isempty(strfind(path, Paths{i}))
        addpath(genpath(Paths{i}));
    end
end

return