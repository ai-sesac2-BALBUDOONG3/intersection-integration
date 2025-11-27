import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles  # 👈 정적 파일 서빙을 위해 추가됨
from .db import create_db_and_tables

# 라우터 모듈 불러오기
from .routers import auth as auth_router
from .routers import users as users_router
from .routers import posts as posts_router
from .routers import comments as comments_router
from .routers import friends as friends_router
from .routers import common as common_router  # 👈 새로 추가된 파일 업로드 라우터

app = FastAPI(title="Intersection Backend (dev)")

# 1. CORS 설정 (프론트엔드 접근 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1|10\.0\.2\.2)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 2. 이미지 업로드 폴더 설정 (서버 실행 시 폴더 자동 생성)
UPLOAD_DIR = "uploads"
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

# 3. 정적 파일 서빙 설정 (http://주소/uploads/... 로 접근 가능하게 함)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


@app.on_event("startup")
def on_startup():
    # DB 테이블 생성
    create_db_and_tables()


# 4. 기능별 라우터 등록
app.include_router(auth_router.router)
app.include_router(users_router.router)
app.include_router(posts_router.router)
app.include_router(comments_router.router)
app.include_router(friends_router.router)
app.include_router(common_router.router)  # 👈 파일 업로드 기능 등록


@app.get("/")
def root():
    return {"message": "Intersection backend running"}