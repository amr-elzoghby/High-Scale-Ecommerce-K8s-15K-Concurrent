import os
import sys
import uuid
import random
import logging
from concurrent import futures
import grpc
from grpc_tools import protoc

# 1. Programmatic Protobuf Compilation at Startup
# Ensures payment_pb2 and payment_pb2_grpc are generated automatically in any environment
proto_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(proto_dir)

if not os.path.exists("payment_pb2.py") or not os.path.exists("payment_pb2_grpc.py"):
    logging.info("Compiling payment.proto dynamically...")
    protoc.main((
        '',
        '-I.',
        '--python_out=.',
        '--grpc_python_out=.',
        'payment.proto',
    ))

# Import the generated gRPC modules
import payment_pb2
import payment_pb2_grpc

from database import SessionLocal
from models import Payment, PaymentStatus

class PaymentServiceServicer(payment_pb2_grpc.PaymentServiceServicer):
    def ProcessPayment(self, request, context):
        logging.info(f"[gRPC Payment Service] Processing payment for user: {request.user_id}, amount: {request.amount}")

        # Validation (Same logic as API)
        if request.amount <= 0:
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            context.set_details("Amount must be greater than 0")
            return payment_pb2.PaymentResponse()

        if len(request.card_number.replace(" ", "")) != 16:
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            context.set_details("Card number must be 16 digits")
            return payment_pb2.PaymentResponse()

        # Simulate success rate
        success = random.random() < 0.95
        status = PaymentStatus.COMPLETED if success else PaymentStatus.FAILED

        # Save to PostgreSQL database
        db = SessionLocal()
        try:
            payment = Payment(
                id=str(uuid.uuid4()),
                user_id=request.user_id,
                amount=request.amount,
                card_last4=request.card_number[-4:],
                status=status
            )
            db.add(payment)
            db.commit()
            db.refresh(payment)
            
            logging.info(f"[gRPC Payment Service] Payment {payment.id} stored with status: {status.value}")

            if not success:
                context.set_code(grpc.StatusCode.ABORTED)
                context.set_details("Payment declined by bank.")
                return payment_pb2.PaymentResponse(
                    payment_id=payment.id,
                    status=status.value,
                    amount=float(payment.amount),
                    message="Payment declined by bank. Please try another card."
                )

            return payment_pb2.PaymentResponse(
                payment_id=payment.id,
                status=status.value,
                amount=float(payment.amount),
                message=f"Payment of ${payment.amount:.2f} completed successfully."
            )
        except Exception as e:
            db.rollback()
            logging.error(f"[gRPC Payment Service] Error processing payment: {str(e)}")
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(f"Internal database error: {str(e)}")
            return payment_pb2.PaymentResponse()
        finally:
            db.close()


def serve(port=50051):
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    payment_pb2_grpc.add_PaymentServiceServicer_to_server(PaymentServiceServicer(), server)
    server.add_insecure_port(f'[::]:{port}')
    logging.info(f"[gRPC Payment Service] gRPC server starting on port {port}...")
    server.start()
    return server
