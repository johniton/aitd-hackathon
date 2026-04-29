from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from database import Base

class Activity(Base):
    __tablename__ = "activities"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    category = Column(String, index=True)
    type = Column(String)
    value = Column(Float)
    carbon = Column(Float)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
