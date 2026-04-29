from pydantic import BaseModel


class ExchangeResponse(BaseModel):
    id: str
    title: str
    offered_by: str
    sector: str
    description: str
    active: bool


class ExchangeCreate(BaseModel):
    title: str
    description: str
    sector: str
