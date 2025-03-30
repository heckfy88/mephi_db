/*
 Найти всех сотрудников, которые занимают роль менеджера и имеют подчиненных (то есть число подчиненных больше 0). Для каждого такого сотрудника вывести следующую информацию:

EmployeeID: идентификатор сотрудника.
Имя сотрудника.
Идентификатор менеджера.
Название отдела, к которому он принадлежит.
Название роли, которую он занимает.
Название проектов, к которым он относится (если есть, конкатенированные в одном столбце).
Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце).
Общее количество подчиненных у каждого сотрудника (включая их подчиненных).
Если у сотрудника нет назначенных проектов или задач, отобразить NULL.
 */

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
