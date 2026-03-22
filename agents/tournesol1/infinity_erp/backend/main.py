from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional
import pandas as pd
import io
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext

from database import get_db, engine
from models import User, Client, Supplier
from schemas import (
    UserCreate, UserResponse, UserLogin, Token,
    ClientCreate, ClientResponse, ClientUpdate,
    SupplierCreate, SupplierResponse, SupplierUpdate
)
import models

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="INFINITY ERP API",
    description="API pour ERP modulaire PME",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
SECRET_KEY = "infinity-erp-secret-key-dev"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user

@app.get("/")
async def root():
    return {"message": "INFINITY ERP API - Foundation Ready"}

# Authentication endpoints
@app.post("/auth/register", response_model=UserResponse)
async def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        password_hash=hashed_password,
        first_name=user.first_name,
        last_name=user.last_name,
        role=user.role
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.post("/auth/login", response_model=Token)
async def login(user_credentials: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == user_credentials.email).first()
    if not user or not verify_password(user_credentials.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/auth/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    return current_user

# Client endpoints
@app.get("/clients", response_model=List[ClientResponse])
async def get_clients(skip: int = 0, limit: int = 100, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    clients = db.query(Client).offset(skip).limit(limit).all()
    return clients

@app.post("/clients", response_model=ClientResponse)
async def create_client(client: ClientCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_client = Client(**client.dict(), created_by=current_user.id)
    db.add(db_client)
    db.commit()
    db.refresh(db_client)
    return db_client

@app.put("/clients/{client_id}", response_model=ClientResponse)
async def update_client(client_id: str, client: ClientUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_client = db.query(Client).filter(Client.id == client_id).first()
    if not db_client:
        raise HTTPException(status_code=404, detail="Client not found")

    for field, value in client.dict(exclude_unset=True).items():
        setattr(db_client, field, value)

    db.commit()
    db.refresh(db_client)
    return db_client

@app.delete("/clients/{client_id}")
async def delete_client(client_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_client = db.query(Client).filter(Client.id == client_id).first()
    if not db_client:
        raise HTTPException(status_code=404, detail="Client not found")

    db.delete(db_client)
    db.commit()
    return {"message": "Client deleted"}

# Supplier endpoints
@app.get("/suppliers", response_model=List[SupplierResponse])
async def get_suppliers(skip: int = 0, limit: int = 100, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    suppliers = db.query(Supplier).offset(skip).limit(limit).all()
    return suppliers

@app.post("/suppliers", response_model=SupplierResponse)
async def create_supplier(supplier: SupplierCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_supplier = Supplier(**supplier.dict(), created_by=current_user.id)
    db.add(db_supplier)
    db.commit()
    db.refresh(db_supplier)
    return db_supplier

# CSV Import endpoints
@app.post("/clients/import-csv")
async def import_clients_csv(file: UploadFile = File(...), current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="File must be CSV")

    contents = await file.read()
    df = pd.read_csv(io.StringIO(contents.decode('utf-8')))

    created_count = 0
    for _, row in df.iterrows():
        try:
            db_client = Client(
                company_name=row.get('company_name'),
                contact_person=row.get('contact_person'),
                email=row.get('email'),
                phone=row.get('phone'),
                address=row.get('address'),
                city=row.get('city'),
                postal_code=row.get('postal_code'),
                country=row.get('country', 'France'),
                created_by=current_user.id
            )
            db.add(db_client)
            created_count += 1
        except Exception as e:
            continue

    db.commit()
    return {"message": f"{created_count} clients imported successfully"}

@app.post("/suppliers/import-csv")
async def import_suppliers_csv(file: UploadFile = File(...), current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="File must be CSV")

    contents = await file.read()
    df = pd.read_csv(io.StringIO(contents.decode('utf-8')))

    created_count = 0
    for _, row in df.iterrows():
        try:
            db_supplier = Supplier(
                company_name=row.get('company_name'),
                contact_person=row.get('contact_person'),
                email=row.get('email'),
                phone=row.get('phone'),
                address=row.get('address'),
                city=row.get('city'),
                postal_code=row.get('postal_code'),
                country=row.get('country', 'France'),
                payment_terms=row.get('payment_terms', 30),
                created_by=current_user.id
            )
            db.add(db_supplier)
            created_count += 1
        except Exception as e:
            continue

    db.commit()
    return {"message": f"{created_count} suppliers imported successfully"}