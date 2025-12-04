try:
    # pydantic v2 moved BaseSettings into pydantic-settings package
    from pydantic_settings import BaseSettings
except Exception:
    # fallback for environments with older pydantic that still expose BaseSettings
    from pydantic import BaseSettings


class Settings(BaseSettings):
    # ✅ 환경 구분 필드 추가
    ENV: str = "development"
    
    # Kakao OAuth
    KAKAO_CLIENT_ID: str | None = None
    KAKAO_CLIENT_SECRET: str | None = None
    KAKAO_REDIRECT_URI: str = "http://127.0.0.1:8000/auth/kakao/callback"
    
    # JWT
    JWT_SECRET: str = "dev-secret-for-local-testing"
    
    # Database
    DATABASE_URL: str = "postgresql+psycopg://postgres:postgres@localhost:5432/intersection"
    
    # ✅ CORS (프로덕션용)
    ALLOWED_ORIGINS: str | None = None

    # NEIS OpenAPI 인증키
    # https://open.neis.go.kr 에서 발급받은 인증키를 .env 파일에 설정
    NEIS_API_KEY: str | None = None

    class Config:
        env_file = ".env"
        # ✅ Pydantic v2에서 정의되지 않은 필드 무시
        extra = "ignore"


settings = Settings()