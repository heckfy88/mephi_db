/* Найти всех сотрудников, подчиняющихся Ивану Иванову с EmployeeID = 1, включая их подчиненных и подчиненных подчиненных. Для каждого сотрудника вывести следующую информацию:

EmployeeID: идентификатор сотрудника.
Имя сотрудника.
Идентификатор менеджера.
Название отдела, к которому он принадлежит.
Название роли, которую он занимает.
Название проектов, к которым он относится (если есть, конкатенированные в одном столбце).
Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце).
Общее количество задач, назначенных этому сотруднику.
Общее количество подчиненных у каждого сотрудника (не включая подчиненных их подчиненных).
Если у сотрудника нет назначенных проектов или задач, отобразить NULL.
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