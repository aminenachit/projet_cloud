from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
import httpx
import os
import models
from database import engine, get_db

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Order Service", version="1.0.0")

PRODUCT_SERVICE_URL = os.getenv("PRODUCT_SERVICE_URL", "http://product-service:8000")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class OrderItemBase(BaseModel):
    product_id: int
    quantity: int

class OrderItemResponse(BaseModel):
    id: int
    product_id: int
    product_name: str
    quantity: int
    price: float

    class Config:
        from_attributes = True

class OrderCreate(BaseModel):
    customer_name: str
    customer_email: str
    items: List[OrderItemBase]

class OrderResponse(BaseModel):
    id: int
    customer_name: str
    customer_email: str
    total_amount: float
    status: str
    items: List[OrderItemResponse]

    class Config:
        from_attributes = True

@app.get("/")
def read_root():
    return {"service": "Order Service", "status": "running", "version": "1.0.0"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

async def get_product_info(product_id: int):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{PRODUCT_SERVICE_URL}/products/{product_id}")
            if response.status_code == 200:
                return response.json()
            return None
        except Exception as e:
            print(f"Error fetching product {product_id}: {str(e)}")
            return None

@app.post("/orders/", response_model=OrderResponse)
async def create_order(order: OrderCreate, db: Session = Depends(get_db)):
    total_amount = 0.0
    order_items = []

    for item in order.items:
        product = await get_product_info(item.product_id)
        if not product:
            raise HTTPException(status_code=404, detail=f"Product {item.product_id} not found")

        if product['stock'] < item.quantity:
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient stock for product {product['name']}"
            )

        item_total = product['price'] * item.quantity
        total_amount += item_total

        order_items.append({
            "product_id": item.product_id,
            "product_name": product['name'],
            "quantity": item.quantity,
            "price": product['price']
        })

    db_order = models.Order(
        customer_name=order.customer_name,
        customer_email=order.customer_email,
        total_amount=total_amount,
        status="pending"
    )
    db.add(db_order)
    db.commit()
    db.refresh(db_order)

    for item_data in order_items:
        db_item = models.OrderItem(
            order_id=db_order.id,
            **item_data
        )
        db.add(db_item)

    db.commit()
    db.refresh(db_order)

    return db_order

@app.get("/orders/", response_model=List[OrderResponse])
def get_orders(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    orders = db.query(models.Order).offset(skip).limit(limit).all()
    return orders

@app.get("/orders/{order_id}", response_model=OrderResponse)
def get_order(order_id: int, db: Session = Depends(get_db)):
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    return order

@app.put("/orders/{order_id}/status")
def update_order_status(order_id: int, status: str, db: Session = Depends(get_db)):
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")

    order.status = status
    db.commit()
    db.refresh(order)
    return order

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
