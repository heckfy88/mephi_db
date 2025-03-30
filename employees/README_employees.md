# Проект базы данных сотрудников

## Обзор проекта

Этот проект реализует SQL базу данных для хранения и управления информацией о сотрудниках компании, их ролях, отделах, проектах и задачах. База данных разработана для демонстрации навыков SQL, включая создание таблиц, определение связей, вставку данных и выполнение сложных запросов с использованием рекурсивных CTE, подзапросов и агрегации.

## Цели проекта

- Создать нормализованную схему базы данных для хранения информации о сотрудниках и организационной структуре
- Реализовать связи между сотрудниками, отделами, ролями, проектами и задачами
- Продемонстрировать возможности SQL-запросов для анализа иерархических данных
- Показать использование рекурсивных CTE для обхода иерархических структур
- Демонстрация работы с агрегатными функциями и условной логикой в SQL

## Структура базы данных

База данных состоит из пяти основных таблиц:

### 1. Таблица Departments (Отделы)

Хранит информацию об отделах компании:

- `DepartmentID`: Идентификатор отдела (первичный ключ)
- `DepartmentName`: Название отдела

### 2. Таблица Roles (Роли)

Хранит информацию о ролях сотрудников:

- `RoleID`: Идентификатор роли (первичный ключ)
- `RoleName`: Название роли

### 3. Таблица Employees (Сотрудники)

Хранит информацию о сотрудниках:

- `EmployeeID`: Идентификатор сотрудника (первичный ключ)
- `Name`: Имя сотрудника
- `Position`: Должность сотрудника
- `ManagerID`: Внешний ключ, ссылающийся на таблицу Employees (руководитель)
- `DepartmentID`: Внешний ключ, ссылающийся на таблицу Departments
- `RoleID`: Внешний ключ, ссылающийся на таблицу Roles

### 4. Таблица Projects (Проекты)

Хранит информацию о проектах:

- `ProjectID`: Идентификатор проекта (первичный ключ)
- `ProjectName`: Название проекта
- `StartDate`: Дата начала проекта
- `EndDate`: Дата окончания проекта
- `DepartmentID`: Внешний ключ, ссылающийся на таблицу Departments

### 5. Таблица Tasks (Задачи)

Хранит информацию о задачах:

- `TaskID`: Идентификатор задачи (первичный ключ)
- `TaskName`: Название задачи
- `AssignedTo`: Внешний ключ, ссылающийся на таблицу Employees
- `ProjectID`: Внешний ключ, ссылающийся на таблицу Projects

## Связи между сущностями

- Каждый сотрудник может иметь руководителя (связь Employees и Employees)
- Каждый сотрудник принадлежит к определенному отделу (связь Employees и Departments)
- Каждый сотрудник имеет определенную роль (связь Employees и Roles)
- Каждый проект связан с определенным отделом (связь Projects и Departments)
- Каждая задача назначена определенному сотруднику (связь Tasks и Employees)
- Каждая задача относится к определенному проекту (связь Tasks и Projects)

## Реализованная функциональность

### Инициализация базы данных (init.sql)

- Создание таблиц с соответствующими ограничениями
- Вставка примеров данных для отделов, ролей, сотрудников, проектов и задач

### Запрос 1: Иерархия подчиненных (1.sql)

Этот запрос находит всех сотрудников, подчиняющихся Ивану Иванову (с EmployeeID = 1), включая их подчиненных и подчиненных подчиненных. Для каждого сотрудника выводится подробная информация, включая отдел, роль, проекты и задачи.

