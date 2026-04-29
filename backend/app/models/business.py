from pydantic import BaseModel


class BusinessCreate(BaseModel):
    name: str
    sector: str  # tourism | cashew | farmer | bakery


class BusinessResponse(BaseModel):
    id: str
    name: str
    sector: str
    sector_icon: str
    emissions_kg: float
    peer_avg_kg: float
    suggestions: list[str]
    badges: list[str]


class EmissionsUpdate(BaseModel):
    emissions_kg: float


class PeerRankingEntry(BaseModel):
    name: str
    emissions_kg: float
    is_me: bool


class BenchmarkResponse(BaseModel):
    my_emissions_kg: float
    sector_avg_kg: float
    best_in_class_kg: float
    sector: str
    peer_ranking: list[PeerRankingEntry]
