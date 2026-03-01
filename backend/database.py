from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models.call import Base as CallBase
from models.deal import Base as DealBase

DATABASE_URL = "sqlite:///./data/gong_clone.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def init_db():
    CallBase.metadata.create_all(bind=engine)
    DealBase.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
