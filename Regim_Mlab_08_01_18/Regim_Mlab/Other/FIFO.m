classdef FIFO
    % FIFO  Value-класс - организует работу со стеком типа первый вошел первый ушел
    
    % Written by D. Kovalchuk
    % Research group of energetic faculty,
    % department of BNTU.
    % Jule 2017.
    
    properties(Access = private)
        QUEUE  % Стек
        LAST % Последний элемент
        SIZED % Признак строгой размерности (1- строгая, 0 - нестрогая)
        SCONST % Количество элементов, добавляемое на каждом шаге увеличения размера очереди для очереди нестрогой размерности
        TYPE % Тип элементов стека
    end
    
    methods
        function Stack = FIFO(varargin)
            % Stack  Конструктор.
            Stack.SCONST = 10;
            switch length(varargin)
                case 0
                    Stack.TYPE = double(0);
                    Stack.QUEUE (Stack.SCONST) = Stack.TYPE;
                    Stack.LAST = 0;
                    Stack.SIZED = 0;
                case 1
                    Stack.TYPE = varargin{1};
                    Stack.QUEUE (Stack.SCONST) = Stack.TYPE;
                    Stack.LAST = 0;
                    Stack.SIZED = 0;
                case 2
                    Stack.TYPE = varargin{1};
                    Stack.QUEUE (varargin{2}) = Stack.TYPE;
                    Stack.LAST = 0;
                    Stack.SIZED = 1;             
            end
        end

        function B = subsref(Stack, S)
            % Метод индексной ссылки. Выполняет обращение к полям объекта
            % по принятым правилам синтаксиса индексации.
            %
            % B = subsref(g, S)
            %
            % Stack - объект; S - массив структур индексации объекта; B -
            % результат обращения к объекту по индексной ссылке.
            
            if length(S) == 1 &&...
                    strcmp(S(1).type, '.')
                
                switch S(1).subs
                    case 'n' % количество элементов
                        B = Stack.LAST;
                    case 'len' % текущая длина стека
                        B = length(Stack.QUEUE);
                    case 'last' % первый в очереди элемент (первый записанный)
                        B = Stack.QUEUE(1);
                    case 'list' % список элементов
                        B = Stack.QUEUE(:);
                    case 'options' % список элементов
                        B.SIZED = Stack.SIZED;
                        B.SCONST = Stack.SCONST;
                        B.SCONST = Stack.SCONST;
                    otherwise
                        B = 0;
                end     
            %elseif length(S) == 1
            %    str = Stack.s2str(S);
            %    B = eval(['Stack.QUEUE', str]);
            else
                msg = ['Неверный формат обращения к стеку'];
                warning(msg);
            end
        end
        
        function Stack = add(Stack, Obj)
            % Метод добавляет элемент последним в стек. Возможно добавление
            % произвольных типов элементов, а также массивов элементов.
            % Осуществляется преобразование типов добавляемых элементов к
            % типу элементов стека, при невозможности преобразования запись
            % не происходит.
            %
            % Stack = add(Stack, Obj)
            %
            % Stack - объект типа очередь.
            % Obj - добавляемый элемент       

            % выделение памяти
            if (length(Stack.QUEUE)<Stack.LAST+length(Obj))
                if Stack.SIZED==0
                    if length(Obj)<=Stack.SCONST
                        nAdd=Stack.SCONST;
                        Stack.QUEUE(length(Stack.QUEUE)+Stack.SCONST) = Stack.TYPE;
                    else
                        nAdd=Stack.SCONST*fix(Stack.SCONST/length(Stack.QUEUE));
                        Stack.QUEUE(length(Stack.QUEUE)+nAdd) = Stack.TYPE;
                    end
                else
                    msg = ['Ошибка переполнения стека, запись не произведена'];
                    warning(msg);
                end
            end 
            % при ошибке возвращается warning, а запись отменяется
            try
                if length(Obj)==1
                    Stack.LAST=Stack.LAST+1;
                    Stack.QUEUE(Stack.LAST)=Obj;
                else
                    Stack.QUEUE(Stack.LAST+1:Stack.LAST+length(Obj))=Obj;
                    Stack.LAST=Stack.LAST+length(Obj);                    
                end
            catch
                warning('Неверный тип. Запись не произведена');
                Stack.QUEUE((length(Stack.QUEUE)-nAdd+1):length(Stack.QUEUE))=[];
                return
            end
        end
        
        function TF = isempty(Stack)
            % Метод возвращает true если объект пустой.
            %
            % TF = isempty(Stack)
            %
            % Stack - объект.
            if (Stack.LAST==0)
                TF=1;
            else
                TF=0;
            end
        end
        
        function Stack=del(Stack)
            % Удаляет последний элемент из стека
            %
            % Stack=del(Stack)
            %
            % Stack - объект.
            if Stack.LAST~=0
                Stack.LAST=Stack.LAST-1;
                Stack.QUEUE(1:Stack.LAST)=Stack.QUEUE(2:Stack.LAST+1);
                Stack.QUEUE(Stack.LAST+1)=0;
                if ((Stack.LAST+2*Stack.SCONST) <= length (Stack.QUEUE)) && (Stack.SIZED == 0)
                   Stack.QUEUE((length (Stack.QUEUE)-Stack.SCONST+1):end)=[]; 
                end
            else
                msg = ['Стек пустой, удаление не произведено'];
                display(msg);
            end
        end
        
    end
    methods (Access = private)
                function QUEUE = subsasgn(Stack, S, B)
            
            % Метод индексного присваивания. Выполняет присваивание полям
            % объекта новых значений. Синтаксис индексации полей объекта
            % осуществляется по принятым правилам.
            %
            % hM = subsasgn(hM, S, B)
            %
            % hM - handel объекта; S - структура индексации объекта; B -
            % присваиваемое значение.
            
            str = Stack.s2str(S);
            eval(['Stack', str, '=', num2str(B),';']);
                end
    end
    methods(Static, Access = private)
        function Str = s2str(S)
            % Метод преобразует массив структур индексации объекта в строку
            % без изменения синтаксиса обращения.
            %
            % Str = s2str(S)
            %
            % S - массив структур индексной ссылки; Str - строка индексации
            % объекта.
            
            Str = [];
            for i = 1:length(S)
                switch S(i).type
                    case '()'
                        Str = [Str, S(i).type(1)]; %#ok<AGROW>
                        for j = 1:length(S(i).subs)
                            Str = [Str, mat2str(S(i).subs{j})]; %#ok<AGROW>
                            if j < length(S(i).subs)
                                Str = [Str, ',']; %#ok<AGROW>
                            end
                        end
                        Str = [Str, S(i).type(2)]; %#ok<AGROW>
                    case '.'
                        Str = [Str, S(i).type, S(i).subs]; %#ok<AGROW>
                end
            end
        end
    end
end