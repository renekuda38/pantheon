# backend/models.py


from pydantic import BaseModel # valid lib

from typing import Optional # pre volitelne fields
from datetime import date


# POST request body model - user posiela
class TaskCreate(BaseModel):
    task_name: str
    task_desc: Optional[str] = None
    accomplish_time: int


# GET request response model - API vracia
class TaskResponse(BaseModel):
    id: int # SERIAL tzn auto-generated
    task_name: str
    task_desc: Optional[str] = None
    creation_date: date # CURRENT-DATE tzn auto-generated
    done: bool # default FALSE
    accomplish_time: int


# PUT request body model
class TaskUpdate(BaseModel):
    task_name: Optional[str] = None
    task_desc: Optional[str] = None
    done: Optional[bool] = None
    accomplish_time: Optional[int] = None


