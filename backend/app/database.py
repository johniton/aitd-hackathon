"""
Database layer — supports both Supabase and local SQLite.

When SUPABASE_URL is set → uses supabase-py (production)
When SUPABASE_URL is empty → uses SQLAlchemy + SQLite (local dev)
"""

import uuid
from datetime import datetime, timezone

from core.config import settings

# ── Supabase client ─────────────────────────────────────────────────

_supabase_client = None


def get_supabase():
    """Return a singleton Supabase client. Raises if credentials missing."""
    global _supabase_client
    if _supabase_client is None:
        from supabase import create_client
        _supabase_client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_KEY)
    return _supabase_client


def use_supabase() -> bool:
    """Return True if Supabase is configured."""
    return bool(settings.SUPABASE_URL and settings.SUPABASE_SERVICE_KEY)


# ── SQLite fallback (local dev) ─────────────────────────────────────

_engine = None
_SessionLocal = None
_Base = None


def _init_sqlite():
    global _engine, _SessionLocal, _Base

    if _engine is not None:
        return

    from sqlalchemy import (
        Boolean, Column, DateTime, Float, Integer, String, Text,
        create_engine, ForeignKey,
    )
    from sqlalchemy.orm import DeclarativeBase, sessionmaker, relationship

    _engine = create_engine(
        "sqlite:///./goagreen.db",
        connect_args={"check_same_thread": False},
    )
    _SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=_engine)

    class Base(DeclarativeBase):
        pass

    _Base = Base

    def _uuid():
        return str(uuid.uuid4())

    def _now():
        return datetime.now(timezone.utc)

    class UserDB(Base):
        __tablename__ = "users"
        id = Column(String, primary_key=True, default=_uuid)
        name = Column(String, nullable=False)
        avatar_initials = Column(String, nullable=False)
        green_coins = Column(Float, default=0)
        total_co2_saved = Column(Float, default=0)
        streak_days = Column(Integer, default=0)
        city = Column(String, default="")
        created_at = Column(DateTime, default=_now)
        activities = relationship("ActivityDB", back_populates="user")
        house_items = relationship("HouseItemDB", back_populates="user")
        business = relationship("BusinessDB", back_populates="owner", uselist=False)

    class ActivityDB(Base):
        __tablename__ = "activities"
        id = Column(String, primary_key=True, default=_uuid)
        user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
        title = Column(String, nullable=False)
        category = Column(String, nullable=False)
        co2_kg = Column(Float, nullable=False)
        is_saving = Column(Boolean, default=True)
        analogy = Column(String, default="")
        logged_at = Column(DateTime, default=_now)
        user = relationship("UserDB", back_populates="activities")

    class BusinessDB(Base):
        __tablename__ = "businesses"
        id = Column(String, primary_key=True, default=_uuid)
        name = Column(String, nullable=False)
        sector = Column(String, nullable=False)
        owner_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True)
        emissions_kg = Column(Float, default=0)
        peer_avg_kg = Column(Float, default=0)
        created_at = Column(DateTime, default=_now)
        owner = relationship("UserDB", back_populates="business")
        suggestions = relationship("BusinessSuggestionDB", back_populates="business")
        badges = relationship("BusinessBadgeDB", back_populates="business")
        exchange_listings = relationship("ExchangeListingDB", back_populates="business")

    class BusinessSuggestionDB(Base):
        __tablename__ = "business_suggestions"
        id = Column(String, primary_key=True, default=_uuid)
        business_id = Column(String, ForeignKey("businesses.id"), nullable=False)
        suggestion = Column(String, nullable=False)
        applied = Column(Boolean, default=False)
        business = relationship("BusinessDB", back_populates="suggestions")

    class BusinessBadgeDB(Base):
        __tablename__ = "business_badges"
        id = Column(String, primary_key=True, default=_uuid)
        business_id = Column(String, ForeignKey("businesses.id"), nullable=False)
        badge_name = Column(String, nullable=False)
        earned_at = Column(DateTime, default=_now)
        business = relationship("BusinessDB", back_populates="badges")

    class HouseItemDB(Base):
        __tablename__ = "house_items"
        id = Column(String, primary_key=True, default=_uuid)
        user_id = Column(String, ForeignKey("users.id"), nullable=False)
        item_key = Column(String, nullable=False)
        item_name = Column(String, nullable=False)
        cost = Column(Integer, nullable=False)
        purchased_at = Column(DateTime, default=_now)
        user = relationship("UserDB", back_populates="house_items")

    class SubsidyDB(Base):
        __tablename__ = "subsidies"
        id = Column(String, primary_key=True, default=_uuid)
        title = Column(String, nullable=False)
        description = Column(Text, default="")
        amount = Column(String, default="")
        deadline = Column(String, default="")
        eligible_sectors = Column(String, default="")

    class ExchangeListingDB(Base):
        __tablename__ = "exchange_listings"
        id = Column(String, primary_key=True, default=_uuid)
        business_id = Column(String, ForeignKey("businesses.id"), nullable=False)
        title = Column(String, nullable=False)
        description = Column(Text, default="")
        sector = Column(String, default="")
        active = Column(Boolean, default=True)
        created_at = Column(DateTime, default=_now)
        business = relationship("BusinessDB", back_populates="exchange_listings")

    # Store model classes for external access
    import sys
    mod = sys.modules[__name__]
    mod.UserDB = UserDB
    mod.ActivityDB = ActivityDB
    mod.BusinessDB = BusinessDB
    mod.BusinessSuggestionDB = BusinessSuggestionDB
    mod.BusinessBadgeDB = BusinessBadgeDB
    mod.HouseItemDB = HouseItemDB
    mod.SubsidyDB = SubsidyDB
    mod.ExchangeListingDB = ExchangeListingDB
    mod.Base = Base

    Base.metadata.create_all(bind=_engine)


def get_db():
    """SQLite session dependency."""
    _init_sqlite()
    db = _SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Initialize on import if using SQLite
if not use_supabase():
    _init_sqlite()
