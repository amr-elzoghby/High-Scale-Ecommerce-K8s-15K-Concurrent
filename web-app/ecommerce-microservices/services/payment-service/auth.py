import os
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError

# RS256 Public Key — injected from Kubernetes Secret as env var
# Newlines escaped as \n in env, so we restore them here
_PUBLIC_KEY_RAW = os.getenv("JWT_PUBLIC_KEY", "")
JWT_PUBLIC_KEY = _PUBLIC_KEY_RAW.replace("\\n", "\n")

ALGORITHM = "RS256"
bearer_scheme = HTTPBearer()


def verify_token(credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)) -> dict:
    """
    FastAPI dependency for stateless RS256 JWT verification.
    Verifies the Bearer token using the RSA public key — zero DB calls.

    Usage:
        @router.post("/process")
        def process(payload: ..., user=Depends(verify_token)):
            ...
    """
    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_PUBLIC_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Unauthorized: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )
