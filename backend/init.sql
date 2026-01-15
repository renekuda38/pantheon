-- backend/init.sql
-- PostgreSQL schema pre TaskMaster API
-- Spusta sa automaticky pri starte postgres containera

-- Vytvorenie tabulky tasks
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,              -- auto-increment ID
    task_name VARCHAR(255) NOT NULL,    -- nazov tasku (povinny)
    task_desc TEXT,                      -- popis (volitelny)
    creation_date DATE DEFAULT CURRENT_DATE,  -- datum vytvorenia (auto)
    done BOOLEAN DEFAULT FALSE,          -- stav dokoncenia
    accomplish_time INTEGER NOT NULL     -- cas na splnenie v hodinach
);

-- 3 testovacie inserty
INSERT INTO tasks (task_name, task_desc, accomplish_time) VALUES
    ('Learn Docker', 'Prejst Docker tutorial a postavit prvy container', 8),
    ('Setup CI/CD', 'Nakonfigurovat Jenkins pipeline pre automaticky deploy', 16),
    ('Write API tests', NULL, 4);