```sql
WITH RECURSIVE EmployeeHierarchy AS (
    -- Базовый случай: сотрудники, непосредственно подчиняющиеся Ивану Иванову
    SELECT 
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM 
        Employees e
    WHERE 
        e.ManagerID = 1

    UNION ALL

    -- Рекурсивный случай: подчиненные подчиненных
    SELECT 
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM 
        Employees e
    JOIN 
        EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
)

SELECT 
    eh.EmployeeID,
    eh.Name,
    eh.ManagerID,
    d.DepartmentName,
    r.RoleName,
    -- Конкатенация названий проектов через запятую с обработкой NULL
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Tasks t
            JOIN Projects p ON t.ProjectID = p.ProjectID
            WHERE t.AssignedTo = eh.EmployeeID
        ) THEN (
            SELECT 
                STRING_AGG(DISTINCT p.ProjectName, ',' ORDER BY p.ProjectName)
            FROM 
                Tasks t
            JOIN 
                Projects p ON t.ProjectID = p.ProjectID
            WHERE 
                t.AssignedTo = eh.EmployeeID
        )
        ELSE NULL
    END AS Projects,
    -- Конкатенация названий задач через запятую с обработкой NULL
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Tasks t
            WHERE t.AssignedTo = eh.EmployeeID
        ) THEN (
            SELECT 
                STRING_AGG(t.TaskName, ',' ORDER BY t.TaskName)
            FROM 
                Tasks t
            WHERE 
                t.AssignedTo = eh.EmployeeID
        )
        ELSE NULL
    END AS Tasks
FROM 
    EmployeeHierarchy eh
JOIN 
    Departments d ON eh.DepartmentID = d.DepartmentID
JOIN 
    Roles r ON eh.RoleID = r.RoleID
ORDER BY 
    eh.Name;
```

Этот запрос использует рекурсивный CTE для обхода иерархии сотрудников, начиная с прямых подчиненных Ивана Иванова. Затем для каждого сотрудника выводится информация из всех связанных таблиц, включая конкатенированные списки проектов и задач.

### Запрос 2: Расширенная иерархия подчиненных (2.sql)

Этот запрос аналогичен первому, но дополнительно выводит количество задач, назначенных каждому сотруднику, и количество прямых подчиненных.

```sql
WITH RECURSIVE EmployeeHierarchy AS (
    -- Базовый случай: сотрудники, непосредственно подчиняющиеся Ивану Иванову
    SELECT 
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM 
        Employees e
    WHERE 
        e.ManagerID = 1

    UNION ALL

    -- Рекурсивный случай: подчиненные подчиненных
    SELECT 
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM 
        Employees e
    JOIN 
        EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
)

SELECT 
    eh.EmployeeID,
    eh.Name,
    eh.ManagerID,
    d.DepartmentName,
    r.RoleName,
    -- Конкатенация названий проектов с обработкой NULL
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Tasks t
            JOIN Projects p ON t.ProjectID = p.ProjectID
            WHERE t.AssignedTo = eh.EmployeeID
        ) THEN (
            SELECT 
                STRING_AGG(DISTINCT p.ProjectName, ', ' ORDER BY p.ProjectName)
            FROM 
                Tasks t
            JOIN 
                Projects p ON t.ProjectID = p.ProjectID
            WHERE 
                t.AssignedTo = eh.EmployeeID
        )
        ELSE NULL
    END AS Projects,
    -- Конкатенация названий задач с обработкой NULL
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Tasks t
            WHERE t.AssignedTo = eh.EmployeeID
        ) THEN (
            SELECT 
                STRING_AGG(t.TaskName, ', ' ORDER BY t.TaskName)
            FROM 
                Tasks t
            WHERE 
                t.AssignedTo = eh.EmployeeID
        )
        ELSE NULL
    END AS Tasks,
    -- Общее количество задач, назначенных сотруднику
    (
        SELECT 
            COUNT(*)
        FROM 
            Tasks t
        WHERE 
            t.AssignedTo = eh.EmployeeID
    ) AS TaskCount,
    -- Общее количество прямых подчиненных
    (
        SELECT 
            COUNT(*)
        FROM 
            Employees e
        WHERE 
            e.ManagerID = eh.EmployeeID
    ) AS DirectSubordinatesCount
FROM 
    EmployeeHierarchy eh
JOIN 
    Departments d ON eh.DepartmentID = d.DepartmentID
JOIN 
    Roles r ON eh.RoleID = r.RoleID
ORDER BY 
    eh.Name;
```

Этот запрос расширяет функциональность первого запроса, добавляя подсчет задач и прямых подчиненных для каждого сотрудника.

### Запрос 3: Менеджеры с подчиненными (3.sql)

Этот запрос находит всех сотрудников, которые занимают роль менеджера и имеют подчиненных. Для каждого такого сотрудника выводится подробная информация, включая общее количество подчиненных (включая подчиненных их подчиненных).

