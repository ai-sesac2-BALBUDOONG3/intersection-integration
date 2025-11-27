from fastapi import APIRouter, UploadFile, File
import shutil
import os
import uuid

router = APIRouter(tags=["common"])

UPLOAD_DIR = "uploads"

@router.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    """
    이미지 파일을 업로드하면, 접속 가능한 URL을 반환해주는 API
    """
    # 1. 파일 이름이 겹치지 않게 랜덤 ID 생성 (uuid)
    # 예: my_photo.jpg -> uuid-uuid.jpg
    filename = f"{uuid.uuid4()}{os.path.splitext(file.filename)[1]}"
    file_location = os.path.join(UPLOAD_DIR, filename)
    
    # 2. 서버 디스크에 파일 저장
    with open(file_location, "wb+") as file_object:
        shutil.copyfileobj(file.file, file_object)
    
    # 3. 접속 가능한 URL 반환
    # (주의: 실제 배포 시에는 도메인 주소로 변경 필요, 지금은 상대 경로)
    return {"url": f"/uploads/{filename}"}