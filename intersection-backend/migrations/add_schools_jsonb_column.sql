-- 여러 학교 정보를 저장하기 위한 JSONB 컬럼 추가
-- PostgreSQL에서 실행

-- schools 컬럼 추가 (JSONB 타입)
ALTER TABLE "user" ADD COLUMN IF NOT EXISTS schools JSONB;

-- 기존 school_name, school_type, admission_year 데이터가 있으면 schools JSONB로 변환
UPDATE "user" 
SET schools = jsonb_build_array(
    jsonb_build_object(
        'name', school_name,
        'school_type', school_type,
        'admission_year', admission_year
    )
)
WHERE school_name IS NOT NULL 
  AND school_name != ''
  AND (schools IS NULL OR schools = 'null'::jsonb);

-- 인덱스 추가 (선택사항, JSONB 필드 검색 성능 향상)
CREATE INDEX IF NOT EXISTS idx_user_schools ON "user" USING GIN (schools);

