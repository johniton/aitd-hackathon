from pydantic import BaseModel


class SubsidyResponse(BaseModel):
    id: str
    title: str
    description: str
    amount: str
    deadline: str
    is_eligible: bool
