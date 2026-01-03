# backend/crud.py

from database import get_db_connection

# validovane objekty
# crud.py ich pouzije na INSERT/UPDATE
from models import TaskCreate, TaskUpdate

# RETURNING - vracia riadok po vytvoreni, updateovani a mazani

def create_task_db(task: TaskCreate):
    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute(
        """
        INSERT INTO tasks (task_name, task_desc, accomplish_time)
        VALUES (%s, %s, %s) RETURNING id, task_name, task_desc, creation_date, done, accomplish_time
        """,
        (task.task_name, task.task_desc, task.accomplish_time) # pristupuje sa k attr pydantic obj
    )

    result = cur.fetchone() # dict
    conn.commit()

    cur.close()
    conn.close()
 
    return result # vracia DICT z DB


def get_all_tasks_db():
    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("SELECT * FROM tasks")

    result = cur.fetchall()

    cur.close()
    conn.close()

    return result

def get_task_by_id_db(task_id: int):
    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("SELECT * FROM tasks WHERE id = %s", (task_id,))

    result = cur.fetchone()

    cur.close()
    conn.close()

    return result


def update_task_db(task_id: int, task: TaskUpdate):
    conn = get_db_connection()
    cur = conn.cursor()

    update_fields = []
    update_values = []

    if task.task_name is not None:
        update_fields.append("task_name = %s")
        update_values.append(task.task_name)

    if task.task_desc is not None:
        update_fields.append("task_desc = %s")
        update_values.append(task.task_desc)

    if task.done is not None:
        update_fields.append("done = %s")
        update_values.append(task.done)

    if task.accomplish_time is not None:
        update_fields.append("accomplish_time = %s")
        update_values.append(task.accomplish_time)
    
    cur.execute(
        f"""
        UPDATE tasks
        SET {', '.join(update_fields)}
        WHERE id = %s
        RETURNING id, task_name, task_desc, creation_date, done, accomplish_time
        """,
        (*update_values, task_id)
    )

    result = cur.fetchone()
    conn.commit()

    cur.close()
    conn.close()

    return result


def delete_task_db(task_id: int):
    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute(
        """
        DELETE FROM tasks 
        WHERE id = %s
        RETURNING id, task_name, task_desc, creation_date, done, accomplish_time
        """,
        (task_id,)
    )

    result = cur.fetchone()
    conn.commit()

    cur.close()
    conn.close()

    return result
