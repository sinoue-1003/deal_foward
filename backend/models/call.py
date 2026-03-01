from sqlalchemy import Column, Integer, String, Float, DateTime, Text, JSON
from sqlalchemy.orm import DeclarativeBase
from datetime import datetime


class Base(DeclarativeBase):
    pass


class Call(Base):
    __tablename__ = "calls"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    date = Column(DateTime, default=datetime.utcnow)
    duration_seconds = Column(Integer, default=0)
    participants = Column(JSON, default=list)  # [{"name": str, "role": str}]
    audio_path = Column(String(500), nullable=True)
    transcript = Column(Text, nullable=True)
    summary = Column(Text, nullable=True)
    sentiment = Column(String(50), nullable=True)  # positive / neutral / negative
    keywords = Column(JSON, default=list)
    next_steps = Column(JSON, default=list)
    talk_ratio = Column(JSON, default=dict)  # {"rep": float, "prospect": float}
    deal_id = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
