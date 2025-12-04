import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from .db import create_db_and_tables
from .config import settings

# 라우터 모듈 불러오기
from .routers import auth as auth_router
from .routers import users as users_router
from .routers import posts as posts_router
from .routers import comments as comments_router
from .routers import friends as friends_router
from .routers import common as common_router
from .routers import chat as chat_router
from .routers import moderation as moderation_router

app = FastAPI(title="Intersection Backend")

# ✅ CORS 설정 (환경별 자동 적용)
if settings.ENV.lower() == "production" and settings.ALLOWED_ORIGINS:
    # 🔒 프로덕션: 특정 도메인만 허용
    allowed_origins_list = [origin.strip() for origin in settings.ALLOWED_ORIGINS.split(",")]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    # 🔓 개발: 모든 출처 허용
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# 이미지 업로드 폴더 설정
UPLOAD_DIR = "uploads"
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

# 정적 파일 서빙
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


@app.on_event("startup")
def on_startup():
    # DB 테이블 생성
    create_db_and_tables()

@app.on_event("shutdown")
async def on_shutdown():
    """서버 종료 시 httpx 클라이언트 정리"""
    from .routers.common import _http_client
    if _http_client is not None:
        try:
            await _http_client.aclose()
        except Exception:
            pass


# 라우터 등록
app.include_router(auth_router.router)
app.include_router(users_router.router)
app.include_router(posts_router.router)
app.include_router(comments_router.router)
app.include_router(friends_router.router)
app.include_router(common_router.router)
app.include_router(chat_router.router)
app.include_router(moderation_router.router)


@app.get("/")
def root():
    return {
        "message": "Intersection backend running",
        "env": settings.ENV
    }