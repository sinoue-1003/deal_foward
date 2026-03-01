from sqlalchemy import Column, Integer, String, Float, DateTime, Text, JSON
from datetime import datetime
from .call import Base


class Deal(Base):
    __tablename__ = "deals"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    company = Column(String(255), nullable=False)
    stage = Column(String(100), nullable=False)  # prospect/qualify/demo/proposal/negotiation/closed_won/closed_lost
    amount = Column(Float, default=0.0)
    probability = Column(Integer, default=0)  # 0-100
    owner = Column(String(255), nullable=False)
    contact_name = Column(String(255), nullable=True)
    contact_email = Column(String(255), nullable=True)
    notes = Column(Text, nullable=True)
    competitors = Column(JSON, default=list)
    close_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
