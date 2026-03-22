from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from uuid import UUID

# User schemas
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    first_name: str
    last_name: str
    role: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: UUID
    email: str
    first_name: str
    last_name: str
    role: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

# Client schemas
class ClientCreate(BaseModel):
    company_name: str
    contact_person: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    postal_code: Optional[str] = None
    country: str = "France"
    tax_number: Optional[str] = None

class ClientUpdate(BaseModel):
    company_name: Optional[str] = None
    contact_person: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    postal_code: Optional[str] = None
    country: Optional[str] = None
    tax_number: Optional[str] = None
    is_active: Optional[bool] = None

class ClientResponse(BaseModel):
    id: UUID
    company_name: str
    contact_person: Optional[str]
    email: Optional[str]
    phone: Optional[str]
    address: Optional[str]
    city: Optional[str]
    postal_code: Optional[str]
    country: str
    tax_number: Optional[str]
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

# Supplier schemas
class SupplierCreate(BaseModel):
    company_name: str
    contact_person: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    postal_code: Optional[str] = None
    country: str = "France"
    tax_number: Optional[str] = None
    payment_terms: int = 30

class SupplierUpdate(BaseModel):
    company_name: Optional[str] = None
    contact_person: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    postal_code: Optional[str] = None
    country: Optional[str] = None
    tax_number: Optional[str] = None
    payment_terms: Optional[int] = None
    is_active: Optional[bool] = None

class SupplierResponse(BaseModel):
    id: UUID
    company_name: str
    contact_person: Optional[str]
    email: Optional[str]
    phone: Optional[str]
    address: Optional[str]
    city: Optional[str]
    postal_code: Optional[str]
    country: str
    tax_number: Optional[str]
    payment_terms: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True