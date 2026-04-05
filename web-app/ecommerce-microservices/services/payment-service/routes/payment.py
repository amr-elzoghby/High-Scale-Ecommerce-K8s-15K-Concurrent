import uuid
import random
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from sqlalchemy.orm import Session
from database import get_db
from models import Payment, PaymentStatus

router = APIRouter(prefix="/api/payments", tags=["payments"])


# ── Pydantic Schemas ──────────────────────────────────────────────────────────
class PaymentRequest(BaseModel):
    userId: str
    amount: float
    cardNumber: str   # Will only store last 4 digits
    cardExpiry: str
    cardCvv: str

    @field_validator("cardNumber")
    @classmethod
    def validate_card(cls, v: str) -> str:
        digits = v.replace(" ", "")
        if not digits.isdigit() or len(digits) != 16:
            raise ValueError("Card number must be 16 digits")
        return digits

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v: float) -> float:
        if v < 0:
            raise ValueError("Amount must be 0 or greater")
        return v


class PaymentResponse(BaseModel):
    paymentId: str
    status: str
    amount: float
    message: str

    class Config:
        from_attributes = True


# ── POST /api/payments/process ────────────────────────────────────────────────
@router.post("/process", response_model=PaymentResponse)
def process_payment(payload: PaymentRequest, db: Session = Depends(get_db)):
    """
    Simulates payment processing.
    In production: integrate with Stripe, PayPal, etc.
    """
    # Simulate a 95% success rate
    success = random.random() < 0.95

    status = PaymentStatus.COMPLETED if success else PaymentStatus.FAILED

    payment = Payment(
        id         = str(uuid.uuid4()),
        user_id    = payload.userId,
        amount     = payload.amount,
        card_last4 = payload.cardNumber[-4:],
        status     = status,
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)

    if not success:
        raise HTTPException(status_code=402, detail="Payment declined by bank. Please try another card.")

    return PaymentResponse(
        paymentId = payment.id,
        status    = payment.status.value,
        amount    = payment.amount,
        message   = f"Payment of ${payment.amount:.2f} completed successfully.",
    )


# ── GET /api/payments/:paymentId ──────────────────────────────────────────────
@router.get("/{payment_id}", response_model=PaymentResponse)
def get_payment(payment_id: str, db: Session = Depends(get_db)):
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    return PaymentResponse(
        paymentId = payment.id,
        status    = payment.status.value,
        amount    = payment.amount,
        message   = f"Payment status: {payment.status.value}",
    )


# ── GET /api/payments/user/:userId ────────────────────────────────────────────
@router.get("/user/{user_id}")
def get_payments_by_user(user_id: str, db: Session = Depends(get_db)):
    payments = db.query(Payment).filter(Payment.user_id == user_id).all()
    return [
        {
            "paymentId":  p.id,
            "status":     p.status.value,
            "amount":     p.amount,
            "cardLast4":  p.card_last4,
            "created_at": p.created_at.isoformat(),
        }
        for p in payments
    ]
