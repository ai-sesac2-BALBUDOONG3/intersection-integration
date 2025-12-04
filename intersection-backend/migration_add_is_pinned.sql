-- 채팅방 고정 기능을 위한 마이그레이션
-- 실행 방법: psql -U postgres -d intersection -f migration_add_is_pinned.sql

-- ChatRoom 테이블에 is_pinned 컬럼 추가
ALTER TABLE chatroom 
ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;

-- ChatMessage 테이블에 is_pinned 컬럼 추가
ALTER TABLE chatmessage 
ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;

-- 기존 데이터는 모두 FALSE로 설정 (이미 DEFAULT FALSE이므로 불필요하지만 명시적으로)
UPDATE chatroom SET is_pinned = FALSE WHERE is_pinned IS NULL;
UPDATE chatmessage SET is_pinned = FALSE WHERE is_pinned IS NULL;


