/*
Найти всех сотрудников, подчиняющихся Ивану Иванову (с EmployeeID = 1),
включая их подчиненных и подчиненных подчиненных.
Для каждого сотрудника вывести следующую информацию:

EmployeeID: идентификатор сотрудника.
Имя сотрудника.
ManagerID: Идентификатор менеджера.
Название отдела, к которому он принадлежит.
Название роли, которую он занимает.
Название проектов, к которым он относится (если есть, конкатенированные в одном столбце через запятую).
Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце через запятую).
Если у сотрудника нет назначенных проектов или задач, отобразить NULL.
Требования:

Рекурсивно извлечь всех подчиненных сотрудников Ивана Иванова и их подчиненных.
Для каждого сотрудника отобразить информацию из всех таблиц.
Результаты должны быть отсортированы по имени сотрудника.
Решение задачи должно представлять из себя один sql-запрос и задействовать ключевое слово RECURSIVE.
*/

WITH RECURSIVE EmployeeHierarchy AS (
    -- Базовый случай: сотрудники, непосредственно подчиняющиеся Ивану Иванову (EmployeeID = 1)
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