```sql
WITH RECURSIVE AllSubordinates AS (
    -- Базовый случай: все прямые подчиненные для каждого сотрудника
    SELECT 
        e.EmployeeID AS ManagerID,
        s.EmployeeID AS SubordinateID
    FROM 
        Employees e
    JOIN 
        Employees s ON s.ManagerID = e.EmployeeID

    UNION ALL

    -- Рекурсивный случай: подчиненные подчиненных
    SELECT 
        a.ManagerID,
        s.EmployeeID AS SubordinateID
    FROM 
        AllSubordinates a
    JOIN 
        Employees s ON s.ManagerID = a.SubordinateID
),

-- Подсчет всех подчиненных (включая вложенных) для каждого сотрудника
SubordinateCount AS (
    SELECT 
        ManagerID,
        COUNT(DISTINCT SubordinateID) AS TotalSubordinates
    FROM 
        AllSubordinates
    GROUP BY 
        ManagerID
)

SELECT 
    e.EmployeeID,
    e.Name,
    e.ManagerID,
    d.DepartmentName,
    r.RoleName,
    -- Конкатенация названий проектов с обработкой NULL
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Tasks t
            JOIN Projects p ON t.ProjectID = p.ProjectID
            WHERE t.AssignedTo = e.EmployeeID
        ) THEN (
            SELECT 
                STRING_AGG(DISTINCT p.ProjectName, ', ' ORDER BY p.ProjectName)
            FROM 
                Tasks t
            JOIN 
                Projects p ON t.ProjectID = p.ProjectID
            WHERE 
                t.AssignedTo = e.EmployeeID
        )
        ELSE NULL
    END AS Projects,
    -- Конкатенация названий задач с обработкой NULL
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Tasks t
            WHERE t.AssignedTo = e.EmployeeID
        ) THEN (
            SELECT 
                STRING_AGG(t.TaskName, ', ' ORDER BY t.TaskName)
            FROM 
                Tasks t
            WHERE 
                t.AssignedTo = e.EmployeeID
        )
        ELSE NULL
    END AS Tasks,
    -- Общее количество подчиненных (включая вложенных)
    sc.TotalSubordinates
FROM 
    Employees e
JOIN 
    Departments d ON e.DepartmentID = d.DepartmentID
JOIN 
    Roles r ON e.RoleID = r.RoleID
JOIN 
    SubordinateCount sc ON e.EmployeeID = sc.ManagerID
WHERE 
    r.RoleID = 1 -- Роль "Менеджер"
    AND EXISTS (
        SELECT 1
        FROM Employees s
        WHERE s.ManagerID = e.EmployeeID
    )
ORDER BY 
    e.Name;
```

Этот запрос использует рекурсивный CTE для подсчета всех подчиненных (включая подчиненных подчиненных) для каждого сотрудника. Затем выбираются только те сотрудники, которые имеют роль менеджера и имеют подчиненных.

## Инструкции по запуску и тестированию

### Предварительные требования

- Любая система управления базами данных SQL (PostgreSQL, MySQL, SQLite и т.д.)
- SQL-клиент или интерфейс командной строки

### Шаги настройки

1. Создайте новую базу данных (если требуется вашей системой управления базами данных)
2. Запустите скрипт инициализации:
   ```
   psql -d your_database -f employees/init.sql
   ```
   или эквивалентную команду для вашей системы управления базами данных

3. Проверьте, что данные были вставлены правильно:
   ```sql
   SELECT * FROM Departments;
   SELECT * FROM Roles;
   SELECT * FROM Employees;
   SELECT * FROM Projects;
   SELECT * FROM Tasks;
   ```

### Запуск запросов

1. Для запуска запроса о иерархии подчиненных:
   ```
   psql -d your_database -f employees/1.sql
   ```

2. Для запуска запроса о расширенной иерархии подчиненных:
   ```
   psql -d your_database -f employees/2.sql
   ```

3. Для запуска запроса о менеджерах с подчиненными:
   ```
   psql -d your_database -f employees/3.sql
   ```

### Тестирование

Вы можете протестировать базу данных следующими способами:

1. Добавление новых сотрудников, отделов, ролей, проектов и задач и проверка ограничений
2. Изменение запросов для проверки различных критериев фильтрации и агрегации
3. Создание собственных запросов для анализа иерархии сотрудников и их задач
