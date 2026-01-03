# backend/app.py


from fastapi import FastAPI, HTTPException # HTTP error handling
from typing import List
from taskmaster_api.models import TaskCreate, TaskUpdate, TaskResponse # validacia
from taskmaster_api.database import test_db_connection
from taskmaster_api.crud import (
    create_task_db,
    get_all_tasks_db,
    get_task_by_id_db,
    update_task_db,
    delete_task_db
)

# fastapi appka, metadata pre swagger docs
app = FastAPI(
    title="Task Manager API",
    description="Simple task management API with PostgreSQL",
    version="1.0.0"
)

# ============= HEALTH ENDPOINTS =============

@app.get("/")
def read_root():
    """Root endpoint - zakladny health check"""
    return {"status": "healthy", "message": "Task Manager API is running"}

@app.get("/health")
def health_check():
    """Health check s DB testom"""
    db_status = test_db_connection()
    
    if db_status:
        return {"status": "ok", "database": "connected"}
    else:
        # 503 = Service Unavailable (server beží, ale DB nie)
        raise HTTPException(status_code=503, detail="Database connection failed")

# ============= TASK CRUD ENDPOINTS =============

@app.post("/tasks", response_model=TaskResponse, status_code=201)
def create_task(task: TaskCreate):
    # vytvori novy task
    # input: TaskCreate - valid json od usera -> fastapi + pydantic to parsuju na TaskCreate obj - tento obj sa vlozi do paramtra funckie
    # output: TaskResponse - vytvoreny task s ID
    # status: 201 Created
    try:
        # vlozi task do DB -> dostane / vrati DICT z crud.py
        result = create_task_db(task) 
        # result = {'id': 5, 'task_name': 'Learn Docker', ...}

        # fastapi automaticky konvertuje na JSON pre HTTP response

        # vytvori novu instanciu typu TaskCreate
        # z DICT -> pydantic model
        return TaskResponse(**result)  
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create task: {str(e)}")
        # 500 = Internal Server Error (DB crash, bug...)

@app.get("/tasks", response_model=List[TaskResponse])
def get_all_tasks():
    # vrati vsetky tasky
    try:
        tasks = get_all_tasks_db() # nacita vsetky tasky z DB -> list of dicts
        return [TaskResponse(**task) for task in tasks] # konvertuje kazdy dict -> TaskResponse
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch tasks: {str(e)}")


@app.get("/tasks/{task_id}", response_model=TaskResponse)
def get_task(task_id: int):
    # vrati task podla ID
    try:
        task = get_task_by_id_db(task_id) # hlada task v DB, dict alebo None
        
        if not task:
            raise HTTPException(status_code=404, detail=f"Task with id {task_id} not found")
            # 404 = Not Found
        
        return TaskResponse(**task)
        
    except HTTPException:
        raise # re-raise HTTPException (404) bez zmeny
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch task: {str(e)}") # ostatne errory


@app.put("/tasks/{task_id}", response_model=TaskResponse)
def update_task(task_id: int, task: TaskUpdate):
    # update existujuceho tasku
    try:
        # kontrola ci user poslal aspon jeden field na update
        # model_dump(exclude_unset=True) → vrati LEN fieldy, kt. user nastavil
        if not task.model_dump(exclude_unset=True):
            raise HTTPException(status_code=400, detail="No fields to update")
        
        result = update_task_db(task_id, task)  # updatne task v DB → dict alebo None
        
        if not result:
            raise HTTPException(status_code=404, detail=f"Task with id {task_id} not found")
        
        return TaskResponse(**result)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update task: {str(e)}")


@app.delete("/tasks/{task_id}")
def delete_task(task_id: int):
    # zmaze task
    try:
        # zmaze task z DB → dict (zmazany task) alebo None
        deleted_task = delete_task_db(task_id)
        
        if not deleted_task:
            raise HTTPException(status_code=404, detail=f"Task with id {task_id} not found")

        # vracia JSON - info ci sa podarilo zmazat
        return {"message": "Task deleted successfully", "id": deleted_task['id']}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete task: {str(e)}")
