import httpx
import asyncio

async def test_neis():
    client = httpx.AsyncClient(timeout=5.0)
    try:
        resp = await client.get(
            'https://open.neis.go.kr/hub/schoolInfo',
            params={
                'KEY': '8fe50f0711344fa79bff3c201dbe6f82',
                'Type': 'json',
                'pIndex': 1,
                'pSize': 5,
                'SCHUL_NM': '서울'
            }
        )
        print(f'Status: {resp.status_code}')
        print(f'Response: {resp.text[:1000]}')
    except Exception as e:
        print(f'Error: {e}')
    finally:
        await client.aclose()

asyncio.run(test_neis())
